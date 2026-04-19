<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../models/Order.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();
    $order = new Order($db);

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    switch ($method) {
        case 'GET':
            AuthMiddleware::checkPermission($currentUser, 'orders', 'view');
            if (isset($_GET['id'])) {
                sendJson(['success' => true, 'data' => $order->getById($_GET['id'])]);
            } elseif (isset($_GET['dashboard'])) {
                $period = $_GET['period'] ?? 'today';
                sendJson(['success' => true, 'data' => $order->getDashboardStats($period)]);
            } else {
                sendJson(['success' => true, 'data' => $order->getAll()]);
            }
            break;

        case 'POST':
            AuthMiddleware::checkPermission($currentUser, 'orders', 'create');

            $data['user_id'] = $currentUser['id'];
            // Use user's store, fall back to main store if not assigned
            if (isset($currentUser['store_id']) && $currentUser['store_id']) {
                $data['store_id'] = $currentUser['store_id'];
            } else {
                $stmt = $db->prepare("SELECT id FROM stores WHERE is_main = 1 LIMIT 1");
                $stmt->execute();
                $mainStore = $stmt->fetch(PDO::FETCH_ASSOC);
                $data['store_id'] = $mainStore ? $mainStore['id'] : null;
            }
            $data['customer_id'] = isset($data['customer_id']) && $data['customer_id'] !== '' && $data['customer_id'] !== null ? $data['customer_id'] : null;
            $data['subtotal'] = (float)($data['subtotal'] ?? 0);
            $data['discount'] = (float)($data['discount'] ?? 0);
            $data['tax'] = (float)($data['tax'] ?? 0);
            $data['total'] = (float)($data['total'] ?? 0);

            if (isset($data['items'])) {
                foreach ($data['items'] as &$item) {
                    $item['quantity'] = (int)$item['quantity'];
                    $item['unit_price'] = (float)$item['unit_price'];
                    $item['total_price'] = (float)$item['total_price'];
                }
            }

            $splitPayments = $data['payments'] ?? null;
            unset($data['payments']);

            $result = $order->create($data);

            if ($result['success'] && $splitPayments) {
                $orderId = $result['data']['id'];
                $db->prepare('DELETE FROM payments WHERE order_id = :oid')->execute([':oid' => $orderId]);
                $stmt = $db->prepare('INSERT INTO payments (order_id, payment_method, amount) VALUES (:oid, :method, :amount)');
                foreach ($splitPayments as $payment) {
                    $stmt->execute([':oid' => $orderId, ':method' => $payment['method'], ':amount' => $payment['amount']]);
                }
            }

            if ($result['success']) {
                require_once __DIR__ . '/../utils/NotificationHelper.php';
                $orderId     = $result['data']['id'];
                $orderNumber = $result['data']['order_number'];
                sendEmailReceiptIfEnabled($db, $data, $orderId, $orderNumber);
                if (!empty($data['items'])) {
                    foreach ($data['items'] as $item) {
                        sendLowStockAlertIfEnabled($db, $item['product_id']);
                    }
                }
            }

            sendJson($result, $result['success'] ? 200 : 500);
            break;

        case 'PUT':
            AuthMiddleware::checkPermission($currentUser, 'orders', 'edit');
            if (!isset($_GET['id'])) {
                sendJson(['success' => false, 'message' => 'Order ID required'], 400);
            }
            if (isset($data['customer_id'])) {
                $data['customer_id'] = ($data['customer_id'] !== '' && $data['customer_id'] !== null) ? $data['customer_id'] : null;
            }
            $result = $order->update($_GET['id'], $data);
            sendJson($result, $result['success'] ? 200 : 500);
            break;

        case 'DELETE':
            AuthMiddleware::checkPermission($currentUser, 'orders', 'delete');
            if (!isset($_GET['id'])) {
                sendJson(['success' => false, 'message' => 'Order ID required'], 400);
            }
            $result = $order->delete($_GET['id']);
            sendJson($result, $result['success'] ? 200 : 500);
            break;
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
