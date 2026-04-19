<?php
require_once __DIR__ . '/Config.php';

class Database {
    private $host;
    private $db_name;
    private $username;
    private $password;
    public $conn;

    public function __construct() {
        $this->host     = defined('DB_HOST') ? DB_HOST : Config::get('DB_HOST', 'localhost');
        $this->db_name  = defined('DB_NAME') ? DB_NAME : Config::get('DB_NAME', 'global_pos');
        $this->username = defined('DB_USER') ? DB_USER : Config::get('DB_USER', 'root');
        $this->password = defined('DB_PASS') ? DB_PASS : Config::get('DB_PASSWORD', '');
    }

    public function getConnection() {
        $this->conn = null;
        try {
            $this->conn = new PDO(
                "mysql:host=" . $this->host . ";dbname=" . $this->db_name . ";charset=utf8",
                $this->username,
                $this->password
            );
            $this->conn->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
        } catch(PDOException $e) {
            throw new Exception("Database connection failed: " . $e->getMessage());
        }
        return $this->conn;
    }
}
