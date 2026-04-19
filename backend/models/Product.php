<?php

require_once __DIR__ . '/../utils/UUID.php';

class Product {
    private $conn;
    private $table = 'products';

    public function __construct($db) {
        $this->conn = $db;
    }

    public function getAll() {
        $query = "SELECT p.*, c.name as category_name, s.name as supplier_name FROM " . $this->table . " p LEFT JOIN categories c ON p.category_id = c.id LEFT JOIN suppliers s ON p.supplier_id = s.id WHERE p.is_active = 1 ORDER BY p.created_at DESC";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }

    public function getById($id) {
        $query = "SELECT p.*, c.name as category_name, s.name as supplier_name FROM " . $this->table . " p LEFT JOIN categories c ON p.category_id = c.id LEFT JOIN suppliers s ON p.supplier_id = s.id WHERE p.id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function searchByBarcode($barcode) {
        $query = "SELECT * FROM " . $this->table . " WHERE barcode = :barcode AND is_active = 1";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':barcode', $barcode);
        $stmt->execute();
        return $stmt->fetch(PDO::FETCH_ASSOC);
    }

    public function create($data) {
        $id = UUID::generate();
        $query = "INSERT INTO " . $this->table . " (id, name, barcode, category_id, supplier_id, description, cost_price, selling_price, stock_quantity, low_stock_threshold, image_url) VALUES (:id, :name, :barcode, :category_id, :supplier_id, :description, :cost_price, :selling_price, :stock_quantity, :low_stock_threshold, :image_url)";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':name', $data['name']);
        $stmt->bindParam(':barcode', $data['barcode']);
        $stmt->bindParam(':category_id', $data['category_id']);
        $stmt->bindParam(':supplier_id', $data['supplier_id']);
        $stmt->bindParam(':description', $data['description']);
        $stmt->bindParam(':cost_price', $data['cost_price']);
        $stmt->bindParam(':selling_price', $data['selling_price']);
        $stmt->bindParam(':stock_quantity', $data['stock_quantity']);
        $stmt->bindParam(':low_stock_threshold', $data['low_stock_threshold']);
        $stmt->bindParam(':image_url', $data['image_url']);
        return $stmt->execute();
    }

    public function update($id, $data) {
        $query = "UPDATE " . $this->table . " SET name = :name, barcode = :barcode, category_id = :category_id, supplier_id = :supplier_id, description = :description, cost_price = :cost_price, selling_price = :selling_price, stock_quantity = :stock_quantity, low_stock_threshold = :low_stock_threshold, image_url = :image_url WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':name', $data['name']);
        $stmt->bindParam(':barcode', $data['barcode']);
        $stmt->bindParam(':category_id', $data['category_id']);
        $stmt->bindParam(':supplier_id', $data['supplier_id']);
        $stmt->bindParam(':description', $data['description']);
        $stmt->bindParam(':cost_price', $data['cost_price']);
        $stmt->bindParam(':selling_price', $data['selling_price']);
        $stmt->bindParam(':stock_quantity', $data['stock_quantity']);
        $stmt->bindParam(':low_stock_threshold', $data['low_stock_threshold']);
        $stmt->bindParam(':image_url', $data['image_url']);
        return $stmt->execute();
    }

    public function delete($id) {
        $query = "UPDATE " . $this->table . " SET is_active = 0 WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        return $stmt->execute();
    }

    public function updateStock($id, $quantity) {
        $query = "UPDATE " . $this->table . " SET stock_quantity = stock_quantity + :quantity WHERE id = :id";
        $stmt = $this->conn->prepare($query);
        $stmt->bindParam(':id', $id);
        $stmt->bindParam(':quantity', $quantity);
        return $stmt->execute();
    }

    public function getLowStock() {
        $query = "SELECT * FROM " . $this->table . " WHERE stock_quantity <= low_stock_threshold AND is_active = 1";
        $stmt = $this->conn->prepare($query);
        $stmt->execute();
        return $stmt->fetchAll(PDO::FETCH_ASSOC);
    }
}
