<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();
    $changedBy = $currentUser['id'];



    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET' && isset($_GET['history'])) {
        $stmt = $db->prepare('SELECT ph.*, p.name as product_name, u.full_name as changed_by_name
                              FROM price_history ph
                              LEFT JOIN products p ON ph.product_id = p.id
                              LEFT JOIN users u ON ph.changed_by = u.id
                              ORDER BY ph.created_at DESC LIMIT 100');
        $stmt->execute();
        sendJson(['success' => true, 'data' => $stmt->fetchAll(PDO::FETCH_ASSOC)]);

    } elseif ($method === 'POST') {
        if (!empty($data['bulk_update'])) {
            $pct = floatval($data['percentage']);
            $products = $db->query('SELECT id, selling_price FROM products WHERE is_active = 1')->fetchAll(PDO::FETCH_ASSOC);

            $db->beginTransaction();
            foreach ($products as $product) {
                $oldPrice = floatval($product['selling_price']);
                $newPrice = round($oldPrice * (1 + $pct / 100), 2);
                if ($newPrice <= 0) continue;
                $phId = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                    mt_rand(0,0xffff), mt_rand(0,0xffff), mt_rand(0,0xffff),
                    mt_rand(0,0x0fff)|0x4000, mt_rand(0,0x3fff)|0x8000,
                    mt_rand(0,0xffff), mt_rand(0,0xffff), mt_rand(0,0xffff));
                $db->prepare('UPDATE products SET selling_price = :np WHERE id = :id')
                   ->execute([':np' => $newPrice, ':id' => $product['id']]);
                $db->prepare('INSERT INTO price_history (id, product_id, old_price, new_price, changed_by, reason)
                              VALUES (:id, :pid, :op, :np, :cb, :reason)')
                   ->execute([':id' => $phId, ':pid' => $product['id'], ':op' => $oldPrice,
                              ':np' => $newPrice, ':cb' => $changedBy, ':reason' => "Bulk update {$pct}%"]);
            }
            $db->commit();
            sendJson(['success' => true, 'message' => 'Bulk price update completed']);
        } else {
            $phId = sprintf('%04x%04x-%04x-%04x-%04x-%04x%04x%04x',
                mt_rand(0,0xffff), mt_rand(0,0xffff), mt_rand(0,0xffff),
                mt_rand(0,0x0fff)|0x4000, mt_rand(0,0x3fff)|0x8000,
                mt_rand(0,0xffff), mt_rand(0,0xffff), mt_rand(0,0xffff));
            $db->prepare('UPDATE products SET selling_price = :np WHERE id = :id')
               ->execute([':np' => $data['new_price'], ':id' => $data['product_id']]);
            $db->prepare('INSERT INTO price_history (id, product_id, old_price, new_price, changed_by)
                          VALUES (:id, :pid, :op, :np, :cb)')
               ->execute([':id' => $phId, ':pid' => $data['product_id'], ':op' => $data['old_price'],
                          ':np' => $data['new_price'], ':cb' => $changedBy]);
            sendJson(['success' => true, 'message' => 'Price updated']);
        }
    }
} catch (Exception $e) {
    if (isset($db) && $db->inTransaction()) $db->rollBack();
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
