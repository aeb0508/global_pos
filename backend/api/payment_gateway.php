<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/Database.php';
require_once '../utils/JWT.php';
require_once '../middleware/AuthMiddleware.php';
require_once '../utils/UUID.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['gateways'])) {
                getGateways($db);
            } elseif (isset($_GET['transactions'])) {
                getTransactions($db, $_GET);
            } elseif (isset($_GET['transaction_id'])) {
                getTransaction($db, $_GET['transaction_id']);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid request']);
            }
            break;

        case 'POST':
            $user = AuthMiddleware::authenticate();
            if (!$user) {
                http_response_code(401);
                echo json_encode(['error' => 'Unauthorized']);
                exit();
            }
            
            if (isset($_GET['process'])) {
                processPayment($db, $user);
            } elseif (isset($_GET['refund'])) {
                processRefund($db, $user);
            } elseif (isset($_GET['webhook'])) {
                handleWebhook($db);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid request']);
            }
            break;

        case 'PUT':
            $user = AuthMiddleware::authenticate();
            if (!$user) {
                http_response_code(401);
                echo json_encode(['error' => 'Unauthorized']);
                exit();
            }
            
            if (isset($_GET['gateway_id'])) {
                updateGateway($db, $_GET['gateway_id'], $user);
            }
            break;

        default:
            http_response_code(405);
            echo json_encode(['error' => 'Method not allowed']);
            break;
    }
} catch (Exception $e) {
    http_response_code(500);
    echo json_encode(['error' => $e->getMessage()]);
}

// Get all payment gateways
function getGateways($db) {
    $query = "SELECT id, name, gateway_type, is_active, is_test_mode, 
              created_at, updated_at FROM payment_gateways ORDER BY name";
    
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $gateways = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($gateways);
}

// Get transactions
function getTransactions($db, $params) {
    $where = [];
    $bindings = [];
    
    if (isset($params['order_id'])) {
        $where[] = "order_id = ?";
        $bindings[] = $params['order_id'];
    }
    
    if (isset($params['status'])) {
        $where[] = "status = ?";
        $bindings[] = $params['status'];
    }
    
    $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';
    
    $query = "SELECT pt.*, pg.name as gateway_name, o.order_number
              FROM payment_transactions pt
              LEFT JOIN payment_gateways pg ON pt.gateway_id = pg.id
              LEFT JOIN orders o ON pt.order_id = o.id
              $whereClause
              ORDER BY pt.created_at DESC
              LIMIT 100";
    
    $stmt = $db->prepare($query);
    $stmt->execute($bindings);
    
    $transactions = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($transactions);
}

// Get single transaction
function getTransaction($db, $id) {
    $query = "SELECT pt.*, pg.name as gateway_name, pg.gateway_type, o.order_number
              FROM payment_transactions pt
              LEFT JOIN payment_gateways pg ON pt.gateway_id = pg.id
              LEFT JOIN orders o ON pt.order_id = o.id
              WHERE pt.id = ?";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$id]);
    
    $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($transaction) {
        echo json_encode($transaction);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Transaction not found']);
    }
}

// Process payment
function processPayment($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['order_id']) || !isset($data['amount']) || !isset($data['gateway_type'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields']);
        return;
    }
    
    // Get gateway configuration
    $query = "SELECT * FROM payment_gateways WHERE gateway_type = ? AND is_active = 1";
    $stmt = $db->prepare($query);
    $stmt->execute([$data['gateway_type']]);
    $gateway = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$gateway) {
        http_response_code(400);
        echo json_encode(['error' => 'Payment gateway not configured or inactive']);
        return;
    }
    
    $db->beginTransaction();
    
    try {
        // Create transaction record
        $dbTransactionUuid = UUID::generate();
        $transactionId = 'txn_' . UUID::generate();
        
        $query = "INSERT INTO payment_transactions 
                  (id, order_id, gateway_id, transaction_id, payment_method, amount, currency, status, customer_email, customer_name) 
                  VALUES (?, ?, ?, ?, ?, ?, ?, 'processing', ?, ?)";
        
        $stmt = $db->prepare($query);
        $stmt->execute([
            $dbTransactionUuid,
            $data['order_id'],
            $gateway['id'],
            $transactionId,
            $data['payment_method'] ?? 'card',
            $data['amount'],
            $data['currency'] ?? 'USD',
            $data['customer_email'] ?? null,
            $data['customer_name'] ?? null
        ]);
        
        $dbTransactionId = $dbTransactionUuid;
        
        // Process payment based on gateway type
        $result = null;
        switch ($gateway['gateway_type']) {
            case 'stripe':
                $result = processStripePayment($gateway, $data, $transactionId);
                break;
            case 'paypal':
                $result = processPayPalPayment($gateway, $data, $transactionId);
                break;
            case 'square':
                $result = processSquarePayment($gateway, $data, $transactionId);
                break;

            default:
                throw new Exception('Unsupported gateway type');
        }
        
        // Update transaction with result
        $status = $result['success'] ? 'completed' : 'failed';
        $query = "UPDATE payment_transactions 
                  SET status = ?, gateway_response = ?, error_message = ?, updated_at = CURRENT_TIMESTAMP
                  WHERE id = ?";
        
        $stmt = $db->prepare($query);
        $stmt->execute([
            $status,
            json_encode($result),
            $result['error'] ?? null,
            $dbTransactionId
        ]);
        
        if ($result['success']) {
            // Update order status
            $query = "UPDATE orders SET status = 'completed' WHERE id = ?";
            $stmt = $db->prepare($query);
            $stmt->execute([$data['order_id']]);
            
            // Create payment record
            $query = "INSERT INTO payments (order_id, payment_method, amount, transaction_id) 
                      VALUES (?, ?, ?, ?)";
            $stmt = $db->prepare($query);
            $stmt->execute([
                $data['order_id'],
                $data['payment_method'] ?? 'card',
                $data['amount'],
                $dbTransactionId
            ]);
        }
        
        $db->commit();
        
        echo json_encode([
            'success' => $result['success'],
            'transaction_id' => $dbTransactionId,
            'gateway_transaction_id' => $transactionId,
            'message' => $result['success'] ? 'Payment processed successfully' : 'Payment failed',
            'error' => $result['error'] ?? null
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Payment processing failed: ' . $e->getMessage()]);
    }
}

// Stripe payment processing (mock implementation)
function processStripePayment($gateway, $data, $transactionId) {
    // In production, use Stripe PHP SDK
    // require 'vendor/autoload.php';
    // \Stripe\Stripe::setApiKey($gateway['api_key']);
    
    // Mock implementation for demonstration
    if ($gateway['is_test_mode']) {
        // Simulate successful payment in test mode
        return [
            'success' => true,
            'transaction_id' => $transactionId,
            'gateway_response' => [
                'id' => 'ch_' . UUID::generate(),
                'amount' => $data['amount'] * 100, // Stripe uses cents
                'currency' => $data['currency'] ?? 'USD',
                'status' => 'succeeded'
            ]
        ];
    }
    
    // Production implementation would be:
    /*
    try {
        $charge = \Stripe\Charge::create([
            'amount' => $data['amount'] * 100,
            'currency' => $data['currency'] ?? 'usd',
            'source' => $data['token'],
            'description' => 'Order #' . $data['order_id'],
            'metadata' => ['order_id' => $data['order_id']]
        ]);
        
        return [
            'success' => true,
            'transaction_id' => $charge->id,
            'gateway_response' => $charge->jsonSerialize()
        ];
    } catch (\Stripe\Exception\CardException $e) {
        return [
            'success' => false,
            'error' => $e->getMessage()
        ];
    }
    */
    
    return ['success' => false, 'error' => 'Production mode not configured'];
}

// PayPal payment processing (mock implementation)
function processPayPalPayment($gateway, $data, $transactionId) {
    // Mock implementation
    if ($gateway['is_test_mode']) {
        return [
            'success' => true,
            'transaction_id' => $transactionId,
            'gateway_response' => [
                'id' => 'PAYID-' . strtoupper(UUID::generate()),
                'status' => 'COMPLETED',
                'amount' => $data['amount']
            ]
        ];
    }
    
    return ['success' => false, 'error' => 'Production mode not configured'];
}

// Square payment processing (mock implementation)
function processSquarePayment($gateway, $data, $transactionId) {
    // Mock implementation
    if ($gateway['is_test_mode']) {
        return [
            'success' => true,
            'transaction_id' => $transactionId,
            'gateway_response' => [
                'id' => strtoupper(UUID::generate()),
                'status' => 'COMPLETED',
                'amount_money' => [
                    'amount' => $data['amount'] * 100,
                    'currency' => $data['currency'] ?? 'USD'
                ]
            ]
        ];
    }
    
    return ['success' => false, 'error' => 'Production mode not configured'];
}

// Process refund
function processRefund($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['transaction_id']) || !isset($data['amount'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields']);
        return;
    }
    
    // Get original transaction
    $query = "SELECT pt.*, pg.* FROM payment_transactions pt
              JOIN payment_gateways pg ON pt.gateway_id = pg.id
              WHERE pt.id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$data['transaction_id']]);
    $transaction = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$transaction) {
        http_response_code(404);
        echo json_encode(['error' => 'Transaction not found']);
        return;
    }
    
    // Create refund record
    $refundUuid = UUID::generate();
    $refundTxnId = 'rfnd_' . UUID::generate();
    
    $query = "INSERT INTO payment_refunds (id, transaction_id, refund_transaction_id, amount, reason, status) 
              VALUES (?, ?, ?, ?, ?, 'pending')";
    $stmt = $db->prepare($query);
    $stmt->execute([
        $refundUuid,
        $data['transaction_id'],
        $refundTxnId,
        $data['amount'],
        $data['reason'] ?? null
    ]);
    
    $refundId = $refundUuid;
    
    // Process refund (mock)
    $refundSuccess = true; // In production, call actual gateway API
    
    if ($refundSuccess) {
        $query = "UPDATE payment_refunds SET status = 'completed', gateway_response = ? WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([json_encode(['status' => 'success']), $refundId]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Refund processed successfully',
            'refund_id' => $refundId
        ]);
    } else {
        $query = "UPDATE payment_refunds SET status = 'failed' WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$refundId]);
        
        http_response_code(500);
        echo json_encode(['error' => 'Refund processing failed']);
    }
}

// Update gateway configuration
function updateGateway($db, $id, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    $query = "UPDATE payment_gateways SET 
              api_key = ?, api_secret = ?, webhook_secret = ?, 
              is_active = ?, is_test_mode = ?, settings = ?,
              updated_at = CURRENT_TIMESTAMP
              WHERE id = ?";
    
    $stmt = $db->prepare($query);
    $result = $stmt->execute([
        $data['api_key'] ?? null,
        $data['api_secret'] ?? null,
        $data['webhook_secret'] ?? null,
        $data['is_active'] ?? false,
        $data['is_test_mode'] ?? true,
        json_encode($data['settings'] ?? []),
        $id
    ]);
    
    if ($result) {
        echo json_encode(['success' => true, 'message' => 'Gateway updated successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update gateway']);
    }
}

// Handle webhook (for payment status updates)
function handleWebhook($db) {
    $payload = file_get_contents('php://input');
    $data = json_decode($payload, true);
    
    // Verify webhook signature (implementation depends on gateway)
    // Log webhook for debugging
    error_log("Webhook received: " . $payload);
    
    // Process webhook based on event type
    // This is a simplified example
    if (isset($data['transaction_id'])) {
        $query = "UPDATE payment_transactions SET 
                  status = ?, gateway_response = ?, updated_at = CURRENT_TIMESTAMP
                  WHERE transaction_id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['status'] ?? 'completed',
            $payload,
            $data['transaction_id']
        ]);
    }
    
    http_response_code(200);
    echo json_encode(['received' => true]);
}
