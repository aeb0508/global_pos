<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, POST, PUT');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/Database.php';
require_once '../utils/JWT.php';
require_once '../middleware/AuthMiddleware.php';

$database = new Database();
$db = $database->getConnection();

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
            if (isset($_GET['changes'])) {
                getChanges($db, $user, $_GET);
            } elseif (isset($_GET['conflicts'])) {
                getConflicts($db, $user);
            } elseif (isset($_GET['status'])) {
                getSyncStatus($db, $user, $_GET['device_id'] ?? null);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid request']);
            }
            break;

        case 'POST':
            if (isset($_GET['register_device'])) {
                registerDevice($db, $user);
            } elseif (isset($_GET['sync'])) {
                syncData($db, $user);
            } elseif (isset($_GET['resolve_conflict'])) {
                resolveConflict($db, $user);
            } else {
                http_response_code(400);
                echo json_encode(['error' => 'Invalid request']);
            }
            break;

        case 'PUT':
            if (isset($_GET['device_id'])) {
                updateDeviceSync($db, $user, $_GET['device_id']);
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

// Register device for offline sync
function registerDevice($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['device_id'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Device ID is required']);
        return;
    }
    
    // Check if device already exists
    $query = "SELECT id FROM devices WHERE device_id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$data['device_id']]);
    $existing = $stmt->fetch(PDO::FETCH_ASSOC);
    
    if ($existing) {
        // Update existing device
        $query = "UPDATE devices SET user_id = ?, device_name = ?, device_type = ?, 
                  platform = ?, is_active = 1, updated_at = CURRENT_TIMESTAMP
                  WHERE device_id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $user['id'],
            $data['device_name'] ?? 'Unknown Device',
            $data['device_type'] ?? 'desktop',
            $data['platform'] ?? 'unknown',
            $data['device_id']
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Device updated successfully',
            'device_id' => $data['device_id']
        ]);
    } else {
        // Register new device
        $query = "INSERT INTO devices (device_id, user_id, device_name, device_type, platform) 
                  VALUES (?, ?, ?, ?, ?)";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['device_id'],
            $user['id'],
            $data['device_name'] ?? 'Unknown Device',
            $data['device_type'] ?? 'desktop',
            $data['platform'] ?? 'unknown'
        ]);
        
        echo json_encode([
            'success' => true,
            'message' => 'Device registered successfully',
            'device_id' => $data['device_id']
        ]);
    }
}

// Get changes since last sync
function getChanges($db, $user, $params) {
    $lastSync = $params['last_sync'] ?? '1970-01-01 00:00:00';
    $deviceId = $params['device_id'] ?? null;
    
    $changes = [
        'products' => [],
        'orders' => [],
        'customers' => [],
        'categories' => [],
        'timestamp' => date('Y-m-d H:i:s')
    ];
    
    // Get products changed since last sync
    $query = "SELECT * FROM products WHERE last_modified > ? ORDER BY last_modified ASC";
    $stmt = $db->prepare($query);
    $stmt->execute([$lastSync]);
    $changes['products'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get orders changed since last sync
    $query = "SELECT o.*, 
              (SELECT JSON_ARRAYAGG(JSON_OBJECT('id', oi.id, 'product_id', oi.product_id, 
               'product_name', oi.product_name, 'quantity', oi.quantity, 
               'unit_price', oi.unit_price, 'total_price', oi.total_price))
               FROM order_items oi WHERE oi.order_id = o.id) as items
              FROM orders o WHERE o.last_modified > ? ORDER BY o.last_modified ASC";
    $stmt = $db->prepare($query);
    $stmt->execute([$lastSync]);
    $changes['orders'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get customers changed since last sync
    $query = "SELECT * FROM customers WHERE last_modified > ? ORDER BY last_modified ASC";
    $stmt = $db->prepare($query);
    $stmt->execute([$lastSync]);
    $changes['customers'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Get categories changed since last sync
    $query = "SELECT * FROM categories WHERE last_modified > ? ORDER BY last_modified ASC";
    $stmt = $db->prepare($query);
    $stmt->execute([$lastSync]);
    $changes['categories'] = $stmt->fetchAll(PDO::FETCH_ASSOC);
    
    // Update device last sync time
    if ($deviceId) {
        $query = "UPDATE devices SET last_sync = CURRENT_TIMESTAMP WHERE device_id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$deviceId]);
    }
    
    echo json_encode($changes);
}

// Sync data from offline device
function syncData($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['device_id']) || !isset($data['operations'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Device ID and operations are required']);
        return;
    }
    
    // Create sync log
    $query = "INSERT INTO sync_logs (device_id, user_id, sync_type, status) 
              VALUES (?, ?, 'incremental', 'started')";
    $stmt = $db->prepare($query);
    $stmt->execute([$data['device_id'], $user['id']]);
    $syncLogId = $db->lastInsertId();
    
    $synced = 0;
    $conflicts = 0;
    $errors = [];
    
    $db->beginTransaction();
    
    try {
        foreach ($data['operations'] as $operation) {
            $result = processOperation($db, $user, $operation, $data['device_id']);
            
            if ($result['success']) {
                $synced++;
            } elseif ($result['conflict']) {
                $conflicts++;
            } else {
                $errors[] = $result['error'];
            }
        }
        
        $db->commit();
        
        // Update sync log
        $query = "UPDATE sync_logs SET 
                  entities_synced = ?, conflicts_found = ?, 
                  status = 'completed', completed_at = CURRENT_TIMESTAMP
                  WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$synced, $conflicts, $syncLogId]);
        
        echo json_encode([
            'success' => true,
            'synced' => $synced,
            'conflicts' => $conflicts,
            'errors' => $errors,
            'sync_log_id' => $syncLogId
        ]);
        
    } catch (Exception $e) {
        $db->rollBack();
        
        // Update sync log with error
        $query = "UPDATE sync_logs SET status = 'failed', error_message = ?, 
                  completed_at = CURRENT_TIMESTAMP WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$e->getMessage(), $syncLogId]);
        
        throw $e;
    }
}

// Process individual sync operation
function processOperation($db, $user, $operation, $deviceId) {
    $entityType = $operation['entity_type'];
    $operationType = $operation['operation_type'];
    $entityData = $operation['data'];
    $localVersion = $operation['sync_version'] ?? 1;
    
    // Add to sync queue
    $query = "INSERT INTO sync_queue (user_id, device_id, operation_type, entity_type, entity_id, data, status) 
              VALUES (?, ?, ?, ?, ?, ?, 'pending')";
    $stmt = $db->prepare($query);
    $stmt->execute([
        $user['id'],
        $deviceId,
        $operationType,
        $entityType,
        $entityData['id'] ?? null,
        json_encode($entityData)
    ]);
    $queueId = $db->lastInsertId();
    
    try {
        switch ($entityType) {
            case 'product':
                return syncProduct($db, $operationType, $entityData, $localVersion, $queueId);
            case 'order':
                return syncOrder($db, $operationType, $entityData, $localVersion, $queueId);
            case 'customer':
                return syncCustomer($db, $operationType, $entityData, $localVersion, $queueId);
            default:
                return ['success' => false, 'error' => 'Unknown entity type'];
        }
    } catch (Exception $e) {
        // Update queue status
        $query = "UPDATE sync_queue SET status = 'failed', error_message = ? WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$e->getMessage(), $queueId]);
        
        return ['success' => false, 'error' => $e->getMessage()];
    }
}

// Sync product
function syncProduct($db, $operation, $data, $localVersion, $queueId) {
    if ($operation === 'create') {
        $query = "INSERT INTO products (name, barcode, category_id, description, cost_price, 
                  selling_price, stock_quantity, low_stock_threshold, sync_version) 
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['name'], $data['barcode'] ?? null, $data['category_id'] ?? null,
            $data['description'] ?? null, $data['cost_price'], $data['selling_price'],
            $data['stock_quantity'] ?? 0, $data['low_stock_threshold'] ?? 10
        ]);
        
        updateQueueStatus($db, $queueId, 'synced');
        return ['success' => true];
        
    } elseif ($operation === 'update') {
        // Check for conflicts
        $query = "SELECT sync_version FROM products WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$data['id']]);
        $current = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if ($current && $current['sync_version'] != $localVersion) {
            // Conflict detected
            createConflict($db, $queueId, 'product', $data['id'], $data, $current);
            updateQueueStatus($db, $queueId, 'conflict');
            return ['success' => false, 'conflict' => true];
        }
        
        $query = "UPDATE products SET name = ?, barcode = ?, category_id = ?, description = ?, 
                  cost_price = ?, selling_price = ?, stock_quantity = ?, low_stock_threshold = ?,
                  sync_version = sync_version + 1, last_modified = CURRENT_TIMESTAMP
                  WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['name'], $data['barcode'] ?? null, $data['category_id'] ?? null,
            $data['description'] ?? null, $data['cost_price'], $data['selling_price'],
            $data['stock_quantity'] ?? 0, $data['low_stock_threshold'] ?? 10,
            $data['id']
        ]);
        
        updateQueueStatus($db, $queueId, 'synced');
        return ['success' => true];
    }
    
    return ['success' => false, 'error' => 'Unsupported operation'];
}

// Sync order
function syncOrder($db, $operation, $data, $localVersion, $queueId) {
    if ($operation === 'create') {
        $query = "INSERT INTO orders (order_number, customer_id, user_id, subtotal, discount, 
                  tax, total, status, sync_version) 
                  VALUES (?, ?, ?, ?, ?, ?, ?, ?, 1)";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['order_number'], $data['customer_id'] ?? null, $data['user_id'],
            $data['subtotal'], $data['discount'] ?? 0, $data['tax'] ?? 0,
            $data['total'], $data['status'] ?? 'completed'
        ]);
        
        $orderId = $db->lastInsertId();
        
        // Insert order items
        if (isset($data['items'])) {
            foreach ($data['items'] as $item) {
                $query = "INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price) 
                          VALUES (?, ?, ?, ?, ?, ?)";
                $stmt = $db->prepare($query);
                $stmt->execute([
                    $orderId, $item['product_id'], $item['product_name'],
                    $item['quantity'], $item['unit_price'], $item['total_price']
                ]);
            }
        }
        
        updateQueueStatus($db, $queueId, 'synced');
        return ['success' => true];
    }
    
    return ['success' => false, 'error' => 'Only create operation supported for orders'];
}

// Sync customer
function syncCustomer($db, $operation, $data, $localVersion, $queueId) {
    if ($operation === 'create') {
        $query = "INSERT INTO customers (name, email, phone, address) VALUES (?, ?, ?, ?)";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['name'], $data['email'] ?? null, 
            $data['phone'] ?? null, $data['address'] ?? null
        ]);
        
        updateQueueStatus($db, $queueId, 'synced');
        return ['success' => true];
        
    } elseif ($operation === 'update') {
        $query = "UPDATE customers SET name = ?, email = ?, phone = ?, address = ?,
                  last_modified = CURRENT_TIMESTAMP WHERE id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([
            $data['name'], $data['email'] ?? null,
            $data['phone'] ?? null, $data['address'] ?? null,
            $data['id']
        ]);
        
        updateQueueStatus($db, $queueId, 'synced');
        return ['success' => true];
    }
    
    return ['success' => false, 'error' => 'Unsupported operation'];
}

// Create conflict record
function createConflict($db, $queueId, $entityType, $entityId, $localData, $serverData) {
    $query = "INSERT INTO sync_conflicts (sync_queue_id, entity_type, entity_id, local_data, server_data) 
              VALUES (?, ?, ?, ?, ?)";
    $stmt = $db->prepare($query);
    $stmt->execute([
        $queueId, $entityType, $entityId,
        json_encode($localData), json_encode($serverData)
    ]);
}

// Update queue status
function updateQueueStatus($db, $queueId, $status) {
    $query = "UPDATE sync_queue SET status = ?, synced_at = CURRENT_TIMESTAMP WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$status, $queueId]);
}

// Get conflicts
function getConflicts($db, $user) {
    $query = "SELECT sc.*, sq.device_id, sq.entity_type as queue_entity_type
              FROM sync_conflicts sc
              JOIN sync_queue sq ON sc.sync_queue_id = sq.id
              WHERE sq.user_id = ? AND sc.resolution = 'pending'
              ORDER BY sc.created_at DESC";
    
    $stmt = $db->prepare($query);
    $stmt->execute([$user['id']]);
    
    $conflicts = $stmt->fetchAll(PDO::FETCH_ASSOC);
    echo json_encode($conflicts);
}

// Resolve conflict
function resolveConflict($db, $user) {
    $data = json_decode(file_get_contents("php://input"), true);
    
    if (!isset($data['conflict_id']) || !isset($data['resolution'])) {
        http_response_code(400);
        echo json_encode(['error' => 'Conflict ID and resolution are required']);
        return;
    }
    
    $query = "UPDATE sync_conflicts SET resolution = ?, resolved_by = ?, resolved_at = CURRENT_TIMESTAMP 
              WHERE id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$data['resolution'], $user['id'], $data['conflict_id']]);
    
    echo json_encode(['success' => true, 'message' => 'Conflict resolved']);
}

// Get sync status
function getSyncStatus($db, $user, $deviceId) {
    $status = [];
    
    if ($deviceId) {
        // Get device info
        $query = "SELECT * FROM devices WHERE device_id = ? AND user_id = ?";
        $stmt = $db->prepare($query);
        $stmt->execute([$deviceId, $user['id']]);
        $status['device'] = $stmt->fetch(PDO::FETCH_ASSOC);
        
        // Get pending operations
        $query = "SELECT COUNT(*) as pending FROM sync_queue 
                  WHERE device_id = ? AND status = 'pending'";
        $stmt = $db->prepare($query);
        $stmt->execute([$deviceId]);
        $status['pending_operations'] = $stmt->fetch(PDO::FETCH_ASSOC)['pending'];
        
        // Get conflicts
        $query = "SELECT COUNT(*) as conflicts FROM sync_conflicts sc
                  JOIN sync_queue sq ON sc.sync_queue_id = sq.id
                  WHERE sq.device_id = ? AND sc.resolution = 'pending'";
        $stmt = $db->prepare($query);
        $stmt->execute([$deviceId]);
        $status['pending_conflicts'] = $stmt->fetch(PDO::FETCH_ASSOC)['conflicts'];
    }
    
    echo json_encode($status);
}

// Update device sync timestamp
function updateDeviceSync($db, $user, $deviceId) {
    $query = "UPDATE devices SET last_sync = CURRENT_TIMESTAMP WHERE device_id = ? AND user_id = ?";
    $stmt = $db->prepare($query);
    $stmt->execute([$deviceId, $user['id']]);
    
    echo json_encode(['success' => true, 'message' => 'Device sync updated']);
}
