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
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            AuthMiddleware::checkPermission($currentUser, 'suppliers', 'view');
            if (isset($_GET['id'])) {
                $stmt = $db->prepare('SELECT * FROM suppliers WHERE id = :id');
                $stmt->execute([':id' => $_GET['id']]);
                sendJson(['success' => true, 'data' => $stmt->fetch(PDO::FETCH_ASSOC)]);
            } elseif (isset($_GET['products'])) {
                $stmt = $db->prepare('SELECT p.id, p.name, p.selling_price, p.stock_quantity, p.low_stock_threshold FROM products p WHERE p.supplier_id = :id AND p.is_active = 1 ORDER BY p.name ASC');
                $stmt->execute([':id' => $_GET['products']]);
                sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
            } else {
                $stmt = $db->prepare('SELECT s.*, (SELECT COUNT(*) FROM products p WHERE p.supplier_id = s.id AND p.is_active = 1) as product_count FROM suppliers s WHERE s.is_active = 1 ORDER BY s.name ASC');
                $stmt->execute();
                sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
            }
            break;

        case 'POST':
            AuthMiddleware::checkPermission($currentUser, 'suppliers', 'create');
            $stmt = $db->prepare('INSERT INTO suppliers (name, email, phone, address, contact_person)
                                  VALUES (:name, :email, :phone, :address, :cp)');
            $stmt->execute([':name' => $data['name'], ':email' => $data['email'] ?? '',
                            ':phone' => $data['phone'] ?? '', ':address' => $data['address'] ?? '',
                            ':cp' => $data['contact_person'] ?? '']);
            sendJson(['success' => true, 'message' => 'Supplier created successfully']);
            break;

        case 'PUT':
            AuthMiddleware::checkPermission($currentUser, 'suppliers', 'edit');
            if (isset($_GET['id'])) {
                $stmt = $db->prepare('UPDATE suppliers SET name=:name, email=:email, phone=:phone,
                                      address=:address, contact_person=:cp WHERE id=:id');
                $stmt->execute([':name' => $data['name'], ':email' => $data['email'] ?? '',
                                ':phone' => $data['phone'] ?? '', ':address' => $data['address'] ?? '',
                                ':cp' => $data['contact_person'] ?? '', ':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Supplier updated successfully']);
            }
            break;

        case 'DELETE':
            AuthMiddleware::checkPermission($currentUser, 'suppliers', 'delete');
            if (isset($_GET['id'])) {
                $db->prepare('UPDATE suppliers SET is_active = 0 WHERE id = :id')
                   ->execute([':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Supplier deleted successfully']);
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
