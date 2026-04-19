<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    // Top customers by lifetime value
    $topCustomersQuery = "SELECT c.id, c.name, c.email, c.phone,
                          COUNT(o.id) as order_count,
                          SUM(o.total) as lifetime_value
                          FROM customers c
                          JOIN orders o ON c.id = o.customer_id
                          GROUP BY c.id
                          ORDER BY lifetime_value DESC
                          LIMIT 20";
    $topStmt = $db->prepare($topCustomersQuery);
    $topStmt->execute();
    $topCustomers = $topStmt->fetchAll(PDO::FETCH_ASSOC);

    // Total customers
    $totalQuery = "SELECT COUNT(*) as total FROM customers";
    $totalStmt = $db->prepare($totalQuery);
    $totalStmt->execute();
    $totalCustomers = $totalStmt->fetch(PDO::FETCH_ASSOC)['total'];

    // Average order value
    $avgQuery = "SELECT AVG(total) as avg_value FROM orders";
    $avgStmt = $db->prepare($avgQuery);
    $avgStmt->execute();
    $avgOrderValue = $avgStmt->fetch(PDO::FETCH_ASSOC)['avg_value'];

    // Repeat customers (customers with more than 1 order)
    $repeatQuery = "SELECT COUNT(DISTINCT customer_id) as repeat_count
                    FROM orders
                    WHERE customer_id IN (
                        SELECT customer_id
                        FROM orders
                        GROUP BY customer_id
                        HAVING COUNT(*) > 1
                    )";
    $repeatStmt = $db->prepare($repeatQuery);
    $repeatStmt->execute();
    $repeatCustomers = $repeatStmt->fetch(PDO::FETCH_ASSOC)['repeat_count'];

    sendJson([
        'success' => true,
        'data' => [
            'top_customers'    => $topCustomers,
            'total_customers'  => intval($totalCustomers),
            'avg_order_value'  => floatval($avgOrderValue ?? 0),
            'repeat_customers' => intval($repeatCustomers ?? 0),
        ]
    ]);
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
