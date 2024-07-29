import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item.dart'; // Import the MenuItem class
import 'MenuRegOne.dart';

class MenuRegList extends StatefulWidget {
  @override
  _MenuRegListState createState() => _MenuRegListState();
}

class _MenuRegListState extends State<MenuRegList> {
  late Future<List<MenuItem>> _menuItemsFuture;
  List<MenuItem> _allMenuItems = [];
  List<MenuItem> _filteredMenuItems = [];
  String? _searchKeyword;

  @override
  void initState() {
    super.initState();
    _menuItemsFuture = _loadMenuItems();
  }

  Future<List<MenuItem>> _loadMenuItems() async {
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
              .map((menuDoc) => MenuItem.fromDocument(menuDoc))
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
    List<MenuItem> results = _allMenuItems;
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

  Future<void> _deleteMenuItem(MenuItem menuItem) async {
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
              .where('menuName', isEqualTo: menuItem.name)
              .get();

          if (menuItemsQuery.docs.isNotEmpty) {
            final menuItemId = menuItemsQuery.docs.first.id;
            await FirebaseFirestore.instance
                .collection('restaurants')
                .doc(restaurantId)
                .collection('menus')
                .doc(menuItemId)
                .delete();

            setState(() {
              _allMenuItems.remove(menuItem);
              _filteredMenuItems.remove(menuItem);
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('메뉴가 삭제되었습니다.')),
            );
          }
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('메뉴 정보'),
      ),
      body: FutureBuilder<List<MenuItem>>(
        future: _menuItemsFuture,
        builder: (context, snapshot) {
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
                child: snapshot.connectionState == ConnectionState.waiting
                    ? Center(child: CircularProgressIndicator())
                    : _filteredMenuItems.isEmpty
                        ? Center(child: Text('해당하는 메뉴가 존재하지 않습니다.'))
                        : ListView.builder(
                            itemCount: _filteredMenuItems.length,
                            itemBuilder: (context, index) {
                              final menuItem = _filteredMenuItems[index];
                              return ListTile(
                                leading: Icon(Icons.fastfood),
                                title: Text(menuItem.name),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('가격: ${menuItem.price}원'),
                                    Text('설명: ${menuItem.description}'),
                                    Text('원산지: ${menuItem.origin}'),
                                  ],
                                ),
                              );
                            },
                          ),
              ),
              SizedBox(
                height: 100,
                child: Center(
                  child: ElevatedButton(
                    onPressed: () {
                      // 메뉴 등록 페이지로 이동
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MenuRegOne(
                            onSave: (menuItem) {
                              setState(() {
                                _allMenuItems.add(menuItem);
                                _filteredMenuItems.add(menuItem);
                              });
                            },
                          ),
                        ),
                      );
                    },
                    child: Text('+'),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
