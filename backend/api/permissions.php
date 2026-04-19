<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    
    $database = new Database();
    $db = $database->getConnection();

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET') {
        if (isset($_GET['role'])) {
            $stmt = $db->prepare('SELECT * FROM permissions WHERE role = :role ORDER BY feature');
            $stmt->execute([':role' => $_GET['role']]);
            sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        } else {
            $stmt = $db->query('SELECT * FROM permissions ORDER BY role, feature');
            sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        }
    } elseif ($method === 'PUT') {
        try {
            $v = $data['can_view'] ? 1 : 0;
            $c = $data['can_create'] ? 1 : 0;
            $e = $data['can_edit'] ? 1 : 0;
            $d = $data['can_delete'] ? 1 : 0;
            
            // Check if record exists
            $checkStmt = $db->prepare('SELECT id FROM permissions WHERE role = :role AND feature = :feature');
            $checkStmt->execute([':role' => $data['role'], ':feature' => $data['feature']]);
            $exists = $checkStmt->fetch(PDO::FETCH_ASSOC);
            
            if ($exists) {
                // Update existing record
                $stmt = $db->prepare('UPDATE permissions SET can_view=:view, can_create=:create, can_edit=:edit, can_delete=:delete, updated_at=CURRENT_TIMESTAMP WHERE role=:role AND feature=:feature');
                $stmt->execute([':role'=>$data['role'], ':feature'=>$data['feature'], ':view'=>$v, ':create'=>$c, ':edit'=>$e, ':delete'=>$d]);
            } else {
                // Insert new record with UUID
                $stmt = $db->prepare('INSERT INTO permissions (id, role, feature, can_view, can_create, can_edit, can_delete) VALUES (UUID(), :role, :feature, :view, :create, :edit, :delete)');
                $stmt->execute([':role'=>$data['role'], ':feature'=>$data['feature'], ':view'=>$v, ':create'=>$c, ':edit'=>$e, ':delete'=>$d]);
            }
            
            sendJson(['success' => true, 'message' => 'Permission updated', 'data' => $data]);
        } catch (PDOException $e) {
            sendJson(['success' => false, 'message' => 'Database error: ' . $e->getMessage()], 500);
        }
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
