<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    // Fast moving items (top 10 by sales)
    $fastMovingQuery = "SELECT p.id, p.name, p.stock_quantity, 
                        SUM(oi.quantity) as total_sold,
                        SUM(oi.total_price) as revenue
                        FROM products p
                        JOIN order_items oi ON p.id = oi.product_id
                        JOIN orders o ON oi.order_id = o.id
                        WHERE o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                        GROUP BY p.id
                        ORDER BY total_sold DESC
                        LIMIT 10";
    $fastStmt = $db->prepare($fastMovingQuery);
    $fastStmt->execute();
    $fastMoving = $fastStmt->fetchAll(PDO::FETCH_ASSOC);

    // Slow moving items (products with low sales)
    $slowMovingQuery = "SELECT p.id, p.name, p.stock_quantity,
                        COALESCE(SUM(oi.quantity), 0) as total_sold
                        FROM products p
                        LEFT JOIN order_items oi ON p.id = oi.product_id
                        LEFT JOIN orders o ON oi.order_id = o.id 
                        AND o.created_at >= DATE_SUB(NOW(), INTERVAL 30 DAY)
                        WHERE p.stock_quantity > 0
                        GROUP BY p.id
                        HAVING total_sold < 5
                        ORDER BY total_sold ASC
                        LIMIT 10";
    $slowStmt = $db->prepare($slowMovingQuery);
    $slowStmt->execute();
    $slowMoving = $slowStmt->fetchAll(PDO::FETCH_ASSOC);

    // Low stock items
    $lowStockQuery = "SELECT id, name, stock_quantity, low_stock_threshold
                      FROM products
                      WHERE stock_quantity <= low_stock_threshold
                      AND is_active = 1
                      ORDER BY stock_quantity ASC";
    $lowStmt = $db->prepare($lowStockQuery);
    $lowStmt->execute();
    $lowStock = $lowStmt->fetchAll(PDO::FETCH_ASSOC);

    // Total stock value
    $valueQuery = "SELECT SUM(stock_quantity * cost_price) as total_value
                   FROM products
                   WHERE is_active = 1";
    $valueStmt = $db->prepare($valueQuery);
    $valueStmt->execute();
    $stockValue = $valueStmt->fetch(PDO::FETCH_ASSOC);

    sendJson([
        'success' => true,
        'data' => [
            'fast_moving'       => $fastMoving,
            'slow_moving'       => $slowMoving,
            'low_stock'         => $lowStock,
            'total_stock_value' => floatval($stockValue['total_value'] ?? 0),
        ]
    ]);
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
