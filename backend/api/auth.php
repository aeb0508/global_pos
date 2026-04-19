<?php
ob_start();
error_reporting(0);
ini_set('display_errors', '0');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    ob_end_clean();
    http_response_code(200);
    exit();
}

function sendJson($data, $code = 200) {
    ob_end_clean();
    http_response_code($code);
    echo json_encode($data);
    exit();
}

function jwtEncode($payload, $secret) {
    $header = base64_encode(json_encode(['typ' => 'JWT', 'alg' => 'HS256']));
    $payload = base64_encode(json_encode($payload));
    $header  = str_replace(['+','/','='], ['-','_',''], $header);
    $payload = str_replace(['+','/','='], ['-','_',''], $payload);
    $sig = hash_hmac('sha256', "$header.$payload", $secret, true);
    $sig = str_replace(['+','/','='], ['-','_',''], base64_encode($sig));
    return "$header.$payload.$sig";
}

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJson(['success' => false, 'message' => 'Method not allowed'], 405);
}

$data = json_decode(file_get_contents('php://input'), true);

if (empty($data['username']) || empty($data['password'])) {
    sendJson(['success' => false, 'message' => 'Username and password required'], 400);
}

try {
    require_once __DIR__ . '/../config/Config.php';
    $pdo = new PDO(
        'mysql:host=' . Config::get('DB_HOST', 'localhost') . ';dbname=' . Config::get('DB_NAME', 'global_pos') . ';charset=utf8',
        Config::get('DB_USER', 'root'),
        Config::get('DB_PASSWORD', ''),
        [PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION]
    );

    $stmt = $pdo->prepare("SELECT * FROM users WHERE username = ? AND is_active = 1 LIMIT 1");
    $stmt->execute([$data['username']]);
    $user = $stmt->fetch(PDO::FETCH_ASSOC);

    if (!$user || !password_verify($data['password'], $user['password'])) {
        sendJson(['success' => false, 'message' => 'Invalid credentials'], 401);
    }

    $secret = '0699c6ddeaec48d82dfae8a2fb3111d74f3d99cca887a7ab837b3c3a628cdb6a';
    $token = jwtEncode([
        'id'       => $user['id'],
        'username' => $user['username'],
        'role'     => $user['role'],
        'exp'      => time() + 86400,
    ], $secret);

    unset($user['password']);
    sendJson(['success' => true, 'token' => $token, 'user' => $user]);

} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
