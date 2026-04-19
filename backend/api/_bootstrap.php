<?php
error_reporting(0);
ini_set('display_errors', '0');

header('Content-Type: application/json');
header('Access-Control-Allow-Origin: *');
header('Access-Control-Allow-Methods: GET, POST, PUT, DELETE, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

function sendJson($data, $code = 200) {
    http_response_code($code);
    echo json_encode($data);
    exit();
}

// Load config from .env
if (!defined('DB_HOST')) {
    require_once __DIR__ . '/../config/Config.php';
    define('DB_HOST', Config::get('DB_HOST', 'localhost'));
    define('DB_NAME', Config::get('DB_NAME', 'global_pos'));
    define('DB_USER', Config::get('DB_USER', 'root'));
    define('DB_PASS', Config::get('DB_PASSWORD', ''));
    define('JWT_SECRET', Config::get('JWT_SECRET_KEY', '0699c6ddeaec48d82dfae8a2fb3111d74f3d99cca887a7ab837b3c3a628cdb6a'));
}
