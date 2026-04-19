<?php
// Shared notification helper — included by orders, stock_management, etc.

require_once __DIR__ . '/../config/Config.php';

function getSmtpSettings($db) {
    try {
        $rows = $db->query('SELECT setting_key, setting_value FROM notification_settings')->fetchAll(PDO::FETCH_ASSOC);
        $s = [];
        foreach ($rows as $row) $s[$row['setting_key']] = $row['setting_value'];
        return $s;
    } catch (Exception $e) {
        return [];
    }
}

function logNotification($db, $type, $recipient, $subject, $status) {
    try {
        $db->prepare("INSERT INTO notification_logs (type, recipient, subject, status) VALUES (:t, :r, :s, :st)")
           ->execute([':t' => $type, ':r' => $recipient, ':s' => $subject, ':st' => $status]);
    } catch (Exception $e) {}
}

function _smtpRead($socket) {
    $res = '';
    while ($line = fgets($socket, 512)) {
        $res .= $line;
        if (strlen($line) >= 4 && $line[3] === ' ') break;
    }
    return $res;
}

function sendSmtpEmail($host, $port, $user, $pass, $from, $to, $subject, $body) {
    return sendSmtpEmailWithAttachment($host, $port, $user, $pass, $from, $to, $subject, $body);
}

function sendSmtpEmailWithAttachment($host, $port, $user, $pass, $from, $to, $subject, $body, $pdfBase64 = null, $filename = 'receipt.pdf') {
    $timeout = Config::getInt('SMTP_TIMEOUT', 15);
    $socket = @stream_socket_client("tcp://{$host}:{$port}", $errno, $errstr, $timeout);
    if (!$socket) return "Cannot connect to {$host}:{$port} — {$errstr}";

    stream_set_timeout($socket, $timeout);
    $banner = _smtpRead($socket);
    if (strpos($banner, '220') === false) { fclose($socket); return "Bad banner: {$banner}"; }

    fputs($socket, "EHLO localhost\r\n"); _smtpRead($socket);
    fputs($socket, "STARTTLS\r\n");
    $tls = _smtpRead($socket);
    if (strpos($tls, '220') === false) { fclose($socket); return "STARTTLS failed: {$tls}"; }

    if (!stream_socket_enable_crypto($socket, true, STREAM_CRYPTO_METHOD_TLS_CLIENT)) {
        fclose($socket); return 'TLS upgrade failed.';
    }

    fputs($socket, "EHLO localhost\r\n"); _smtpRead($socket);
    fputs($socket, "AUTH LOGIN\r\n");
    $r = _smtpRead($socket);
    if (strpos($r, '334') === false) { fclose($socket); return "AUTH LOGIN failed: {$r}"; }

    fputs($socket, base64_encode($user) . "\r\n");
    $r = _smtpRead($socket);
    if (strpos($r, '334') === false) { fclose($socket); return "Username rejected: {$r}"; }

    fputs($socket, base64_encode($pass) . "\r\n");
    $r = _smtpRead($socket);
    if (strpos($r, '235') === false) { fclose($socket); return "Auth failed: {$r}"; }

    fputs($socket, "MAIL FROM:<" . trim($from) . ">\r\n");
    $r = _smtpRead($socket);
    if (strpos($r, '250') === false) { fclose($socket); return "MAIL FROM failed: {$r}"; }

    fputs($socket, "RCPT TO:<" . trim($to) . ">\r\n");
    $r = _smtpRead($socket);
    if (strpos($r, '250') === false) { fclose($socket); return "RCPT TO failed: {$r}"; }

    fputs($socket, "DATA\r\n");
    $r = _smtpRead($socket);
    if (strpos($r, '354') === false) { fclose($socket); return "DATA failed: {$r}"; }

    if ($pdfBase64) {
        $boundary = 'BOUND_' . md5(time());
        $fromName = Config::get('SMTP_FROM_NAME', 'Global POS');
        $msg  = "From: {$fromName} <{$from}>\r\n";
        $msg .= "To: {$to}\r\n";
        $msg .= "Subject: {$subject}\r\n";
        $msg .= "MIME-Version: 1.0\r\n";
        $msg .= "Content-Type: multipart/mixed; boundary=\"{$boundary}\"\r\n\r\n";
        $msg .= "--{$boundary}\r\n";
        $msg .= "Content-Type: text/plain; charset=UTF-8\r\n\r\n";
        $msg .= "{$body}\r\n";
        $msg .= "--{$boundary}\r\n";
        $msg .= "Content-Type: application/pdf; name=\"{$filename}\"\r\n";
        $msg .= "Content-Disposition: attachment; filename=\"{$filename}\"\r\n";
        $msg .= "Content-Transfer-Encoding: base64\r\n\r\n";
        $msg .= chunk_split($pdfBase64, 76, "\r\n");
        $msg .= "--{$boundary}--\r\n";
    } else {
        $fromName = Config::get('SMTP_FROM_NAME', 'Global POS');
        $msg  = "From: {$fromName} <{$from}>\r\n";
        $msg .= "To: {$to}\r\n";
        $msg .= "Subject: {$subject}\r\n";
        $msg .= "MIME-Version: 1.0\r\n";
        $msg .= "Content-Type: text/plain; charset=UTF-8\r\n\r\n";
        $msg .= "{$body}\r\n";
    }
    $msg .= ".\r\n";
    fputs($socket, $msg);
    $r = _smtpRead($socket);
    if (strpos($r, '250') === false) { fclose($socket); return "Message rejected: {$r}"; }

    fputs($socket, "QUIT\r\n");
    fclose($socket);
    return null;
}

function sendEmailReceiptIfEnabled($db, $orderData, $orderId, $orderNumber = null) {
    $s = getSmtpSettings($db);
    if (($s['email_receipts'] ?? '0') !== '1') return;
    if (empty($s['smtp_host']) || empty($s['smtp_user']) || empty($s['smtp_pass'])) return;

    $customerId = $orderData['customer_id'] ?? null;
    if (!$customerId) return;
    $stmt = $db->prepare('SELECT email, name, phone FROM customers WHERE id = :id');
    $stmt->execute([':id' => $customerId]);
    $customer = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$customer || empty($customer['email'])) return;

    // Fetch order items
    $stmt = $db->prepare('SELECT oi.*, p.name FROM order_items oi JOIN products p ON oi.product_id = p.id WHERE oi.order_id = :id');
    $stmt->execute([':id' => $orderId]);
    $items = $stmt->fetchAll(PDO::FETCH_ASSOC);

    // Use real order_number, fallback to padded ID
    $displayNumber = $orderNumber ?? ('ORD-' . str_pad($orderId, 6, '0', STR_PAD_LEFT));

    // Generate PDF
    require_once __DIR__ . '/ReceiptPdf.php';
    $pdfContent = generateReceiptPdf($displayNumber, $customer, $orderData, $items);
    $pdfBase64  = base64_encode($pdfContent);

    $subject = "Receipt for {$displayNumber} - " . Config::get('COMPANY_NAME', 'Global POS');
    $body    = "Dear {$customer['name']},\n\nThank you for your purchase! Please find your receipt attached as a PDF.\n\nOrder: {$displayNumber}\nTotal: $" . number_format($orderData['total'], 2) . "\n\nThank you for shopping with us!\n" . Config::get('COMPANY_NAME', 'Global POS');

    $error = sendSmtpEmailWithAttachment(
        trim($s['smtp_host']), (int)($s['smtp_port'] ?? 587),
        trim($s['smtp_user']), str_replace(' ', '', $s['smtp_pass']),
        trim($s['smtp_user']), trim($customer['email']),
        $subject, $body, $pdfBase64, "receipt_{$displayNumber}.pdf"
    );
    logNotification($db, 'email', $customer['email'], $subject, $error === null ? 'sent' : 'failed');
}

function sendLowStockAlertIfEnabled($db, $productId) {
    $s = getSmtpSettings($db);
    if (($s['low_stock_alerts'] ?? '0') !== '1') return;
    if (empty($s['admin_email']) || empty($s['smtp_host']) || empty($s['smtp_user']) || empty($s['smtp_pass'])) return;

    $stmt = $db->prepare('SELECT name, stock_quantity, low_stock_threshold FROM products WHERE id = :id');
    $stmt->execute([':id' => $productId]);
    $product = $stmt->fetch(PDO::FETCH_ASSOC);
    if (!$product) return;

    $threshold = $product['low_stock_threshold'] ?? 10;
    if ($product['stock_quantity'] > $threshold) return;

    $subject = "Low Stock Alert: {$product['name']}";
    $body  = "Low Stock Warning!\n\n";
    $body .= "Product: {$product['name']}\n";
    $body .= "Current Stock: {$product['stock_quantity']}\n";
    $body .= "Threshold: {$threshold}\n\n";
    $body .= "Please restock this item soon.\n" . Config::get('COMPANY_NAME', 'Global POS');

    $error = sendSmtpEmail(
        trim($s['smtp_host']), (int)($s['smtp_port'] ?? 587),
        trim($s['smtp_user']), str_replace(' ', '', $s['smtp_pass']),
        trim($s['smtp_user']), trim($s['admin_email']), $subject, $body
    );
    logNotification($db, 'email', $s['admin_email'], $subject, $error === null ? 'sent' : 'failed');
}

function sendDailySummaryIfEnabled($db) {
    $s = getSmtpSettings($db);
    if (($s['daily_summary'] ?? '0') !== '1') return;
    if (empty($s['admin_email']) || empty($s['smtp_host']) || empty($s['smtp_user']) || empty($s['smtp_pass'])) return;

    $today = date('Y-m-d');
    $stmt = $db->prepare("SELECT COUNT(*) as orders, SUM(total) as revenue FROM orders WHERE DATE(created_at) = :d AND status = 'completed'");
    $stmt->execute([':d' => $today]);
    $stats = $stmt->fetch(PDO::FETCH_ASSOC);

    $subject = "Daily Sales Summary - {$today}";
    $body  = "Daily Sales Report for {$today}\n\n";
    $body .= "Total Orders: " . ($stats['orders'] ?? 0) . "\n";
    $body .= "Total Revenue: $" . number_format($stats['revenue'] ?? 0, 2) . "\n\n";
    $body .= "Global POS System";

    $error = sendSmtpEmail(
        trim($s['smtp_host']), (int)($s['smtp_port'] ?? 587),
        trim($s['smtp_user']), str_replace(' ', '', $s['smtp_pass']),
        trim($s['smtp_user']), trim($s['admin_email']), $subject, $body
    );
    logNotification($db, 'email', $s['admin_email'], $subject, $error === null ? 'sent' : 'failed');
}
