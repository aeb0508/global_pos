<?php
error_reporting(E_ALL);
ini_set('display_errors', '1');
header('Content-Type: application/json');

// Test 1: Basic PHP
$result = ['php' => 'ok'];

// Test 2: DB connection
try {
    require_once __DIR__ . '/../config/Config.php';
    $pdo = new PDO(
        'mysql:host=' . Config::get('DB_HOST', 'localhost') . ';dbname=' . Config::get('DB_NAME', 'global_pos'),
        Config::get('DB_USER', 'root'),
        Config::get('DB_PASSWORD', '')
    );
    $pdo->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $result['db'] = 'connected';

    // Test 3: Query users
    $stmt = $pdo->query("SELECT id, username, role FROM users LIMIT 1");
    $user = $stmt->fetch(PDO::FETCH_ASSOC);
    $result['user_found'] = $user ? $user['username'] : 'none';
} catch (Exception $e) {
    $result['db_error'] = $e->getMessage();
}

echo json_encode($result);
