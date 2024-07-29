import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'UserBottom.dart'; // Assume this widget exists

class Favorite extends StatefulWidget {
  const Favorite({super.key});

  @override
  State<Favorite> createState() => _FavoriteState();
}

class FavoriteDetails {
  final String id;
  final String name;
  final String address;
  final String description;

  FavoriteDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
  });

  factory FavoriteDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return FavoriteDetails(
      id: doc.id,
      name: data['name'],
      address: data['address'],
      description: data['description'],
    );
  }
}

class _FavoriteState extends State<Favorite> {
  List<FavoriteDetails> allItems = [];
  List<FavoriteDetails> filteredItems = [];
  User? user;

  @override
  void initState() {
    super.initState();
    _fetchFavorites();
  }

  Future<void> _fetchFavorites() async {
    user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favoritesSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .get();

      List<FavoriteDetails> favorites = favoritesSnapshot.docs
          .map((doc) => FavoriteDetails.fromFirestore(doc))
          .toList();

      setState(() {
        allItems = favorites;
        filteredItems = favorites;
      });
    }
  }

  void _filterItems(String enteredKeyword) {
    List<FavoriteDetails> results = [];
    if (enteredKeyword.isEmpty) {
      results = allItems;
    } else {
      results = allItems
          .where((item) =>
              item.name.toLowerCase().contains(enteredKeyword.toLowerCase()))
          .toList();
    }
    setState(() {
      filteredItems = results;
    });
  }

  Future<void> _removeFavorite(FavoriteDetails item) async {
    if (user != null) {
      final userFavoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites');

      final favoriteDoc = userFavoritesRef.doc(item.id);

      final favoriteSnapshot = await favoriteDoc.get();

      if (favoriteSnapshot.exists) {
        await favoriteDoc.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('즐겨찾기가 해제되었습니다.')),
        );
      }

      _fetchFavorites(); // Update the favorite list
    }
  }

  Future<bool> _isFavorite(FavoriteDetails item) async {
    if (user != null) {
      final favoriteSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .collection('favorites')
          .doc(item.id)
          .get();

      return favoriteSnapshot.exists;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 80,
        title: Text(
          '즐겨찾기',
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            fontWeight: FontWeight.w700,
            height: 0.07,
            letterSpacing: -0.27,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              onChanged: (value) => _filterItems(value),
              decoration: InputDecoration(
                hintText: "즐겨찾기 검색",
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Color(0xFFEDEFF2),
              ),
            ),
            const SizedBox(height: 20),
            filteredItems.isEmpty
                ? Center(child: Text('즐겨찾기 한 음식점이 존재하지 않습니다'))
                : ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredItems.length,
                    itemBuilder: (context, index) {
                      var item = filteredItems[index];
                      return FutureBuilder<bool>(
                        future: _isFavorite(item),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return CircularProgressIndicator();
                          }

                          final isFavorite = snapshot.data ?? false;

                          return ListTile(
                            title: Text(item.name),
                            subtitle:
                                Text("${item.address}\n${item.description}"),
                            trailing: IconButton(
                              icon: Icon(
                                isFavorite ? Icons.star : Icons.star_border,
                                color: isFavorite ? Colors.yellow : null,
                              ),
                              onPressed: () => _removeFavorite(item),
                            ),
                            onTap: () {
                              Navigator.pushNamed(context, '/restaurantInfo',
                                  arguments: item.id);
                            },
                          );
                        },
                      );
                    },
                  ),
          ],
        ),
      ),
      bottomNavigationBar: menuButtom(), // 하단 네비게이션 바
    );
  }
}
