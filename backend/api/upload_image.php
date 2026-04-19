<?php
require_once __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/../config/Config.php';

if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
    sendJson(['success' => false, 'message' => 'Method not allowed'], 405);
}

if (!isset($_FILES['image']) || $_FILES['image']['error'] !== UPLOAD_ERR_OK) {
    sendJson(['success' => false, 'message' => 'No image uploaded'], 400);
}

$allowedTypes = explode(',', Config::get('UPLOAD_ALLOWED_TYPES', 'jpg,jpeg,png,gif,webp'));
$allowedMimes = [];
foreach ($allowedTypes as $type) {
    $type = trim($type);
    if ($type === 'jpg' || $type === 'jpeg') $allowedMimes[] = 'image/jpeg';
    elseif ($type === 'png') $allowedMimes[] = 'image/png';
    elseif ($type === 'gif') $allowedMimes[] = 'image/gif';
    elseif ($type === 'webp') $allowedMimes[] = 'image/webp';
}

$mime = mime_content_type($_FILES['image']['tmp_name']);

if (!in_array($mime, $allowedMimes)) {
    sendJson(['success' => false, 'message' => 'Invalid file type. Allowed: ' . implode(', ', $allowedTypes)], 400);
}

$maxSize = Config::getInt('UPLOAD_MAX_SIZE', 5242880); // Default 5MB
if ($_FILES['image']['size'] > $maxSize) {
    $maxMB = round($maxSize / 1048576, 1);
    sendJson(['success' => false, 'message' => "File too large. Max {$maxMB}MB"], 400);
}

$uploadDir = __DIR__ . '/../../' . Config::get('UPLOAD_DIR', 'uploads/products/');
if (!is_dir($uploadDir)) {
    mkdir($uploadDir, 0755, true);
}

$ext      = pathinfo($_FILES['image']['name'], PATHINFO_EXTENSION);
$filename = uniqid('product_', true) . '.' . strtolower($ext);
$dest     = $uploadDir . $filename;

if (!move_uploaded_file($_FILES['image']['tmp_name'], $dest)) {
    sendJson(['success' => false, 'message' => 'Failed to save image'], 500);
}

$baseUrl  = (isset($_SERVER['HTTPS']) ? 'https' : 'http') . '://' . $_SERVER['HTTP_HOST'];
$imageUrl = $baseUrl . '/' . Config::get('UPLOAD_DIR', 'uploads/products/') . $filename;

sendJson(['success' => true, 'url' => $imageUrl]);
