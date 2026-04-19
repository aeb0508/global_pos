<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    $database = new Database();
    $db = $database->getConnection();

    $db->exec("CREATE TABLE IF NOT EXISTS layaways (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        layaway_number VARCHAR(50) UNIQUE NOT NULL,
        customer_id CHAR(36),
        user_id CHAR(36) NOT NULL,
        total_amount DECIMAL(10,2) NOT NULL,
        deposit_paid DECIMAL(10,2) DEFAULT 0,
        balance_due DECIMAL(10,2) NOT NULL,
        status ENUM('active','completed','cancelled','expired') DEFAULT 'active',
        expiry_date DATE,
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
    )");

    $db->exec("CREATE TABLE IF NOT EXISTS layaway_items (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        layaway_id CHAR(36) NOT NULL,
        product_id CHAR(36) NOT NULL,
        product_name VARCHAR(200) NOT NULL,
        quantity INT NOT NULL,
        unit_price DECIMAL(10,2) NOT NULL,
        total_price DECIMAL(10,2) NOT NULL,
        FOREIGN KEY (layaway_id) REFERENCES layaways(id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products(id)
    )");

    $db->exec("CREATE TABLE IF NOT EXISTS layaway_payments (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        layaway_id CHAR(36) NOT NULL,
        amount DECIMAL(10,2) NOT NULL,
        payment_method ENUM('cash','card') DEFAULT 'cash',
        notes TEXT,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (layaway_id) REFERENCES layaways(id) ON DELETE CASCADE
    )");

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            if (isset($_GET['id'])) {
                $stmt = $db->prepare('SELECT l.*, c.name as customer_name FROM layaways l
                                      LEFT JOIN customers c ON l.customer_id = c.id WHERE l.id = :id');
                $stmt->execute([':id' => $_GET['id']]);
                $layaway = $stmt->fetch(PDO::FETCH_ASSOC);

                $items = $db->prepare('SELECT * FROM layaway_items WHERE layaway_id = :id');
                $items->execute([':id' => $_GET['id']]);
                $layaway['items'] = $items->fetchAll(PDO::FETCH_ASSOC);

                $payments = $db->prepare('SELECT * FROM layaway_payments WHERE layaway_id = :id ORDER BY created_at DESC');
                $payments->execute([':id' => $_GET['id']]);
                $layaway['payments'] = $payments->fetchAll(PDO::FETCH_ASSOC);

                sendJson(['success' => true, 'data' => $layaway]);
            } else {
                $stmt = $db->query('SELECT l.*, c.name as customer_name FROM layaways l
                                    LEFT JOIN customers c ON l.customer_id = c.id
                                    ORDER BY l.created_at DESC');
                sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);
            }
            break;

        case 'POST':
            if (!empty($data['add_payment'])) {
                $db->beginTransaction();
                $db->prepare('INSERT INTO layaway_payments (layaway_id, amount, payment_method, notes)
                              VALUES (:lid, :amount, :method, :notes)')
                   ->execute([':lid' => $data['layaway_id'], ':amount' => $data['amount'],
                              ':method' => $data['payment_method'] ?? 'cash', ':notes' => $data['notes'] ?? '']);
                $db->prepare("UPDATE layaways SET deposit_paid = deposit_paid + :a,
                              balance_due = balance_due - :a2,
                              status = CASE WHEN balance_due - :a3 <= 0 THEN 'completed' ELSE status END
                              WHERE id = :id")
                   ->execute([':a' => $data['amount'], ':a2' => $data['amount'],
                              ':a3' => $data['amount'], ':id' => $data['layaway_id']]);
                $db->commit();
                sendJson(['success' => true, 'message' => 'Payment recorded']);
            } else {
                $db->beginTransaction();
                $layawayNumber = 'LAY-' . date('Ymd') . '-' . rand(1000, 9999);
                $total = $data['total_amount'];
                $deposit = $data['deposit_paid'] ?? 0;
                $balance = $total - $deposit;

                $db->prepare('INSERT INTO layaways (layaway_number, customer_id, user_id, total_amount,
                              deposit_paid, balance_due, expiry_date, notes)
                              VALUES (:ln, :cid, :uid, :total, :deposit, :balance, :expiry, :notes)')
                   ->execute([':ln' => $layawayNumber, ':cid' => $data['customer_id'] ?? null,
                              ':uid' => $data['user_id'] ?? 1, ':total' => $total,
                              ':deposit' => $deposit, ':balance' => $balance,
                              ':expiry' => $data['expiry_date'] ?? null, ':notes' => $data['notes'] ?? '']);
                $layawayId = $db->lastInsertId();

                foreach ($data['items'] as $item) {
                    $db->prepare('INSERT INTO layaway_items (layaway_id, product_id, product_name, quantity, unit_price, total_price)
                                  VALUES (:lid, :pid, :pname, :qty, :uprice, :tprice)')
                       ->execute([':lid' => $layawayId, ':pid' => $item['product_id'],
                                  ':pname' => $item['product_name'], ':qty' => $item['quantity'],
                                  ':uprice' => $item['unit_price'], ':tprice' => $item['total_price']]);
                }

                if ($deposit > 0) {
                    $db->prepare('INSERT INTO layaway_payments (layaway_id, amount, payment_method) VALUES (:lid, :amount, :method)')
                       ->execute([':lid' => $layawayId, ':amount' => $deposit,
                                  ':method' => $data['payment_method'] ?? 'cash']);
                }

                $db->commit();
                sendJson(['success' => true, 'message' => 'Layaway created',
                          'data' => ['id' => $layawayId, 'layaway_number' => $layawayNumber]]);
            }
            break;

        case 'PUT':
            if (isset($_GET['id'])) {
                $db->prepare('UPDATE layaways SET status = :status, notes = :notes WHERE id = :id')
                   ->execute([':status' => $data['status'], ':notes' => $data['notes'] ?? '', ':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Layaway updated']);
            }
            break;

        case 'DELETE':
            if (isset($_GET['id'])) {
                $db->prepare("UPDATE layaways SET status = 'cancelled' WHERE id = :id")
                   ->execute([':id' => $_GET['id']]);
                sendJson(['success' => true, 'message' => 'Layaway cancelled']);
            }
            break;
    }
} catch (Exception $e) {
    if (isset($db) && $db->inTransaction()) $db->rollBack();
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
