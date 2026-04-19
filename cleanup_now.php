<?php
/**
 * Direct Database Cleanup Script
 * Run this file in your browser: http://localhost/cleanup_now.php
 */

header('Content-Type: text/html; charset=utf-8');

echo '<!DOCTYPE html>
<html>
<head>
    <title>Database Cleanup</title>
    <style>
        body { font-family: Arial; max-width: 800px; margin: 50px auto; padding: 20px; background: #f5f5f5; }
        .container { background: white; padding: 30px; border-radius: 10px; box-shadow: 0 2px 10px rgba(0,0,0,0.1); }
        h1 { color: #333; }
        .success { background: #d4edda; color: #155724; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #28a745; }
        .error { background: #f8d7da; color: #721c24; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #dc3545; }
        .info { background: #d1ecf1; color: #0c5460; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #17a2b8; }
        .warning { background: #fff3cd; color: #856404; padding: 15px; border-radius: 5px; margin: 10px 0; border-left: 4px solid #ffc107; }
        button { background: #dc3545; color: white; padding: 15px 30px; border: none; border-radius: 5px; cursor: pointer; font-size: 16px; font-weight: bold; }
        button:hover { background: #c82333; }
        .step { margin: 20px 0; padding: 15px; background: #f8f9fa; border-radius: 5px; }
        ul { line-height: 1.8; }
    </style>
</head>
<body>
    <div class="container">
        <h1>🗑️ Database Cleanup Tool</h1>';

// Check if cleanup was requested
if (isset($_GET['confirm']) && $_GET['confirm'] === 'yes') {
    
    echo '<div class="info"><strong>Starting cleanup...</strong></div>';
    
    try {
        require_once __DIR__ . '/backend/config/Database.php';
        $database = new Database();
        $db = $database->getConnection();
        
        $results = [];
        
        // 1. Delete test products
        $stmt = $db->prepare("DELETE FROM products WHERE name LIKE '%test%' OR name LIKE '%Test%' OR name = 'test prod' OR name = 'test prod 2' OR name = 'test cat'");
        $stmt->execute();
        $deletedProducts = $stmt->rowCount();
        $results[] = "✅ Deleted $deletedProducts test products";
        
        // 2. Delete test categories
        $stmt = $db->prepare("DELETE FROM categories WHERE name LIKE '%test%' OR name LIKE '%Test%'");
        $stmt->execute();
        $deletedCategories = $stmt->rowCount();
        $results[] = "✅ Deleted $deletedCategories test categories";
        
        // 3. Delete test customers
        $stmt = $db->prepare("DELETE FROM customers WHERE name LIKE '%test%' OR name LIKE '%Test%' OR email LIKE '%test%'");
        $stmt->execute();
        $deletedCustomers = $stmt->rowCount();
        $results[] = "✅ Deleted $deletedCustomers test customers";
        
        // 4. Clean orphaned order items
        $stmt = $db->prepare("DELETE FROM order_items WHERE product_id NOT IN (SELECT id FROM products)");
        $stmt->execute();
        $deletedOrderItems = $stmt->rowCount();
        $results[] = "✅ Cleaned $deletedOrderItems orphaned order items";
        
        // 5. Clean orphaned inventory logs
        $stmt = $db->prepare("DELETE FROM inventory_logs WHERE product_id NOT IN (SELECT id FROM products)");
        $stmt->execute();
        $deletedLogs = $stmt->rowCount();
        $results[] = "✅ Cleaned $deletedLogs orphaned inventory logs";
        
        // 6. Clean orphaned store inventory
        $stmt = $db->prepare("DELETE FROM store_inventory WHERE product_id NOT IN (SELECT id FROM products)");
        $stmt->execute();
        $deletedInventory = $stmt->rowCount();
        $results[] = "✅ Cleaned $deletedInventory orphaned store inventory records";
        
        // Show results
        echo '<div class="success">';
        echo '<h2>✅ Cleanup Completed Successfully!</h2>';
        echo '<ul>';
        foreach ($results as $result) {
            echo "<li>$result</li>";
        }
        echo '</ul>';
        echo '</div>';
        
        // Show remaining products count
        $stmt = $db->query("SELECT COUNT(*) as count FROM products");
        $count = $stmt->fetch(PDO::FETCH_ASSOC)['count'];
        
        echo '<div class="info">';
        echo "<strong>Remaining products in database:</strong> $count";
        echo '</div>';
        
        echo '<div class="warning">';
        echo '<h3>⚠️ Important: Delete This File!</h3>';
        echo '<p>For security, delete this file now:</p>';
        echo '<code>c:\\xampp\\htdocs\\cleanup_now.php</code>';
        echo '</div>';
        
        echo '<div class="step">';
        echo '<h3>Next Steps:</h3>';
        echo '<ol>';
        echo '<li>Refresh your application to see the changes</li>';
        echo '<li>Verify test products are gone</li>';
        echo '<li>Delete this cleanup_now.php file</li>';
        echo '<li>Change your admin password from admin123</li>';
        echo '</ol>';
        echo '</div>';
        
    } catch (Exception $e) {
        echo '<div class="error">';
        echo '<strong>❌ Error:</strong> ' . htmlspecialchars($e->getMessage());
        echo '</div>';
    }
    
} else {
    // Show confirmation page
    echo '<div class="warning">';
    echo '<h2>⚠️ Warning</h2>';
    echo '<p>This will permanently delete:</p>';
    echo '<ul>';
    echo '<li>All products with "test" in the name (test prod, test prod 2, test cat)</li>';
    echo '<li>All test categories</li>';
    echo '<li>All test customers</li>';
    echo '<li>Orphaned database records</li>';
    echo '</ul>';
    echo '<p><strong>This action cannot be undone!</strong></p>';
    echo '</div>';
    
    echo '<div class="info">';
    echo '<h3>What will be kept:</h3>';
    echo '<ul>';
    echo '<li>✅ All real products</li>';
    echo '<li>✅ All real categories (Electronics, Food, etc.)</li>';
    echo '<li>✅ All real customers</li>';
    echo '<li>✅ All real orders</li>';
    echo '<li>✅ Admin user and settings</li>';
    echo '</ul>';
    echo '</div>';
    
    echo '<div class="step">';
    echo '<h3>Ready to clean?</h3>';
    echo '<form method="get">';
    echo '<input type="hidden" name="confirm" value="yes">';
    echo '<button type="submit">🗑️ Yes, Clean Database Now</button>';
    echo '</form>';
    echo '</div>';
}

echo '    </div>
</body>
</html>';
?>
