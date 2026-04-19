<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();
    AuthMiddleware::checkPermission($currentUser, 'reports', 'view');

    $database = new Database();
    $db = $database->getConnection();

    $reportType = $_GET['type'] ?? 'sales';
    $startDate  = $_GET['start_date'] ?? date('Y-m-d', strtotime('-30 days'));
    $endDate    = $_GET['end_date'] ?? date('Y-m-d');
    $groupBy    = $_GET['group_by'] ?? 'day';

    switch ($reportType) {
        case 'sales':
            if ($groupBy === 'hour') {
                $query = "SELECT 
                    DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00') as date,
                    COUNT(*) as total_orders,
                    SUM(subtotal) as subtotal,
                    SUM(discount) as discount,
                    SUM(tax) as tax,
                    SUM(total) as total_sales
                FROM orders 
                WHERE created_at >= :start_date
                AND created_at < DATE_ADD(:end_date, INTERVAL 1 DAY)
                AND status = 'completed'
                GROUP BY DATE_FORMAT(created_at, '%Y-%m-%d %H:00:00')
                ORDER BY date ASC";
            } else {
                $query = "SELECT 
                    DATE(created_at) as date,
                    COUNT(*) as total_orders,
                    SUM(subtotal) as subtotal,
                    SUM(discount) as discount,
                    SUM(tax) as tax,
                    SUM(total) as total_sales
                FROM orders 
                WHERE created_at >= :start_date
                AND created_at < DATE_ADD(:end_date, INTERVAL 1 DAY)
                AND status = 'completed'
                GROUP BY DATE(created_at)
                ORDER BY date ASC";
            }
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':start_date', $startDate);
            $stmt->bindParam(':end_date', $endDate);
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Calculate totals
            $totals = [
                'total_orders' => array_sum(array_column($data, 'total_orders')),
                'total_sales' => array_sum(array_column($data, 'total_sales')),
                'total_discount' => array_sum(array_column($data, 'discount')),
                'total_tax' => array_sum(array_column($data, 'tax')),
            ];
            
            sendJson(['success' => true, 'data' => $data, 'totals' => $totals, 'period' => ['start' => $startDate, 'end' => $endDate]]);
            break;

        case 'profit':
            // Profit/Loss Report
            $query = "SELECT 
                DATE(o.created_at) as date,
                COUNT(o.id) as total_orders,
                SUM(oi.quantity * p.cost_price) as total_cost,
                SUM(oi.total_price) as total_revenue,
                SUM(oi.total_price - (oi.quantity * p.cost_price)) as gross_profit
            FROM orders o
            JOIN order_items oi ON o.id = oi.order_id
            JOIN products p ON oi.product_id = p.id
            WHERE DATE(o.created_at) BETWEEN :start_date AND :end_date
            AND o.status = 'completed'
            GROUP BY DATE(o.created_at)
            ORDER BY date DESC";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':start_date', $startDate);
            $stmt->bindParam(':end_date', $endDate);
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            // Calculate totals and profit margin
            $totalCost = array_sum(array_column($data, 'total_cost'));
            $totalRevenue = array_sum(array_column($data, 'total_revenue'));
            $grossProfit = $totalRevenue - $totalCost;
            $profitMargin = $totalRevenue > 0 ? ($grossProfit / $totalRevenue) * 100 : 0;
            
            $totals = [
                'total_orders' => array_sum(array_column($data, 'total_orders')),
                'total_cost' => $totalCost,
                'total_revenue' => $totalRevenue,
                'gross_profit' => $grossProfit,
                'profit_margin' => round($profitMargin, 2)
            ];
            
            sendJson(['success' => true, 'data' => $data, 'totals' => $totals, 'period' => ['start' => $startDate, 'end' => $endDate]]);
            break;

        case 'products':
            // Product Performance Report
            $query = "SELECT 
                p.id,
                p.name,
                p.barcode,
                c.name as category,
                SUM(oi.quantity) as total_sold,
                SUM(oi.total_price) as total_revenue,
                SUM(oi.quantity * p.cost_price) as total_cost,
                SUM(oi.total_price - (oi.quantity * p.cost_price)) as profit,
                p.stock_quantity as current_stock
            FROM products p
            LEFT JOIN order_items oi ON p.id = oi.product_id
            LEFT JOIN orders o ON oi.order_id = o.id AND DATE(o.created_at) BETWEEN :start_date AND :end_date AND o.status = 'completed'
            LEFT JOIN categories c ON p.category_id = c.id
            WHERE p.is_active = 1
            GROUP BY p.id
            ORDER BY total_sold DESC";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':start_date', $startDate);
            $stmt->bindParam(':end_date', $endDate);
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            sendJson(['success' => true, 'data' => $data, 'period' => ['start' => $startDate, 'end' => $endDate]]);
            break;

        case 'employees':
            // Employee Performance Report
            $query = "SELECT 
                u.id,
                u.full_name,
                u.role,
                COUNT(o.id) as total_orders,
                SUM(o.total) as total_sales,
                AVG(o.total) as average_order_value
            FROM users u
            LEFT JOIN orders o ON u.id = o.user_id AND DATE(o.created_at) BETWEEN :start_date AND :end_date AND o.status = 'completed'
            WHERE u.is_active = 1
            GROUP BY u.id
            ORDER BY total_sales DESC";
            
            $stmt = $db->prepare($query);
            $stmt->bindParam(':start_date', $startDate);
            $stmt->bindParam(':end_date', $endDate);
            $stmt->execute();
            $data = $stmt->fetchAll(PDO::FETCH_ASSOC);
            
            sendJson(['success' => true, 'data' => $data, 'period' => ['start' => $startDate, 'end' => $endDate]]);
            break;

        default:
            sendJson(['success' => false, 'message' => 'Invalid report type'], 400);
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
