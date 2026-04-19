<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET' && isset($_GET['logs'])) {
        AuthMiddleware::checkPermission($currentUser, 'inventory', 'view');
        $stmt = $db->prepare('SELECT il.*, p.name as product_name, u.full_name as user_name
                  FROM inventory_logs il
                  JOIN products p ON il.product_id = p.id
                  JOIN users u ON il.user_id = u.id
                  ORDER BY il.created_at DESC LIMIT 50');
        $stmt->execute();
        sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    } elseif ($method === 'POST') {
        AuthMiddleware::checkPermission($currentUser, 'inventory', 'edit');
        $db->beginTransaction();
        $db->prepare('UPDATE products SET stock_quantity = stock_quantity + :qc WHERE id = :pid')
           ->execute([':qc' => $data['quantity_change'], ':pid' => $data['product_id']]);
        $db->prepare('INSERT INTO inventory_logs (product_id, user_id, type, quantity_change, notes)
                      VALUES (:pid, :uid, "adjustment", :qc, :notes)')
           ->execute([':pid' => $data['product_id'], ':uid' => $currentUser['id'],
                      ':qc' => $data['quantity_change'], ':notes' => $data['notes'] ?? '']);
        $db->commit();

        // Trigger low stock alert if needed
        require_once __DIR__ . '/../utils/NotificationHelper.php';
        sendLowStockAlertIfEnabled($db, $data['product_id']);

        sendJson(['success' => true, 'message' => 'Stock adjusted successfully']);
    }
} catch (Exception $e) {
    if (isset($db) && $db->inTransaction()) $db->rollBack();
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
