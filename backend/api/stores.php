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
require_once '../config/Config.php';
require_once '../utils/JWT.php';
require_once '../middleware/AuthMiddleware.php';
require_once '../utils/UUID.php';

$database = new Database();
$db = $database->getConnection();

// Verify authentication
$user = AuthMiddleware::authenticate();
if (!$user) {
    http_response_code(401);
    echo json_encode(['error' => 'Unauthorized']);
    exit();
}

$method = $_SERVER['REQUEST_METHOD'];

try {
    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                getStore($db, $_GET['id']);
            } elseif (isset($_GET['transfers'])) {
                getTransfers($db, $_GET);
            } elseif (isset($_GET['inventory'])) {
                getStoreInventory($db, $_GET['store_id'] ?? null);
            } elseif (isset($_GET['stats'])) {
                getStoreStats($db, $_GET['store_id'] ?? null);
            } else {
                getAllStores($db);
            }
            break;

        case 'POST':
            if (isset($_GET['transfer'])) {
                createTransfer($db, $user);
            } else {
                createStore($db, $user);
            }
            break;

        case 'PUT':
            if (isset($_GET['id'])) {
                if (isset($_GET['transfer'])) {
                    updateTransferStatus($db, $_GET['id'], $user);
                } else {
                    updateStore($db, $_GET['id'], $user);
                }
            }
            break;

        case 'DELETE':
            if (isset($_GET['id'])) {
                deleteStore($db, $_GET['id'], $user);
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

// Get all stores
function getAllStores($db) {
    $query = "SELECT s.*, u.full_name as manager_name,
              (SELECT COUNT(*) FROM orders WHERE store_id = s.id) as total_orders,
              (SELECT COUNT(*) FROM users WHERE store_id = s.id) as total_employees
              FROM stores s
              LEFT JOIN users u ON s.manager_id = u.id
              ORDER BY s.is_main DESC, s.name ASC";
    
    $stmt = $db->prepare($query);
    $stmt->execute();
    
    $stores = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($stores);
}

// Get single store
function getStore($db, $id) {
    $query = "SELECT s.*, u.full_name as manager_name,
              (SELECT COUNT(*) FROM orders WHERE store_id = s.id) as total_orders,
              (SELECT COUNT(*) FROM users WHERE store_id = s.id) as total_employees,
              (SELECT COUNT(*) FROM store_inventory WHERE store_id = s.id) as total_products
              FROM stores s
              LEFT JOIN users u ON s.manager_id = u.id
              WHERE s.id = ?";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$id]);
    
    $store = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($store) {
        echo json_encode($store);
    } else {
        http_response_code(404);
        echo json_encode(['error' => 'Store not found']);
    }
}

// Create store
function createStore($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['name']) || !isset($data['code'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Name and code are required']);
        return;
    }
    
    $query = "INSERT INTO stores (id, name, code, address, phone, email, manager_id, is_active) 
              VALUES (?, ?, ?, ?, ?, ?, ?, ?)";
    
    $stmt = $db->prepare($query);
    $result = $stmt->execute([
        UUID::generate(),
        $data['name'],
        $data['code'],
        $data['address'] ?? null,
        $data['phone'] ?? null,
        $data['email'] ?? null,
        $data['manager_id'] ?? null,
        $data['is_active'] ?? true
    ]);
    
    if ($result) {
        $storeId = $db->lastInsertId();
        
        // Log audit
        logAudit($db, $user['id'], 'create', 'store', $storeId, "Created store: {$data['name']}");
        
        echo json_encode([
            'success' => true,
            'message' => 'Store created successfully',
            'id' => $storeId
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create store']);
    }
}

// Update store
function updateStore($db, $id, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    $query = "UPDATE stores SET 
              name = ?, code = ?, address = ?, phone = ?, email = ?, 
              manager_id = ?, is_active = ?, updated_at = CURRENT_TIMESTAMP
              WHERE id = ?";
    
    $stmt = $db->prepare($query);
    $result = $stmt->execute([
        $data['name'],
        $data['code'],
        $data['address'] ?? null,
        $data['phone'] ?? null,
        $data['email'] ?? null,
        $data['manager_id'] ?? null,
        $data['is_active'] ?? true,
        $id
    ]);
    
    if ($result) {
        logAudit($db, $user['id'], 'update', 'store', $id, "Updated store: {$data['name']}");
        echo json_encode(['success' => true, 'message' => 'Store updated successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update store']);
    }
}

// Delete store
function deleteStore($db, $id, $user) {
    // Check if it's the main store
    $query = "SELECT is_main FROM stores WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$id]);
    $store = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($store && $store['is_main']) {
        http_response_code(400);
        echo json_encode(['error' => 'Cannot delete main store']);
        return;
    }
    
    $query = "DELETE FROM stores WHERE id = ?";
    $stmt = $db->prepare($query);
    $result = $stmt->execute([$id]);
    
    if ($result) {
        logAudit($db, $user['id'], 'delete', 'store', $id, "Deleted store ID: $id");
        echo json_encode(['success' => true, 'message' => 'Store deleted successfully']);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to delete store']);
    }
}

// Get store inventory — falls back to global product stock if store_inventory is empty
function getStoreInventory($db, $storeId) {
    if (!$storeId) {
        http_response_code(400);
        echo json_encode(['error' => 'Store ID is required']);
        return;
    }

    // Check if this store has any store_inventory rows
    $check = $db->prepare("SELECT COUNT(*) as cnt FROM store_inventory WHERE store_id = ?");
    $check->execute([$storeId]);
    $hasRows = (int)$check->fetch(PDO::FETCH_ASSOC)['cnt'] > 0;

    if ($hasRows) {
        // Use store-specific inventory
        $query = "SELECT si.id, si.store_id, si.product_id, si.quantity,
                  p.name as product_name, p.barcode, p.selling_price, p.cost_price,
                  c.name as category_name
                  FROM store_inventory si
                  JOIN products p ON si.product_id = p.id
                  LEFT JOIN categories c ON p.category_id = c.id
                  WHERE si.store_id = ? AND p.is_active = 1
                  ORDER BY p.name ASC";
        $stmt = $db->prepare($query);
        $stmt->execute([$storeId]);
    } else {
        // Fall back to global product stock
        $query = "SELECT
                  UUID() as id,
                  ? as store_id,
                  p.id as product_id,
                  p.stock_quantity as quantity,
                  p.name as product_name, p.barcode, p.selling_price, p.cost_price,
                  c.name as category_name
                  FROM products p
                  LEFT JOIN categories c ON p.category_id = c.id
                  WHERE p.is_active = 1
                  ORDER BY p.name ASC";
        $stmt = $db->prepare($query);
        $stmt->execute([$storeId]);
    }

    $inventory = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($inventory);
}

// Create transfer
function createTransfer($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['from_store_id']) || !isset($data['to_store_id']) || 
        !isset($data['product_id']) || !isset($data['quantity'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Missing required fields']);
        return;
    }
    
    // Check if source store has enough stock
    $query = "SELECT quantity FROM store_inventory WHERE store_id = ? AND product_id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$data['from_store_id'], $data['product_id']]);
    $inventory = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$inventory || $inventory['quantity'] < $data['quantity']) {
        http_response_code(400);
        echo json_encode(['error' => 'Insufficient stock in source store']);
        return;
    }
    
    // Generate transfer number
    $prefix = Config::get('TRANSFER_NUMBER_PREFIX', 'TRF');
    $transferNumber = $prefix . '-' . date('Ymd') . '-' . strtoupper(substr(uniqid(), -6));
    
    $query = "INSERT INTO store_transfers 
              (id, transfer_number, from_store_id, to_store_id, product_id, quantity, initiated_by, notes, status) 
              VALUES (?, ?, ?, ?, ?, ?, ?, ?, 'pending')";
    
    $stmt = $db->prepare($query);
    $transferId = UUID::generate();
    $result = $stmt->execute([
        $transferId,
        $transferNumber,
        $data['from_store_id'],
        $data['to_store_id'],
        $data['product_id'],
        $data['quantity'],
        $user['id'],
        $data['notes'] ?? null
    ]);
    
    if ($result) {
        logAudit($db, $user['id'], 'create', 'transfer', $transferId, "Created transfer: $transferNumber");
        
        echo json_encode([
            'success' => true,
            'message' => 'Transfer created successfully',
            'id' => $transferId,
            'transfer_number' => $transferNumber
        ]);
    } else {
        http_response_code(500);
        echo json_encode(['error' => 'Failed to create transfer']);
    }
}

// Get transfers
function getTransfers($db, $params) {
    $where = [];
    $bindings = [];
    
    if (isset($params['store_id'])) {
        $where[] = "(from_store_id = ? OR to_store_id = ?)";
        $bindings[] = $params['store_id'];
        $bindings[] = $params['store_id'];
    }
    
    if (isset($params['status'])) {
        $where[] = "status = ?";
        $bindings[] = $params['status'];
    }
    
    $whereClause = !empty($where) ? 'WHERE ' . implode(' AND ', $where) : '';
    
    $query = "SELECT st.*, 
              fs.name as from_store_name, ts.name as to_store_name,
              p.name as product_name, p.barcode,
              u.full_name as initiated_by_name
              FROM store_transfers st
              JOIN stores fs ON st.from_store_id = fs.id
              JOIN stores ts ON st.to_store_id = ts.id
              JOIN products p ON st.product_id = p.id
              JOIN users u ON st.initiated_by = u.id
              $whereClause
              ORDER BY st.created_at DESC";
    
    $stmt = $db->prepare($query);
    $stmt->execute($bindings);
    
    $transfers = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($transfers);
}

// Update transfer status
function updateTransferStatus($db, $id, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['status'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Status is required']);
        return;
    }
    
    // Get transfer details
    $query = "SELECT * FROM store_transfers WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$id]);
    $transfer = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if (!$transfer) {
        http_response_code(404);
        echo json_encode(['error' => 'Transfer not found']);
        return;
    }
    
    $db->beginTransaction();
    
    try {
        // Update transfer status
        $query = "UPDATE store_transfers SET status = ?, completed_at = ? WHERE id = ?";
        $stmt = $db->prepare($query);
        $completedAt = ($data['status'] === 'completed') ? date('Y-m-d H:i:s') : null;
        $stmt->execute([$data['status'], $completedAt, $id]);
        
        // If completed, update inventory
        if ($data['status'] === 'completed') {
            // Decrease from source store
            $query = "UPDATE store_inventory SET quantity = quantity - ? 
                      WHERE store_id = ? AND product_id = ?";
            $stmt = $db->prepare($query);
            $stmt->execute([$transfer['quantity'], $transfer['from_store_id'], $transfer['product_id']]);
            
            // Increase in destination store (or create if not exists)
            $query = "INSERT INTO store_inventory (id, store_id, product_id, quantity) 
                      VALUES (UUID(), ?, ?, ?)
                      ON DUPLICATE KEY UPDATE quantity = quantity + ?";
            $stmt = $db->prepare($query);
            $stmt->execute([
                $transfer['to_store_id'], 
                $transfer['product_id'], 
                $transfer['quantity'],
                $transfer['quantity']
            ]);
        }
        
        $db->commit();
        
        logAudit($db, $user['id'], 'update', 'transfer', $id, 
                 "Updated transfer status to: {$data['status']}");
        
        echo json_encode(['success' => true, 'message' => 'Transfer updated successfully']);
    } catch (Exception $e) {
        $db->rollBack();
        http_response_code(500);
        echo json_encode(['error' => 'Failed to update transfer: ' . $e->getMessage()]);
    }
}

// Get store statistics
function getStoreStats($db, $storeId) {
    if (!$storeId) {
        http_response_code(400);
        echo json_encode(['error' => 'Store ID is required']);
        return;
    }
    
    $stats = [];
    
    // Total sales
    $query = "SELECT COUNT(*) as total_orders, COALESCE(SUM(total), 0) as total_sales
              FROM orders WHERE store_id = ? AND status = 'completed'";
    $stmt = $db->prepare($query);
    $stmt->execute([$storeId]);
    $sales = $stmt->fetch(PDO::FETCH_ASSOC);
    $stats['sales'] = $sales;
    
    // Inventory value
    $query = "SELECT COUNT(*) as total_products, 
              COALESCE(SUM(si.quantity * p.cost_price), 0) as inventory_value
              FROM store_inventory si
              JOIN products p ON si.product_id = p.id
              WHERE si.store_id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$storeId]);
    $inventory = $stmt->fetch(PDO::FETCH_ASSOC);
    $stats['inventory'] = $inventory;
    
    // Employees
    $query = "SELECT COUNT(*) as total_employees FROM users WHERE store_id = ? AND is_active = 1";
    $stmt = $db->prepare($query);
    $stmt->execute([$storeId]);
    $employees = $stmt->fetch(PDO::FETCH_ASSOC);
    $stats['employees'] = $employees;
    
    // Pending transfers
    $query = "SELECT COUNT(*) as pending_in FROM store_transfers 
              WHERE to_store_id = ? AND status = 'pending'";
    $stmt = $db->prepare($query);
    $stmt->execute([$storeId]);
    $pendingIn = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $query = "SELECT COUNT(*) as pending_out FROM store_transfers 
              WHERE from_store_id = ? AND status = 'pending'";
    $stmt = $db->prepare($query);
    $stmt->execute([$storeId]);
    $pendingOut = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $stats['transfers'] = [
        'pending_in' => $pendingIn['pending_in'],
        'pending_out' => $pendingOut['pending_out']
    ];
    
    echo json_encode($stats);
}

// Log audit trail
function logAudit($db, $userId, $action, $entityType, $entityId, $description) {
    try {
        $query = "INSERT INTO audit_logs (user_id, action, entity_type, entity_id, description, ip_address) 
                  VALUES (?, ?, ?, ?, ?, ?)";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $userId,
            $action,
            $entityType,
            null, // entity_id is INT in schema, skip UUID values to avoid type error
            $description,
            $_SERVER['REMOTE_ADDR'] ?? null
        ]);
    } catch (Exception $e) {
        // Non-critical — don't fail the main operation if audit logging fails
        error_log('Audit log error: ' . $e->getMessage());
    }
}
