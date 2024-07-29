import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'reservationBottom.dart';
import 'MemberFavorite.dart';
import 'RestaurantInfo.dart';
import 'googleMap.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class search extends StatefulWidget {
  const search({super.key});

  @override
  State<search> createState() => _SearchState();
}

class SearchDetails {
  final String id;
  final String name;
  final String address;
  final String description;
  final String businessHours;
  final String photoUrl;
  late List<Map<String, dynamic>> menuItems;
  double? distance;

  SearchDetails({
    required this.id,
    required this.name,
    required this.address,
    required this.description,
    required this.businessHours,
    required this.photoUrl,
    required this.menuItems,
    this.distance,
  });

  factory SearchDetails.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return SearchDetails(
      id: doc.id,
      name: data['restaurantName'],
      address: data['location'],
      description: data['description'],
      businessHours: data['businessHours'],
      photoUrl: data['photoUrl'],
      menuItems: [], // Initialize as an empty list
    );
  }
}

class _SearchState extends State<search> {
  final CollectionReference _collectionRef =
      FirebaseFirestore.instance.collection('restaurants');
  List<SearchDetails> allItems = [];
  List<SearchDetails> filteredItems = [];
  String? _locationKeyword;
  String? _searchKeyword;
  String? _currentAddress;
  Position? _currentPosition;

  @override
  void initState() {
    super.initState();
    _fetchAllItems();
    _fetchUserLocationFromDatabase();
  }

  Future<void> _fetchAllItems() async {
    try {
      QuerySnapshot querySnapshot =
          await _collectionRef.where('isDeleted', isEqualTo: false).get();
      List<SearchDetails> results = querySnapshot.docs
          .map((doc) => SearchDetails.fromFirestore(doc))
          .toList();

      // Fetch menu items for each restaurant
      for (var item in results) {
        QuerySnapshot menuSnapshot =
            await _collectionRef.doc(item.id).collection('menus').get();
        item.menuItems = menuSnapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      }

      if (mounted) {
        setState(() {
          allItems = results;
          filteredItems = results;
          _calculateDistances();
        });
      }
    } catch (e) {
      print('Error fetching data: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('데이터를 불러오는 중 오류가 발생했습니다.')),
        );
      }
    }
  }

  Future<void> _fetchUserLocationFromDatabase() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (userDoc.exists) {
        final userData = userDoc.data() as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            _currentAddress = userData['location'];
          });
        }
        _calculateDistances();
      }
    }
  }

  Future<void> _calculateDistances() async {
    if (_currentAddress == null) return;

    for (var item in allItems) {
      List<Location> locations = await locationFromAddress(item.address);
      if (locations.isNotEmpty) {
        List<Location> userLocations =
            await locationFromAddress(_currentAddress!);
        if (userLocations.isNotEmpty) {
          double distanceInMeters = Geolocator.distanceBetween(
            userLocations[0].latitude,
            userLocations[0].longitude,
            locations[0].latitude,
            locations[0].longitude,
          );
          item.distance = distanceInMeters / 1000; // Convert to kilometers
        }
      }
    }

    _filterItems();
  }

  void _filterItems() async {
    List<SearchDetails> results = allItems;

    if (_searchKeyword != null && _searchKeyword!.isNotEmpty) {
      results = results.where((item) {
        final containsInMenu = item.menuItems.any((menuItem) =>
            menuItem['menuName']
                .toString()
                .toLowerCase()
                .contains(_searchKeyword!.toLowerCase()));
        return item.name
                .toLowerCase()
                .contains(_searchKeyword!.toLowerCase()) ||
            item.description
                .toLowerCase()
                .contains(_searchKeyword!.toLowerCase()) ||
            containsInMenu;
      }).toList();
    }

    if (_locationKeyword != null && _locationKeyword!.isNotEmpty) {
      results = results.where((item) {
        return item.address
            .toLowerCase()
            .contains(_locationKeyword!.toLowerCase());
      }).toList();
    } else if (_currentAddress != null) {
      results = results.where((item) => item.distance != null).toList()
        ..sort((a, b) => (a.distance ?? double.infinity)
            .compareTo(b.distance ?? double.infinity));
    }

    if (mounted) {
      setState(() {
        filteredItems = results;
      });
    }
  }

  void _updateLocation(String location) {
    _locationKeyword = location;
    _filterItems();
  }

  void _updateSearch(String search) {
    _searchKeyword = search;
    _filterItems();
  }

  Future<void> _toggleFavorite(SearchDetails item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userFavoritesRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites');

      final favoriteDoc = userFavoritesRef.doc(item.id);

      final favoriteSnapshot = await favoriteDoc.get();

      if (favoriteSnapshot.exists) {
        await favoriteDoc.delete();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('즐겨찾기가 해제되었습니다.')),
        );
      } else {
        await favoriteDoc.set({
          'restaurantId': item.id,
          'name': item.name,
          'address': item.address,
          'description': item.description,
          'businessHours': item.businessHours,
          'photoUrl': item.photoUrl,
          'userId': user.uid,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('즐겨찾기에 추가되었습니다.')),
        );
      }

      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<bool> _isFavorite(SearchDetails item) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final favoriteSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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
        toolbarHeight: 70,
        title: Text(
          '검색',
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
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                height: 30,
                child: Icon(Icons.location_on),
              ),
              Container(
                width: 200,
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            MapPage(previousPage: 'UserSearch'),
                      ),
                    );
                  },
                  child: Text(
                    '현재위치설정',
                    style: TextStyle(
                      color: Colors.black,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ]),
            if (_currentAddress != null)
              Padding(
                padding: const EdgeInsets.only(left: 20.0),
                child: Text(
                  '$_currentAddress',
                  style: TextStyle(
                    color: Colors.black,
                  ),
                ),
              ),
            SizedBox(height: 20),
            TextField(
              onChanged: (value) => _updateSearch(value),
              decoration: InputDecoration(
                hintText: "음식점 검색",
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
            Expanded(
              child: filteredItems.isEmpty
                  ? Center(child: Text('해당하는 음식점 또는 메뉴가 존재하지 않습니다'))
                  : ListView.builder(
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

                            return Card(
                              color: Color(0xFFBBDEFB),
                              margin: EdgeInsets.symmetric(vertical: 10),
                              child: ListTile(
                                leading: Image.network(
                                  item.photoUrl,
                                  width: 80,
                                  height: 150,
                                  fit: BoxFit.cover,
                                ),
                                title: Text(
                                  item.name,
                                  style: TextStyle(
                                    color: Color(0xFF1C1C21),
                                    fontSize: 17,
                                    fontFamily: 'Epilogue',
                                    fontWeight: FontWeight.w700,
                                    height: 2,
                                    letterSpacing: -0.27,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(
                                            text: "주소: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(text: '${item.address}'),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    RichText(
                                      text: TextSpan(
                                        style: TextStyle(color: Colors.black),
                                        children: [
                                          TextSpan(
                                            text: "메뉴: ",
                                            style: TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          TextSpan(
                                              text:
                                                  '${item.menuItems.map((menuItem) => menuItem['menuName']).join(', ')}'),
                                        ],
                                      ),
                                    ),
                                    SizedBox(height: 5),
                                    if (item.distance != null)
                                      RichText(
                                        text: TextSpan(
                                          style: TextStyle(color: Colors.black),
                                          children: [
                                            TextSpan(
                                              text: "나와의 거리: ",
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            TextSpan(
                                                text:
                                                    '${item.distance!.toStringAsFixed(2)} km'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                trailing: IconButton(
                                  icon: Icon(
                                    isFavorite ? Icons.star : Icons.star_border,
                                    color: isFavorite ? Colors.yellow : null,
                                  ),
                                  onPressed: () => _toggleFavorite(item),
                                ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/restaurantInfo',
                                    arguments: item.id, // Pass the ID
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: reservationBottom(),
    );
  }
}
