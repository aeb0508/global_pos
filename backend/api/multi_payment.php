<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    $data = json_decode(file_get_contents('php://input'), true);

    if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
        sendJson(['success' => false, 'message' => 'Method not allowed'], 405);
    }

    $db->beginTransaction();

    $orderNumber = 'ORD-' . date('Ymd') . '-' . rand(1000, 9999);

    $db->prepare('INSERT INTO orders (order_number, customer_id, user_id, subtotal, discount, tax, total)
                  VALUES (:on, :cid, :uid, :sub, :disc, :tax, :total)')
       ->execute([':on' => $orderNumber, ':cid' => $data['customer_id'] ?? null,
                  ':uid' => $data['user_id'] ?? 1, ':sub' => $data['subtotal'],
                  ':disc' => $data['discount'] ?? 0, ':tax' => $data['tax'] ?? 0,
                  ':total' => $data['total']]);

    $orderId = $db->lastInsertId();

    $itemStmt = $db->prepare('INSERT INTO order_items (order_id, product_id, product_name, quantity, unit_price, total_price)
                               VALUES (:oid, :pid, :pname, :qty, :up, :tp)');
    foreach ($data['items'] as $item) {
        $itemStmt->execute([':oid' => $orderId, ':pid' => $item['product_id'],
                            ':pname' => $item['product_name'], ':qty' => $item['quantity'],
                            ':up' => $item['unit_price'], ':tp' => $item['total_price']]);
        $db->prepare('UPDATE products SET stock_quantity = stock_quantity - :qty WHERE id = :pid')
           ->execute([':qty' => $item['quantity'], ':pid' => $item['product_id']]);
    }

    $payStmt = $db->prepare('INSERT INTO payments (order_id, payment_method, amount) VALUES (:oid, :method, :amount)');
    foreach ($data['payments'] as $payment) {
        $payStmt->execute([':oid' => $orderId, ':method' => $payment['method'], ':amount' => $payment['amount']]);
    }

    $db->commit();
    sendJson(['success' => true, 'data' => ['id' => $orderId, 'order_number' => $orderNumber],
              'message' => 'Order processed with multiple payments']);
} catch (Exception $e) {
    if (isset($db) && $db->inTransaction()) $db->rollBack();
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
