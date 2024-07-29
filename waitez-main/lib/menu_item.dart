// menu_item.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class MenuItem {
  final String id;
  final String name;
  final int price;
  final String description;
  final String origin;
  final String photoUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.price,
    required this.description,
    required this.origin,
    required this.photoUrl,
  });

  factory MenuItem.fromDocument(DocumentSnapshot document) {
    final data = document.data() as Map<String, dynamic>;
    return MenuItem(
      id: document.id,
      name: data['menuName'] ?? '',
      price: data['price'] ?? 0,
      description: data['description'] ?? '',
      origin: data['origin'] ?? '',
      photoUrl: data['photoUrl'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'menuName': name,
      'price': price,
      'description': description,
      'origin': origin,
      'photoUrl': photoUrl,
    };
  }
}
