<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../models/Product.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();
    $product = new Product($db);

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            AuthMiddleware::checkPermission($currentUser, 'products', 'view');
            if (isset($_GET['id'])) {
                sendJson(['success' => true, 'data' => $product->getById($_GET['id'])]);
            } elseif (isset($_GET['barcode'])) {
                sendJson(['success' => true, 'data' => $product->searchByBarcode($_GET['barcode'])]);
            } elseif (isset($_GET['low_stock'])) {
                sendJson(['success' => true, 'data' => $product->getLowStock()]);
            } else {
                sendJson(['success' => true, 'data' => $product->getAll()]);
            }
            break;

        case 'POST':
            AuthMiddleware::checkPermission($currentUser, 'products', 'create');
            if ($product->create($data)) {
                sendJson(['success' => true, 'message' => 'Product created']);
            } else {
                sendJson(['success' => false, 'message' => 'Failed to create product'], 500);
            }
            break;

        case 'PUT':
            AuthMiddleware::checkPermission($currentUser, 'products', 'edit');
            $id = $_GET['id'] ?? $data['id'] ?? null;
            if ($id) {
                if ($product->update($id, $data)) {
                    sendJson(['success' => true, 'message' => 'Product updated']);
                } else {
                    sendJson(['success' => false, 'message' => 'Failed to update product'], 500);
                }
            } else {
                sendJson(['success' => false, 'message' => 'Product ID required'], 400);
            }
            break;

        case 'DELETE':
            AuthMiddleware::checkPermission($currentUser, 'products', 'delete');
            if (isset($_GET['id'])) {
                if ($product->delete($_GET['id'])) {
                    sendJson(['success' => true, 'message' => 'Product deleted']);
                } else {
                    sendJson(['success' => false, 'message' => 'Failed to delete product'], 500);
                }
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
