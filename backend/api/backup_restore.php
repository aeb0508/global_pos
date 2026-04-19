<?php
require_once __DIR__ . '/_bootstrap.php';

try {
    require_once __DIR__ . '/../config/Database.php';
    require_once __DIR__ . '/../config/Config.php';
    require_once __DIR__ . '/../middleware/AuthMiddleware.php';
    require_once __DIR__ . '/../utils/JWT.php';

    $currentUser = AuthMiddleware::authenticate();

    $database = new Database();
    $db = $database->getConnection();

    $method = $_SERVER['REQUEST_METHOD'];
    $data = json_decode(file_get_contents("php://input"), true);

    $backupDir = __DIR__ . '/../backups/';
    if (!file_exists($backupDir)) {
        mkdir($backupDir, 0777, true);
    }

    if ($method === 'GET') {
        AuthMiddleware::checkPermission($currentUser, 'backup', 'view');
        // List all backups
        $backups = [];
        $files = glob($backupDir . '*.sql');
        
        foreach ($files as $file) {
            $backups[] = [
                'filename' => basename($file),
                'created_at' => date('Y-m-d H:i:s', filemtime($file)),
                'size' => round(filesize($file) / 1024, 2) . ' KB'
            ];
        }

        // Sort by date descending
        usort($backups, function($a, $b) {
            return strtotime($b['created_at']) - strtotime($a['created_at']);
        });

        sendJson(['success' => true, 'data' => $backups]);

    } elseif ($method === 'POST') {
        $action = $data['action'] ?? '';

        if ($action === 'backup') {
            AuthMiddleware::checkPermission($currentUser, 'backup', 'create');
            // Create backup
            $filename = 'backup_' . date('Y-m-d_H-i-s') . '.sql';
            $filepath = $backupDir . $filename;

            // Get database credentials from config
            $host = Config::get('DB_HOST', 'localhost');
            $dbname = Config::get('DB_NAME', 'global_pos');
            $username = Config::get('DB_USER', 'root');
            $password = Config::get('DB_PASSWORD', '');

            // Execute mysqldump
            $passwordArg = !empty($password) ? "--password=$password" : '';
            $command = "mysqldump --host=$host --user=$username $passwordArg $dbname > $filepath";
            exec($command, $output, $result);

            if ($result === 0) {
                sendJson(['success' => true, 'message' => 'Backup created successfully']);
            } else {
                throw new Exception('Backup failed. Ensure mysqldump is in PATH.');
            }

        } elseif ($action === 'restore') {
            AuthMiddleware::checkPermission($currentUser, 'backup', 'edit');
            // Restore backup
            $filename = $data['filename'] ?? '';
            $filepath = $backupDir . $filename;

            if (!file_exists($filepath)) {
                throw new Exception('Backup file not found');
            }

            // Get database credentials from config
            $host = Config::get('DB_HOST', 'localhost');
            $dbname = Config::get('DB_NAME', 'global_pos');
            $username = Config::get('DB_USER', 'root');
            $password = Config::get('DB_PASSWORD', '');

            // Execute mysql restore
            $passwordArg = !empty($password) ? "--password=$password" : '';
            $command = "mysql --host=$host --user=$username $passwordArg $dbname < $filepath";
            exec($command, $output, $result);

            if ($result === 0) {
                sendJson(['success' => true, 'message' => 'Database restored successfully']);
            } else {
                throw new Exception('Restore failed. Ensure mysql is in PATH.');
            }
        }
    }
} catch (Exception $e) {
    sendJson(['success' => false, 'message' => 'Server error: ' . $e->getMessage()], 500);
}
