<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../models/Customer.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();
    $customer = new Customer($db);

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents("php://input"), true);

    switch ($method) {
        case 'GET':
            AuthMiddleware::checkPermission($currentUser, 'customers', 'view');
            if (isset($_GET['id']) && isset($_GET['history'])) {
                sendJson(['success' => true, 'data' => $customer->getPurchaseHistory($_GET['id'])]);
            } elseif (isset($_GET['id'])) {
                $stmt = $db->prepare('SELECT * FROM customers WHERE id = :id');
                $stmt->bindParam(':id', $_GET['id']);
                $stmt->execute();
                sendJson(['success' => true, 'data' => $stmt->fetch(PDO::FETCH_ASSOC)]);
            } else {
                sendJson(['success' => true, 'data' => $customer->getAll()]);
            }
            break;

        case 'POST':
            AuthMiddleware::checkPermission($currentUser, 'customers', 'create');
            $newId = $customer->create($data);
            if ($newId) {
                $stmt = $db->prepare('SELECT * FROM customers WHERE id = :id');
                $stmt->bindParam(':id', $newId);
                $stmt->execute();
                $newCustomer = $stmt->fetch(PDO::FETCH_ASSOC);
                sendJson(['success' => true, 'message' => 'Customer created', 'data' => $newCustomer]);
            } else {
                sendJson(['success' => false, 'message' => 'Failed to create customer'], 500);
            }
            break;

        case 'PUT':
            AuthMiddleware::checkPermission($currentUser, 'customers', 'edit');
            if (isset($_GET['id']) || isset($data['id'])) {
                $customerId = $_GET['id'] ?? $data['id'];
                $fields = [];
                $params = [':id' => $customerId];
                foreach (['name', 'email', 'phone', 'address'] as $f) {
                    if (isset($data[$f])) { $fields[] = "$f = :$f"; $params[":$f"] = $data[$f]; }
                }
                if ($fields) {
                    $db->prepare('UPDATE customers SET ' . implode(', ', $fields) . ' WHERE id = :id')->execute($params);
                    // Get the updated customer
                    $stmt = $db->prepare('SELECT * FROM customers WHERE id = :id');
                    $stmt->bindParam(':id', $customerId);
                    $stmt->execute();
                    $updatedCustomer = $stmt->fetch(PDO::FETCH_ASSOC);
                    sendJson(['success' => true, 'message' => 'Customer updated', 'data' => $updatedCustomer]);
                }
            }
            break;

        case 'DELETE':
            AuthMiddleware::checkPermission($currentUser, 'customers', 'delete');
            if (isset($_GET['id'])) {
                $stmt = $db->prepare('DELETE FROM customers WHERE id = :id');
                $stmt->bindParam(':id', $_GET['id']);
                $stmt->execute();
                sendJson(['success' => true, 'message' => 'Customer deleted']);
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
