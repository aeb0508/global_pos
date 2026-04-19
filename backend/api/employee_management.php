<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    $stmt = $db->prepare("SELECT u.id, u.username, u.full_name, u.email, u.role,
              COUNT(o.id) as order_count,
              COALESCE(SUM(o.total), 0) as total_sales,
              COALESCE(AVG(o.total), 0) as avg_order_value
              FROM users u
              LEFT JOIN orders o ON u.id = o.user_id
              WHERE u.is_active = 1
              GROUP BY u.id
              ORDER BY total_sales DESC");
    $stmt->execute();
    sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
