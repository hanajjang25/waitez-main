import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'MenuEditDetail.dart' as detail; // Prefix for MenuEditDetail
import 'menu_item.dart' as item; // Prefix for MenuItem class

class MenuEdit extends StatefulWidget {
  @override
  _MenuEditState createState() => _MenuEditState();
}

class _MenuEditState extends State<MenuEdit> {
  late Future<List<item.MenuItem>> _menuItemsFuture; // Use prefixed class name
  List<item.MenuItem> _allMenuItems = [];
  List<item.MenuItem> _filteredMenuItems = [];
  String? _searchKeyword;

  @override
  void initState() {
    super.initState();
    _menuItemsFuture = _loadMenuItems();
  }

  Future<List<item.MenuItem>> _loadMenuItems() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDocRef =
          FirebaseFirestore.instance.collection('users').doc(user.uid);
      final userDocSnapshot = await userDocRef.get();
      final resNum = userDocSnapshot.data()?['resNum'] as String?;

      if (resNum != null) {
        final restaurantQuery = await FirebaseFirestore.instance
            .collection('restaurants')
            .where('registrationNumber', isEqualTo: resNum)
            .where('isDeleted', isEqualTo: false)
            .get();

        if (restaurantQuery.docs.isNotEmpty) {
          final restaurantId = restaurantQuery.docs.first.id;
          final menuItemsQuery = await FirebaseFirestore.instance
              .collection('restaurants')
              .doc(restaurantId)
              .collection('menus')
              .get();

          final menuItems = menuItemsQuery.docs
              .map((menuDoc) => item.MenuItem.fromDocument(menuDoc))
              .toList();

          setState(() {
            _allMenuItems = menuItems;
            _filteredMenuItems = menuItems;
          });

          return menuItems;
        }
      }
    }
    return [];
  }

  void _filterItems() {
    List<item.MenuItem> results = _allMenuItems;
    if (_searchKeyword != null && _searchKeyword!.isNotEmpty) {
      results = results.where((item) {
        return item.name
                .toLowerCase()
                .contains(_searchKeyword!.toLowerCase()) ||
            item.description
                .toLowerCase()
                .contains(_searchKeyword!.toLowerCase());
      }).toList();
    }

    setState(() {
      _filteredMenuItems = results;
    });
  }

  void _updateSearch(String search) {
    setState(() {
      _searchKeyword = search;
      _filterItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메뉴 수정'),
      ),
      body: FutureBuilder<List<item.MenuItem>>(
        future: _menuItemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) => _updateSearch(value),
                    decoration: InputDecoration(
                      hintText: '검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text('등록된 메뉴가 없습니다.'),
                  ),
                ),
              ],
            );
          } else {
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextField(
                    onChanged: (value) => _updateSearch(value),
                    decoration: InputDecoration(
                      hintText: '검색',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: _filteredMenuItems.isNotEmpty
                      ? ListView.builder(
                          itemCount: _filteredMenuItems.length,
                          itemBuilder: (context, index) {
                            final menuItem = _filteredMenuItems[index];
                            return ListTile(
                              leading: Icon(Icons.fastfood),
                              title: Text(menuItem.name),
                              subtitle: Text('가격: ${menuItem.price}원'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => detail.MenuEditDetail(
                                        menuItemId: menuItem.id),
                                  ),
                                );
                              },
                            );
                          },
                        )
                      : Center(
                          child: Text('해당하는 메뉴가 존재하지 않습니다.'),
                        ),
                ),
              ],
            );
          }
        },
      ),
    );
  }
}
