<?php

require_once __DIR__ . '/../config/Config.php';
require_once __DIR__ . '/../utils/UUID.php';

class Order {
    private $conn;
    private $table = 'orders';

    public function __construct($db) {
        $this->conn = $db;
    }

    public function create($data) {
        try {
            $this->conn->beginTransaction();

            $orderId = UUID::generate();
            $prefix = Config::get('ORDER_NUMBER_PREFIX', 'ORD');
            $orderNumber = $prefix . '-' . date('Ymd') . '-' . rand(1000, 9999);
            
            // Ensure proper types
            $userId = $data['user_id'] ?? null;
            $storeId = isset($data['store_id']) && $data['store_id'] ? $data['store_id'] : null;
            $customerId = (isset($data['customer_id']) && $data['customer_id'] !== null && $data['customer_id'] !== '') ? $data['customer_id'] : null;
            $subtotal = (float)($data['subtotal'] ?? 0);
            $discount = (float)($data['discount'] ?? 0);
            $tax = (float)($data['tax'] ?? 0);
            $total = (float)($data['total'] ?? 0);
            $status = $data['status'] ?? 'completed';
            
            $query = "INSERT INTO " . $this->table . " (id, order_number, customer_id, user_id, store_id, subtotal, discount, tax, total, status) VALUES (:id, :order_number, :customer_id, :user_id, :store_id, :subtotal, :discount, :tax, :total, :status)";
            $stmt = $this->conn->prepare($query);
            
            $stmt->bindValue(':id', $orderId, PDO::PARAM_STR);
            $stmt->bindValue(':order_number', $orderNumber, PDO::PARAM_STR);
            $stmt->bindValue(':customer_id', $customerId, $customerId === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
            $stmt->bindValue(':user_id', $userId, $userId === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
            $stmt->bindValue(':store_id', $storeId, $storeId === null ? PDO::PARAM_NULL : PDO::PARAM_STR);
            $stmt->bindValue(':subtotal', $subtotal);
            $stmt->bindValue(':discount', $discount);
            $stmt->bindValue(':tax', $tax);
            $stmt->bindValue(':total', $total);
            $stmt->bindValue(':status', $status, PDO::PARAM_STR);
            
            $stmt->execute();

            foreach ($data['items'] as $item) {
                $itemId = UUID::generate();
                $itemQuery = "INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, total_price) VALUES (:id, :order_id, :product_id, :product_name, :quantity, :unit_price, :total_price)";
                $itemStmt = $this->conn->prepare($itemQuery);
                
                $productId = $item['product_id'];
                $quantity = (int)$item['quantity'];
                $unitPrice = (float)$item['unit_price'];
                $totalPrice = (float)$item['total_price'];
                
                $itemStmt->bindValue(':id', $itemId, PDO::PARAM_STR);
                $itemStmt->bindValue(':order_id', $orderId, PDO::PARAM_STR);
                $itemStmt->bindValue(':product_id', $productId, PDO::PARAM_STR);
                $itemStmt->bindValue(':product_name', $item['product_name'], PDO::PARAM_STR);
                $itemStmt->bindValue(':quantity', $quantity, PDO::PARAM_INT);
                $itemStmt->bindValue(':unit_price', $unitPrice);
                $itemStmt->bindValue(':total_price', $totalPrice);
                $itemStmt->execute();

                // Only deduct stock for completed orders
                if ($status === 'completed') {
                    $stockQuery = "UPDATE products SET stock_quantity = stock_quantity - :quantity WHERE id = :product_id";
                    $stockStmt = $this->conn->prepare($stockQuery);
                    $stockStmt->bindValue(':quantity', $quantity, PDO::PARAM_INT);
                    $stockStmt->bindValue(':product_id', $productId, PDO::PARAM_STR);
                    $result = $stockStmt->execute();
                    if (!$result) {
                        throw new Exception('Failed to update stock for product ' . $productId);
                    }

                    $logId = UUID::generate();
                    $logQuery = "INSERT INTO inventory_logs (id, product_id, user_id, type, quantity_change) VALUES (:id, :product_id, :user_id, 'sale', :quantity)";
                    $logStmt = $this->conn->prepare($logQuery);
                    $logStmt->bindValue(':id', $logId, PDO::PARAM_STR);
                    $logStmt->bindValue(':product_id', $productId, PDO::PARAM_STR);
                    $logStmt->bindValue(':user_id', $userId, PDO::PARAM_STR);
                    $negQuantity = -$quantity;
                    $logStmt->bindValue(':quantity', $negQuantity, PDO::PARAM_INT);
                    $logStmt->execute();
                }
            }

            $paymentId = UUID::generate();
            $paymentQuery = "INSERT INTO payments (id, order_id, payment_method, amount) VALUES (:id, :order_id, :payment_method, :amount)";
            $paymentStmt = $this->conn->prepare($paymentQuery);
            $paymentStmt->bindValue(':id', $paymentId, PDO::PARAM_STR);
            $paymentStmt->bindValue(':order_id', $orderId, PDO::PARAM_STR);
            $paymentStmt->bindValue(':payment_method', $data['payment_method'], PDO::PARAM_STR);
            $paymentStmt->bindValue(':amount', $total);
            $paymentStmt->execute();

            $this->conn->commit();
            return ['success' => true, 'data' => ['id' => $orderId, 'order_number' => $orderNumber]];
        } catch (Exception $e) {
            $this->conn->rollBack();
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function getAll($limit = 100) {
        $limit = Config::getInt('DEFAULT_ORDER_LIMIT', 100);
        $query = "SELECT o.*, u.full_name as cashier_name, c.name as customer_name FROM " . $this->table . " o LEFT JOIN users u ON o.user_id = u.id LEFT JOIN customers c ON o.customer_id = c.id ORDER BY o.created_at DESC LIMIT :limit";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':limit', $limit, PDO::PARAM_INT);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getById($id) {
        $query = "SELECT o.*, u.full_name as cashier_name, c.name as customer_name FROM " . $this->table . " o LEFT JOIN users u ON o.user_id = u.id LEFT JOIN customers c ON o.customer_id = c.id WHERE o.id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        $order = $stmt->fetch(PDO::FETCH_ASSOC);

        if ($order) {
            $itemsQuery = "SELECT * FROM order_items WHERE order_id = :order_id";
            $itemsStmt = $this->conn->prepare($itemsQuery);
            $itemsStmt->bindParam(':order_id', $id);
            $itemsStmt->execute();
            $order['items'] = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);
        }

        return $order;
    }

    public function getDashboardStats($period = 'today') {
        $endDate = date('Y-m-d');
        switch ($period) {
            case 'week':  $startDate = date('Y-m-d', strtotime('-7 days')); break;
            case 'month': $startDate = date('Y-m-d', strtotime('-30 days')); break;
            default:      $startDate = $endDate; break;
        }

        $query = "SELECT COUNT(*) as total_orders, COALESCE(SUM(total), 0) as total_revenue
                  FROM " . $this->table . "
                  WHERE created_at >= :start_date
                  AND created_at < DATE_ADD(:end_date, INTERVAL 1 DAY)
                  AND status = 'completed'";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':start_date', $startDate);
        $stmt->bindParam(':end_date', $endDate);
        $stmt->execute();
        $stats = $stmt->fetch(PDO::FETCH_ASSOC) ?: ['total_orders' => 0, 'total_revenue' => 0];

        $topProductsQuery = "SELECT oi.product_name, SUM(oi.quantity) as total_sold
                             FROM order_items oi
                             JOIN orders o ON oi.order_id = o.id
                             WHERE o.created_at >= :start_date
                             AND o.created_at < DATE_ADD(:end_date, INTERVAL 1 DAY)
                             AND o.status = 'completed'
                             GROUP BY oi.product_id, oi.product_name
                             ORDER BY total_sold DESC LIMIT 5";
        $topStmt = $this->conn->prepare($topProductsQuery);
        $topStmt->bindParam(':start_date', $startDate);
        $topStmt->bindParam(':end_date', $endDate);
        $topStmt->execute();
        $stats['top_products'] = $topStmt->fetchAll(PDO::FETCH_ASSOC);

        return $stats;
    }

    public function update($id, $data) {
        try {
            $this->conn->beginTransaction();

            $updates = [];
            $params  = [':id' => $id];

            if (isset($data['status'])) {
                $updates[] = 'status = :status';
                $params[':status'] = $data['status'];
            }

            // Fetch current status FIRST before building updates
            $currentOrder = $this->conn->prepare('SELECT status FROM ' . $this->table . ' WHERE id = :id');
            $currentOrder->bindValue(':id', $id);
            $currentOrder->execute();
            $currentStatus = $currentOrder->fetchColumn();
            $newStatus = $data['status'] ?? $currentStatus;

            if (isset($data['customer_id'])) {
                $updates[] = 'customer_id = :customer_id';
                $cid = ($data['customer_id'] !== '' && $data['customer_id'] !== null) ? $data['customer_id'] : null;
                $params[':customer_id'] = $cid;
            }

            if (isset($data['discount'])) {
                $updates[] = 'discount = :discount';
                $params[':discount'] = (float)$data['discount'];
            }
            if (isset($data['tax'])) {
                $updates[] = 'tax = :tax';
                $params[':tax'] = (float)$data['tax'];
            }
            if (isset($data['subtotal'])) {
                $updates[] = 'subtotal = :subtotal';
                $params[':subtotal'] = (float)$data['subtotal'];
            }
            if (isset($data['total'])) {
                $updates[] = 'total = :total';
                $params[':total'] = (float)$data['total'];
            }

            if (!empty($updates)) {
                $sql = 'UPDATE ' . $this->table . ' SET ' . implode(', ', $updates) . ' WHERE id = :id';
                $stmt = $this->conn->prepare($sql);
                foreach ($params as $k => $v) {
                    if ($v === null) {
                        $stmt->bindValue($k, null, PDO::PARAM_NULL);
                    } else {
                        $stmt->bindValue($k, $v);
                    }
                }
                $stmt->execute();
            }

            // Replace items if provided (only for pending orders being edited)
            if (isset($data['items']) && is_array($data['items'])) {
                // Old items: only restore stock if the order was already completed
                $old = $this->conn->prepare('SELECT product_id, quantity FROM order_items WHERE order_id = :oid');
                $old->bindValue(':oid', $id);
                $old->execute();
                $oldItems = $old->fetchAll(PDO::FETCH_ASSOC);

                if ($currentStatus === 'completed') {
                    foreach ($oldItems as $row) {
                        $this->conn->prepare('UPDATE products SET stock_quantity = stock_quantity + :q WHERE id = :pid')
                            ->execute([':q' => $row['quantity'], ':pid' => $row['product_id']]);
                    }
                }

                $this->conn->prepare('DELETE FROM order_items WHERE order_id = :oid')
                    ->execute([':oid' => $id]);

                $ins = $this->conn->prepare(
                    'INSERT INTO order_items (id, order_id, product_id, product_name, quantity, unit_price, total_price)
                     VALUES (:iid, :oid, :pid, :pname, :qty, :up, :tp)'
                );
                foreach ($data['items'] as $item) {
                    $qty = (int)$item['quantity'];
                    $ins->execute([
                        ':iid'   => UUID::generate(),
                        ':oid'   => $id,
                        ':pid'   => $item['product_id'],
                        ':pname' => $item['product_name'],
                        ':qty'   => $qty,
                        ':up'    => (float)$item['unit_price'],
                        ':tp'    => (float)$item['total_price'],
                    ]);
                    // Only deduct stock if completing the order
                    if ($newStatus === 'completed') {
                        $this->conn->prepare('UPDATE products SET stock_quantity = stock_quantity - :q WHERE id = :pid')
                            ->execute([':q' => $qty, ':pid' => $item['product_id']]);
                    }
                }
            } elseif ($currentStatus === 'pending' && $newStatus === 'completed') {
                // Status-only change from pending -> completed: deduct stock now
                $orderRow = $this->conn->prepare('SELECT user_id FROM ' . $this->table . ' WHERE id = :id');
                $orderRow->bindValue(':id', $id);
                $orderRow->execute();
                $orderUserId = $orderRow->fetchColumn() ?: 1;

                $items = $this->conn->prepare('SELECT product_id, quantity FROM order_items WHERE order_id = :oid');
                $items->bindValue(':oid', $id);
                $items->execute();
                foreach ($items->fetchAll(PDO::FETCH_ASSOC) as $row) {
                    $this->conn->prepare('UPDATE products SET stock_quantity = stock_quantity - :q WHERE id = :pid')
                        ->execute([':q' => $row['quantity'], ':pid' => $row['product_id']]);
                    $this->conn->prepare("INSERT INTO inventory_logs (id, product_id, user_id, type, quantity_change) VALUES (:id, :pid, :uid, 'sale', :q)")
                        ->execute([':id' => UUID::generate(), ':pid' => $row['product_id'], ':uid' => $orderUserId, ':q' => -$row['quantity']]);
                }
            }

            $this->conn->commit();
            return ['success' => true, 'message' => 'Order updated successfully'];
        } catch (Exception $e) {
            $this->conn->rollBack();
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }

    public function delete($id) {
        try {
            $this->conn->beginTransaction();

            // Get order items to restore stock
            $itemsQuery = "SELECT product_id, quantity FROM order_items WHERE order_id = :order_id";
            $itemsStmt = $this->conn->prepare($itemsQuery);
            $itemsStmt->bindValue(':order_id', $id);
            $itemsStmt->execute();
            $items = $itemsStmt->fetchAll(PDO::FETCH_ASSOC);

            // Restore stock for each item
            foreach ($items as $item) {
                $stockQuery = "UPDATE products SET stock_quantity = stock_quantity + :quantity WHERE id = :product_id";
                $stockStmt = $this->conn->prepare($stockQuery);
                $stockStmt->bindValue(':quantity', $item['quantity'], PDO::PARAM_INT);
                $stockStmt->bindValue(':product_id', $item['product_id'], PDO::PARAM_STR);
                $stockStmt->execute();
            }

            // Delete order items
            $deleteItems = "DELETE FROM order_items WHERE order_id = :order_id";
            $deleteItemsStmt = $this->conn->prepare($deleteItems);
            $deleteItemsStmt->bindValue(':order_id', $id);
            $deleteItemsStmt->execute();

            // Delete payments
            $deletePayments = "DELETE FROM payments WHERE order_id = :order_id";
            $deletePaymentsStmt = $this->conn->prepare($deletePayments);
            $deletePaymentsStmt->bindValue(':order_id', $id);
            $deletePaymentsStmt->execute();

            // Delete order
            $deleteOrder = "DELETE FROM " . $this->table . " WHERE id = :id";
            $deleteOrderStmt = $this->conn->prepare($deleteOrder);
            $deleteOrderStmt->bindValue(':id', $id);
            $deleteOrderStmt->execute();

            $this->conn->commit();
            return ['success' => true, 'message' => 'Order deleted successfully'];
        } catch (Exception $e) {
            $this->conn->rollBack();
            return ['success' => false, 'message' => $e->getMessage()];
        }
    }
}
