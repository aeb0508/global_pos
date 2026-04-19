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

    if ($method === 'GET') {
        AuthMiddleware::checkPermission($currentUser, 'audit', 'view');
        $type      = $_GET['type']       ?? 'all';
        $startDate = $_GET['start_date'] ?? date('Y-m-d', strtotime('-7 days'));
        $endDate   = $_GET['end_date']   ?? date('Y-m-d');

        $query = "SELECT al.*, u.full_name as user_name 
                  FROM audit_logs al 
                  LEFT JOIN users u ON al.user_id = u.id 
                  WHERE DATE(al.created_at) BETWEEN :start_date AND :end_date";

        if ($type !== 'all') {
            $query .= " AND al.action = :type";
        }

        $query .= " ORDER BY al.created_at DESC LIMIT 500";

        $stmt = $db->prepare($query);
        $stmt->bindParam(':start_date', $startDate);
        $stmt->bindParam(':end_date', $endDate);
        if ($type !== 'all') {
            $stmt->bindParam(':type', $type);
        }

        $stmt->execute();
        sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
    } elseif ($method === 'POST') {
        $data = json_decode(file_get_contents("php://input"), true);

        $query = "INSERT INTO audit_logs (user_id, action, entity_type, entity_id, description, ip_address) 
                  VALUES (:user_id, :action, :entity_type, :entity_id, :description, :ip_address)";

        $stmt = $db->prepare($query);
        $stmt->bindParam(':user_id',     $data['user_id']);
        $stmt->bindParam(':action',      $data['action']);
        $stmt->bindParam(':entity_type', $data['entity_type']);
        $stmt->bindParam(':entity_id',   $data['entity_id']);
        $stmt->bindParam(':description', $data['description']);
        $ipAddress = $_SERVER['REMOTE_ADDR'];
        $stmt->bindParam(':ip_address',  $ipAddress);

        if ($stmt->execute()) {
            sendJson(['success' => true, 'message' => 'Audit log created']);
        } else {
            sendJson(['success' => false, 'message' => 'Failed to create audit log'], 500);
        }
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
