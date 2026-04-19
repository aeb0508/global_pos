<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../models/Category.php';

    $database = new Database();
    $db = $database->getConnection();
    $category = new Category($db);

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents("php://input"), true);

    switch ($method) {
        case 'GET':
            sendJson(['success' => true, 'data' => $category->getAll()]);
            break;

        case 'POST':
            if ($category->create($data)) {
                sendJson(['success' => true, 'message' => 'Category created']);
            } else {
                sendJson(['success' => false, 'message' => 'Failed to create category'], 500);
            }
            break;

        case 'PUT':
            if (isset($_GET['id'])) {
                $stmt = $db->prepare("UPDATE categories SET name = :name, description = :desc WHERE id = :id");
                $stmt->execute([':name' => $data['name'], ':desc' => $data['description'] ?? '', ':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Category updated']);
            }
            break;

        case 'DELETE':
            if (isset($_GET['id'])) {
                $stmt = $db->prepare('DELETE FROM categories WHERE id = :id');
                $stmt->bindParam(':id', $_GET['id']);
                $stmt->execute();
                sendJson(['success' => true, 'message' => 'Category deleted']);
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
