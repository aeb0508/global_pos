<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    $database = new Database();
    $db = $database->getConnection();

    $db->exec("CREATE TABLE IF NOT EXISTS currencies (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        code VARCHAR(10) UNIQUE NOT NULL,
        name VARCHAR(100) NOT NULL,
        symbol VARCHAR(10) NOT NULL,
        exchange_rate DECIMAL(15,6) NOT NULL DEFAULT 1.000000,
        is_base BOOLEAN DEFAULT FALSE,
        is_active BOOLEAN DEFAULT TRUE,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    $base = $db->query('SELECT id FROM currencies WHERE is_base = 1 LIMIT 1')->fetch();
    if (!$base) {
        $db->exec("INSERT INTO currencies (code, name, symbol, exchange_rate, is_base) VALUES ('USD','US Dollar','\$',1.000000,1)");
    }

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            $stmt = $db->query('SELECT * FROM currencies ORDER BY is_base DESC, code ASC');
            sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
            break;

        case 'POST':
            $stmt = $db->prepare('INSERT INTO currencies (code, name, symbol, exchange_rate, is_base) VALUES (:code, :name, :symbol, :rate, 0)');
            $stmt->execute([':code' => strtoupper($data['code']), ':name' => $data['name'],
                            ':symbol' => $data['symbol'], ':rate' => $data['exchange_rate']]);
            sendJson(['success' => true, 'message' => 'Currency added']);
            break;

        case 'PUT':
            if (isset($_GET['id'])) {
                if (!empty($data['set_base'])) {
                    $db->exec('UPDATE currencies SET is_base = 0');
                    $db->prepare('UPDATE currencies SET is_base = 1, exchange_rate = 1.000000 WHERE id = :id')
                       ->execute([':id' => $_GET['id']]);
                    sendJson(['success' => true, 'message' => 'Base currency updated']);
                } else {
                    $stmt = $db->prepare('UPDATE currencies SET code=:code, name=:name, symbol=:symbol, exchange_rate=:rate, is_active=:active WHERE id=:id');
                    $stmt->execute([':code' => strtoupper($data['code']), ':name' => $data['name'],
                                    ':symbol' => $data['symbol'], ':rate' => $data['exchange_rate'],
                                    ':active' => $data['is_active'] ?? 1, ':id' => $_GET['id']]);
                    sendJson(['success' => true, 'message' => 'Currency updated']);
                }
            }
            break;

        case 'DELETE':
            if (isset($_GET['id'])) {
                $row = $db->prepare('SELECT is_base FROM currencies WHERE id = :id');
                $row->execute([':id' => $_GET['id']]);
                $c = $row->fetch(PDO::FETCH_ASSOC);
                if ($c && $c['is_base']) sendJson(['success' => false, 'message' => 'Cannot delete base currency']);
                $db->prepare('DELETE FROM currencies WHERE id = :id')->execute([':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Currency deleted']);
            }
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
