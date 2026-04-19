<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';

    $database = new Database();
    $db = $database->getConnection();

    // Create table if not exists
    $db->exec("CREATE TABLE IF NOT EXISTS tax_rates (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        name VARCHAR(100) NOT NULL,
        rate DECIMAL(5,2) NOT NULL,
        description TEXT,
        is_default TINYINT(1) DEFAULT 0,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                $stmt = $db->prepare('SELECT * FROM tax_rates WHERE id = :id');
                $stmt->execute([':id' => $_GET['id']]);
                sendJson(['success' => true, 'data' => $stmt->fetch(PDO::FETCH_ASSOC)]);
            } else {
                $stmt = $db->prepare('SELECT * FROM tax_rates ORDER BY is_default DESC, name ASC');
                $stmt->execute();
                sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
            }
            break;

        case 'POST':
            if (!empty($data['is_default'])) $db->exec('UPDATE tax_rates SET is_default = 0');
            $stmt = $db->prepare('INSERT INTO tax_rates (name, rate, description, is_default) VALUES (:name, :rate, :desc, :def)');
            $stmt->execute([':name' => $data['name'], ':rate' => $data['rate'],
                            ':desc' => $data['description'] ?? '', ':def' => $data['is_default'] ?? 0]);
            sendJson(['success' => true, 'message' => 'Tax rate created successfully']);
            break;

        case 'PUT':
            if (isset($_GET['id'])) {
                if (!empty($data['is_default'])) $db->exec('UPDATE tax_rates SET is_default = 0');
                $stmt = $db->prepare('UPDATE tax_rates SET name=:name, rate=:rate, description=:desc, is_default=:def WHERE id=:id');
                $stmt->execute([':name' => $data['name'], ':rate' => $data['rate'],
                                ':desc' => $data['description'] ?? '', ':def' => $data['is_default'] ?? 0,
                                ':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Tax rate updated successfully']);
            }
            break;

        case 'DELETE':
            if (isset($_GET['id'])) {
                $db->prepare('DELETE FROM tax_rates WHERE id = :id')->execute([':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Tax rate deleted successfully']);
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
