<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../models/User.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();
    $user = new User($db);

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            AuthMiddleware::checkPermission($currentUser, 'users', 'view');
            if (isset($_GET['id'])) {
                sendJson(['success' => true, 'data' => $user->getById($_GET['id'])]);
            } else {
                sendJson(['success' => true, 'data' => $user->getAll()]);
            }
            break;

        case 'POST':
            AuthMiddleware::checkPermission($currentUser, 'users', 'create');
            if ($user->create($data)) {
                sendJson(['success' => true, 'message' => 'User created successfully']);
            } else {
                sendJson(['success' => false, 'message' => 'Failed to create user'], 500);
            }
            break;

        case 'PUT':
            AuthMiddleware::checkPermission($currentUser, 'users', 'edit');
            if (isset($_GET['id'])) {
                if ($user->update($_GET['id'], $data)) {
                    sendJson(['success' => true, 'message' => 'User updated successfully']);
                } else {
                    sendJson(['success' => false, 'message' => 'Failed to update user'], 500);
                }
            }
            break;

        case 'DELETE':
            AuthMiddleware::checkPermission($currentUser, 'users', 'delete');
            if (isset($_GET['id'])) {
                if ($_GET['id'] == $currentUser['id']) {
                    sendJson(['success' => false, 'message' => 'Cannot delete your own account'], 400);
                }
                if ($user->delete($_GET['id'])) {
                    sendJson(['success' => true, 'message' => 'User deleted successfully']);
                } else {
                    sendJson(['success' => false, 'message' => 'Failed to delete user'], 500);
                }
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
