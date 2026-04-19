<?php
header('Access-Control-Allow-Origin: *');
header('Content-Type: application/json');
header('Access-Control-Allow-Methods: GET, PUT');
header('Access-Control-Allow-Headers: Content-Type, Authorization');

if ($_SERVER['REQUEST_METHOD'] === 'OPTIONS') {
    http_response_code(200);
    exit();
}

require_once '../config/Database.php';

$database = new Database();
$db = $database->getConnection();

$method = $_SERVER['REQUEST_METHOD'];

// Create table if not exists
try {
    $createTable = "CREATE TABLE IF NOT EXISTS app_settings (
        id CHAR(36) PRIMARY KEY,
        setting_key VARCHAR(100) UNIQUE NOT NULL,
        setting_value VARCHAR(255) NOT NULL,
        description TEXT,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
    )";
    $db->exec($createTable);
    
    // Insert default values if table is empty
    $checkQuery = "SELECT COUNT(*) as count FROM app_settings";
    $stmt = $db->prepare($checkQuery);
    $stmt->execute();
    $result = $stmt->fetch(PDO::FETCH_ASSOC);
    
    $allKeys = [
        'feature_loyalty_program'      => 'false',
        'feature_gift_cards'           => 'false',
        'feature_layaway'              => 'false',
        'feature_multi_store'          => 'true',
        'feature_payment_gateway'      => 'true',
        'feature_reports'              => 'true',
        'feature_audit_trail'          => 'true',
        'feature_backup_restore'       => 'true',
        'feature_notifications'        => 'true',
        'feature_permissions'          => 'true',
        'feature_refunds'              => 'true',
        'feature_price_management'     => 'true',
        'feature_tax_management'       => 'true',
        'feature_currency_management'  => 'true',
        'feature_stock_management'     => 'true',
        'feature_employee_management'  => 'true',
        'feature_suppliers'            => 'true',
        'feature_customers'            => 'true',
        'feature_categories'           => 'true',
        'feature_pending_orders'       => 'true',
        'feature_customer_analytics'   => 'true',
        'feature_inventory_analytics'  => 'true',
    ];

    // Insert any missing keys (safe for both fresh and existing installs)
    $insert = $db->prepare(
        "INSERT IGNORE INTO app_settings (id, setting_key, setting_value) VALUES (UUID(), :key, :value)"
    );
    foreach ($allKeys as $key => $value) {
        $insert->execute([':key' => $key, ':value' => $value]);
    }
} catch (Exception $e) {
    error_log("Error creating app_settings table: " . $e->getMessage());
}

try {
    if ($method === 'GET') {
        $query = "SELECT * FROM app_settings";
        $stmt = $db->prepare($query);
        $stmt->execute();
        $settings = $stmt->fetchAll(PDO::FETCH_ASSOC);
        
        $settingsMap = [];
        foreach ($settings as $setting) {
            $settingsMap[$setting['setting_key']] = $setting['setting_value'] === 'true';
        }
        
        echo json_encode(['success' => true, 'data' => $settingsMap]);
    } elseif ($method === 'PUT') {
        $data = json_decode(file_get_contents("php://input"), true);
        
        if (!$data) {
            echo json_encode(['success' => false, 'message' => 'Invalid JSON data']);
            exit();
        }
        
        foreach ($data as $key => $value) {
            $valueStr = $value ? 'true' : 'false';
            $query = "INSERT INTO app_settings (id, setting_key, setting_value)
                      VALUES (UUID(), :key, :value)
                      ON DUPLICATE KEY UPDATE setting_value = :value2";
            $stmt = $db->prepare($query);
            $stmt->bindValue(':key', $key);
            $stmt->bindValue(':value', $valueStr);
            $stmt->bindValue(':value2', $valueStr);
            $stmt->execute();
        }
        
        echo json_encode(['success' => true, 'message' => 'Settings updated']);
    } else {
        echo json_encode(['success' => false, 'message' => 'Method not allowed']);
    }
} catch (Exception $e) {
    error_log("Error in app_settings.php: " . $e->getMessage());
    echo json_encode(['success' => false, 'message' => $e->getMessage()]);
}
