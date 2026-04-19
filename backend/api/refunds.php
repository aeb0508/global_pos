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

    if ($method === 'GET') {
        AuthMiddleware::checkPermission($currentUser, 'refunds', 'view');
        if (isset($_GET['id'])) {
            $stmt = $db->prepare('SELECT r.*, o.order_number, u.full_name as processed_by
                                  FROM refunds r
                                  JOIN orders o ON r.order_id = o.id
                                  JOIN users u ON r.user_id = u.id
                                  WHERE r.id = :id');
            $stmt->execute([':id' => $_GET['id']]);
            sendJson(['success' => true, 'data' => $stmt->fetch(PDO::FETCH_ASSOC)]);
        } else {
            $stmt = $db->prepare('SELECT r.*, o.order_number, u.full_name as processed_by
                                  FROM refunds r
                                  JOIN orders o ON r.order_id = o.id
                                  JOIN users u ON r.user_id = u.id
                                  ORDER BY r.created_at DESC');
            $stmt->execute();
            sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        }

    } elseif ($method === 'POST') {
        AuthMiddleware::checkPermission($currentUser, 'refunds', 'create');
        $db->beginTransaction();

        $orderStmt = $db->prepare('SELECT * FROM orders WHERE order_number = :on');
        $orderStmt->execute([':on' => $data['order_number']]);
        $order = $orderStmt->fetch(PDO::FETCH_ASSOC);
        if (!$order) throw new Exception('Order not found');

        $refundId = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
            mt_rand(0, 0xffff), mt_rand(0, 0xffff),
            mt_rand(0, 0xffff),
            mt_rand(0, 0x0fff) | 0x4000,
            mt_rand(0, 0x3fff) | 0x8000,
            mt_rand(0, 0xffff), mt_rand(0, 0xffff), mt_rand(0, 0xffff)
        );

        $db->prepare('INSERT INTO refunds (id, order_id, user_id, amount, reason, type, status)
                      VALUES (:id, :oid, :uid, :amount, :reason, :type, :status)')
           ->execute([':id' => $refundId, ':oid' => $order['id'], ':uid' => $currentUser['id'],
                      ':amount' => $data['amount'], ':reason' => $data['reason'],
                      ':type' => $data['type'], ':status' => $data['status'] ?? 'approved']);

        if ($data['type'] === 'full') {
            $db->prepare('UPDATE orders SET status = "refunded" WHERE id = :id')
               ->execute([':id' => $order['id']]);
        }

        $items = $db->prepare('SELECT * FROM order_items WHERE order_id = :id');
        $items->execute([':id' => $order['id']]);
        foreach ($items->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $db->prepare('UPDATE products SET stock_quantity = stock_quantity + :qty WHERE id = :pid')
               ->execute([':qty' => $item['quantity'], ':pid' => $item['product_id']]);
        }

        $db->commit();
        sendJson(['success' => true, 'message' => 'Refund processed successfully']);

    } elseif ($method === 'PUT') {
        AuthMiddleware::checkPermission($currentUser, 'refunds', 'edit');
        if (!isset($_GET['id'])) throw new Exception('Refund ID required');

        $db->prepare('UPDATE refunds SET amount = :amount, reason = :reason, type = :type, status = :status
                      WHERE id = :id')
           ->execute([':amount' => $data['amount'], ':reason' => $data['reason'],
                      ':type' => $data['type'], ':status' => $data['status'], ':id' => $_GET['id']]);

        sendJson(['success' => true, 'message' => 'Refund updated successfully']);

    } elseif ($method === 'DELETE') {
        AuthMiddleware::checkPermission($currentUser, 'refunds', 'delete');
        if (!isset($_GET['id'])) throw new Exception('Refund ID required');

        $db->beginTransaction();

        $refundStmt = $db->prepare('SELECT * FROM refunds WHERE id = :id');
        $refundStmt->execute([':id' => $_GET['id']]);
        $refund = $refundStmt->fetch(PDO::FETCH_ASSOC);
        if (!$refund) throw new Exception('Refund not found');

        $items = $db->prepare('SELECT * FROM order_items WHERE order_id = :id');
        $items->execute([':id' => $refund['order_id']]);
        foreach ($items->fetchAll(PDO::FETCH_ASSOC) as $item) {
            $db->prepare('UPDATE products SET stock_quantity = stock_quantity - :qty WHERE id = :pid')
               ->execute([':qty' => $item['quantity'], ':pid' => $item['product_id']]);
        }

        $db->prepare('UPDATE orders SET status = "completed" WHERE id = :id')
           ->execute([':id' => $refund['order_id']]);

        $db->prepare('DELETE FROM refunds WHERE id = :id')->execute([':id' => $_GET['id']]);

        $db->commit();
        sendJson(['success' => true, 'message' => 'Refund deleted successfully']);
    }
} catch (Exception $e) {
    if (isset($db) && $db->inTransaction()) $db->rollBack();
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
