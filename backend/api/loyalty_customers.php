<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET') {
        // Get all loyalty customers
        $query = "SELECT lc.*, c.name, c.email, c.phone 
                  FROM loyalty_customers lc
                  JOIN customers c ON lc.customer_id = c.id
                  ORDER BY lc.points DESC";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $customers = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        sendJson(['success' => true, 'data' => $customers]);
    } elseif ($method === 'POST') {
        // Add or update points
        $customerId = $data['customer_id'];
        $points = $data['points'];
        $action = $data['action'] ?? 'add';
        
        // Check if customer exists in loyalty program
        $checkQuery = "SELECT * FROM loyalty_customers WHERE customer_id = :customer_id";
        $checkStmt = $db->prepare($checkQuery);
        $checkStmt->bindParam(':customer_id', $customerId);
        $checkStmt->execute();
        $existing = $checkStmt->fetch(PDO::FETCH_ASSOC);
        
        if ($existing) {
            // Update points
            $newPoints = $action === 'add' ? $existing['points'] + $points : $existing['points'] - $points;
            $newPoints = max(0, $newPoints); // Don't go negative
            
            // Determine tier
            $tier = 'bronze';
            if ($newPoints >= 2000) $tier = 'platinum';
            elseif ($newPoints >= 1000) $tier = 'gold';
            elseif ($newPoints >= 500) $tier = 'silver';
            
            $updateQuery = "UPDATE loyalty_customers SET points = :points, tier = :tier WHERE customer_id = :customer_id";
            $updateStmt = $db->prepare($updateQuery);
            $updateStmt->bindParam(':points', $newPoints);
            $updateStmt->bindParam(':tier', $tier);
            $updateStmt->bindParam(':customer_id', $customerId);
            $updateStmt->execute();
        } else {
            // Create new loyalty customer
            $tier = 'bronze';
            $insertQuery = "INSERT INTO loyalty_customers (customer_id, points, tier) VALUES (:customer_id, :points, :tier)";
            $insertStmt = $db->prepare($insertQuery);
            $insertStmt->bindParam(':customer_id', $customerId);
            $insertStmt->bindParam(':points', $points);
            $insertStmt->bindParam(':tier', $tier);
            $insertStmt->execute();
        }
        
        sendJson(['success' => true, 'message' => 'Points updated successfully']);
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
