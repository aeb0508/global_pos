class Product {
  final String id;
  final String name;
  final String? barcode;
  final String? categoryId;
  final String? categoryName;
  final String? supplierId;
  final String? supplierName;
  final String? description;
  final double costPrice;
  final double sellingPrice;
  final int stockQuantity;
  final int lowStockThreshold;
  final String? imageUrl;

  Product({
    required this.id,
    required this.name,
    this.barcode,
    this.categoryId,
    this.categoryName,
    this.supplierId,
    this.supplierName,
    this.description,
    required this.costPrice,
    required this.sellingPrice,
    required this.stockQuantity,
    required this.lowStockThreshold,
    this.imageUrl,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'].toString(),
      name: json['name'],
      barcode: json['barcode'],
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name'],
      supplierId: json['supplier_id']?.toString(),
      supplierName: json['supplier_name'],
      description: json['description'],
      costPrice: double.parse(json['cost_price'].toString()),
      sellingPrice: double.parse(json['selling_price'].toString()),
      stockQuantity: int.parse(json['stock_quantity'].toString()),
      lowStockThreshold: int.parse(json['low_stock_threshold'].toString()),
      imageUrl: json['image_url'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'barcode': barcode,
      'category_id': categoryId,
      'description': description,
      'cost_price': costPrice,
      'selling_price': sellingPrice,
      'stock_quantity': stockQuantity,
      'low_stock_threshold': lowStockThreshold,
      'image_url': imageUrl,
    };
  }
}
