<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET') {
        // Get loyalty program settings
        $query = "SELECT * FROM loyalty_program LIMIT 1";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $program = $stmt->fetch(PDO::FETCH_ASSOC);
        
        if (!$program) {
            // Create default program
            $insertQuery = "INSERT INTO loyalty_program (name, description, points_per_dollar, points_for_reward, reward_value) 
                           VALUES ('Standard Loyalty', 'Earn points on every purchase', 10, 100, 10.00)";
            $db->exec($insertQuery);
            $stmt->execute();
            $program = $stmt->fetch(PDO::FETCH_ASSOC);
        }
        
        sendJson(['success' => true, 'data' => $program]);
    } elseif ($method === 'POST' || $method === 'PUT') {
        // Update loyalty program
        $query = "UPDATE loyalty_program SET 
                  points_per_dollar = :points_per_dollar,
                  points_for_reward = :points_for_reward,
                  reward_value = :reward_value
                  WHERE id = 1";
        
        $stmt = $db->prepare($query);
        $stmt->bindParam(':points_per_dollar', $data['points_per_dollar']);
        $stmt->bindParam(':points_for_reward', $data['points_for_reward']);
        $stmt->bindParam(':reward_value', $data['reward_value']);
        
        if ($stmt->execute()) {
            sendJson(['success' => true, 'message' => 'Program updated successfully']);
        } else {
            sendJson(['success' => false, 'message' => 'Failed to update program'], 500);
        }
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
