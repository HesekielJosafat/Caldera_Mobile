class Menu {
  final int id;
  final String name;
  final String category;
  final String description;
  final double price;
  final String? image;
  final bool isAvailable;
  final bool isRecommended;
  
  Menu({
    required this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.price,
    this.image,
    required this.isAvailable,
    required this.isRecommended,
  });
  
  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      id: json['id'],
      name: json['name'],
      category: json['category'],
      description: json['description'],
      price: json['price'].toDouble(),
      image: json['image'],
      isAvailable: json['is_available'],
      isRecommended: json['is_recommended'],
    );
  }
}