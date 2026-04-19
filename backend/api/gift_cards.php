<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    $database = new Database();
    $db = $database->getConnection();

    $db->exec("CREATE TABLE IF NOT EXISTS gift_cards (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        card_number VARCHAR(50) UNIQUE NOT NULL,
        initial_balance DECIMAL(10,2) NOT NULL,
        current_balance DECIMAL(10,2) NOT NULL,
        status ENUM('active','used','expired') DEFAULT 'active',
        issued_by CHAR(36) NOT NULL,
        expiry_date DATE,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET') {
        if (isset($_GET['card_number'])) {
            $stmt = $db->prepare('SELECT * FROM gift_cards WHERE card_number = :cn');
            $stmt->execute([':cn' => $_GET['card_number']]);
            sendJson(['success' => true, 'data' => $stmt->fetch(PDO::FETCH_ASSOC)]);
        } else {
            $stmt = $db->query('SELECT * FROM gift_cards ORDER BY created_at DESC');
            sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
        }
    } elseif ($method === 'POST') {
        if (!empty($data['redeem'])) {
            $stmt = $db->prepare("SELECT * FROM gift_cards WHERE card_number = :cn AND status = 'active'");
            $stmt->execute([':cn' => $data['card_number']]);
            $card = $stmt->fetch(PDO::FETCH_ASSOC);
            if (!$card) sendJson(['success' => false, 'message' => 'Invalid or inactive gift card']);

            $amount = min(floatval($data['amount']), floatval($card['current_balance']));
            $newBalance = floatval($card['current_balance']) - $amount;
            $newStatus = $newBalance <= 0 ? 'used' : 'active';

            $db->prepare('UPDATE gift_cards SET current_balance = :bal, status = :status WHERE id = :id')
               ->execute([':bal' => $newBalance, ':status' => $newStatus, ':id' => $card['id']]);
            sendJson(['success' => true, 'amount_applied' => $amount, 'remaining_balance' => $newBalance]);
        } else {
            $cardNumber = 'GC-' . strtoupper(substr(md5(uniqid()), 0, 10));
            $db->prepare('INSERT INTO gift_cards (card_number, initial_balance, current_balance, issued_by, expiry_date)
                          VALUES (:cn, :ib, :cb, :ib_by, :exp)')
               ->execute([':cn' => $cardNumber, ':ib' => $data['initial_balance'],
                          ':cb' => $data['initial_balance'], ':ib_by' => $data['issued_by'] ?? 1,
                          ':exp' => $data['expiry_date'] ?? null]);
            sendJson(['success' => true, 'message' => 'Gift card issued', 'card_number' => $cardNumber]);
        }
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
