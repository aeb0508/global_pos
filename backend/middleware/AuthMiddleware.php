<?php

class AuthMiddleware {
    
    public static function authenticate() {
        $authHeader = null;

        // Method 1: getallheaders()
        if (function_exists('getallheaders')) {
            $headers = getallheaders();
            foreach ($headers as $k => $v) {
                if (strtolower($k) === 'authorization') {
                    $authHeader = $v;
                    break;
                }
            }
        }

        // Method 2: $_SERVER variants
        if (!$authHeader) $authHeader = $_SERVER['HTTP_AUTHORIZATION'] ?? null;
        if (!$authHeader) $authHeader = $_SERVER['REDIRECT_HTTP_AUTHORIZATION'] ?? null;

        // Method 3: token in query string (InfinityFree workaround)
        if (!$authHeader && !empty($_GET['token'])) {
            $authHeader = 'Bearer ' . $_GET['token'];
        }

        // Method 4: token in POST body
        if (!$authHeader) {
            $body = json_decode(file_get_contents('php://input'), true);
            if (!empty($body['token'])) {
                $authHeader = 'Bearer ' . $body['token'];
            }
        }

        if (!$authHeader) {
            http_response_code(401);
            echo json_encode(['success' => false, 'message' => 'No token provided']);
            exit();
        }

        $arr = explode(" ", $authHeader);
        $jwt = isset($arr[1]) ? $arr[1] : null;

        if ($jwt) {
            $decoded = JWT::decode($jwt);
            if ($decoded) {
                return $decoded;
            }
        }

        http_response_code(401);
        echo json_encode(['success' => false, 'message' => 'Invalid token']);
        exit();
    }

    public static function checkRole($user, $allowedRoles) {
        if (!in_array($user['role'], $allowedRoles)) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Access denied']);
            exit();
        }
    }

    public static function checkPermission($user, $feature, $action) {
        // Admin always has full access
        if ($user['role'] === 'admin') {
            return true;
        }

        require_once __DIR__ . '/../config/Database.php';
        $database = new Database();
        $db = $database->getConnection();

        $actionColumn = 'can_' . $action; // can_view, can_create, can_edit, can_delete
        $stmt = $db->prepare("SELECT $actionColumn FROM permissions WHERE role = :role AND feature = :feature");
        $stmt->execute([':role' => $user['role'], ':feature' => $feature]);
        $result = $stmt->fetch(PDO::FETCH_ASSOC);

        if (!$result || !$result[$actionColumn]) {
            http_response_code(403);
            echo json_encode(['success' => false, 'message' => 'Permission denied: You do not have ' . $action . ' access to ' . $feature]);
            exit();
        }

        return true;
    }
}
