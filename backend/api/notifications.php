<?php
require_once __DIR__ . '/_bootstrap.php';
require_once __DIR__ . '/../utils/NotificationHelper.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();
    
    $database = new Database();
    $db = $database->getConnection();

    $db->exec("CREATE TABLE IF NOT EXISTS notification_settings (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        setting_key VARCHAR(100) UNIQUE NOT NULL,
        setting_value TEXT,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )");

    $db->exec("CREATE TABLE IF NOT EXISTS notification_logs (
        id CHAR(36) PRIMARY KEY DEFAULT (UUID()),
        type ENUM('email','sms') NOT NULL,
        recipient VARCHAR(255) NOT NULL,
        subject VARCHAR(255),
        message TEXT,
        status ENUM('sent','failed') DEFAULT 'sent',
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents('php://input'), true);

    if ($method === 'GET') {
        if (isset($_GET['settings'])) {
            AuthMiddleware::checkRole($currentUser, ['admin']);
            $rows = $db->query('SELECT setting_key, setting_value FROM notification_settings')->fetchAll(PDO::FETCH_ASSOC);
            $settings = [];
            foreach ($rows as $row) $settings[$row['setting_key']] = $row['setting_value'];
            sendJson(['success' => true, 'data' => $settings]);
        } elseif (isset($_GET['daily_summary'])) {
            AuthMiddleware::checkRole($currentUser, ['admin']);
            sendDailySummaryIfEnabled($db);
            sendJson(['success' => true, 'message' => 'Daily summary sent']);
        }
    } elseif ($method === 'POST') {
        AuthMiddleware::checkRole($currentUser, ['admin']);
        $action = $data['action'] ?? '';

        if ($action === 'save_settings') {
            $keys = ['email_receipts','low_stock_alerts','daily_summary','sms_notifications',
                     'admin_email','smtp_host','smtp_port','smtp_user','smtp_pass'];
            $stmt = $db->prepare('INSERT INTO notification_settings (setting_key, setting_value)
                                  VALUES (:k, :v) ON DUPLICATE KEY UPDATE setting_value = :v2');
            foreach ($keys as $key) {
                if (isset($data[$key])) {
                    $val = $data[$key];
                    // Remove spaces from SMTP password (Gmail App Passwords have spaces)
                    if ($key === 'smtp_pass') {
                        $val = str_replace(' ', '', $val);
                    }
                    $stmt->execute([':k' => $key, ':v' => $val, ':v2' => $val]);
                }
            }
            sendJson(['success' => true, 'message' => 'Settings saved']);

        } elseif ($action === 'test_email') {
            $recipient = $data['email'] ?? '';
            
            // Get SMTP settings
            $rows = $db->query('SELECT setting_key, setting_value FROM notification_settings')->fetchAll(PDO::FETCH_ASSOC);
            $settings = [];
            foreach ($rows as $row) $settings[$row['setting_key']] = $row['setting_value'];
            
            $smtpHost = trim($settings['smtp_host'] ?? '');
            $smtpPort = (int)($settings['smtp_port'] ?? 587);
            $smtpUser = trim($settings['smtp_user'] ?? '');
            $smtpPass = str_replace(' ', '', $settings['smtp_pass'] ?? '');
            $recipient = trim($recipient);
            
            if (empty($smtpHost) || empty($smtpUser) || empty($smtpPass)) {
                sendJson(['success' => false, 'message' => 'SMTP not configured. Please fill all email settings first.']);
                exit;
            }
            
            $subject = 'Test Email from Global POS';
            $body    = 'This is a test email from your Global POS system. Email notifications are working!';
            
            $error = sendSmtpEmail($smtpHost, $smtpPort, $smtpUser, $smtpPass, $smtpUser, $recipient, $subject, $body);
            $status = $error === null ? 'sent' : 'failed';
            
            $db->prepare("INSERT INTO notification_logs (type, recipient, subject, status)
                          VALUES ('email', :r, :s, :status)")
               ->execute([':r' => $recipient, ':s' => $subject, ':status' => $status]);
            
            if ($error === null) {
                sendJson(['success' => true, 'message' => 'Test email sent successfully! Check your inbox.']);
            } else {
                sendJson(['success' => false, 'message' => 'SMTP Error: ' . $error]);
            }
        }
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
