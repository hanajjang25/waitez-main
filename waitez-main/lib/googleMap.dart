import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

const String GOOGLE_API_KEY = 'AIzaSyAyc3lB3ln_EvyNTaecIVEi66ZV4CCIPoc';

class MapPage extends StatefulWidget {
  final String previousPage;

  MapPage({required this.previousPage});

  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final Completer<GoogleMapController> _controller =
      Completer<GoogleMapController>();
  CameraPosition _initialPosition = CameraPosition(
    target: LatLng(37.42796133580664, -122.085749655962),
    zoom: 18.0,
  );

  String _currentAddress = "Getting location...";
  Position? _currentPosition;
  Marker? _userMarker;
  bool _isMapMoving = false;
  TextEditingController _searchController = TextEditingController();
  List<String> _suggestions = [];

  @override
  void initState() {
    super.initState();
    _requestLocationPermission();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    if (_searchController.text.isNotEmpty) {
      _getSuggestions(_searchController.text);
    } else {
      setState(() {
        _suggestions = [];
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    PermissionStatus status = await Permission.locationWhenInUse.request();

    if (status == PermissionStatus.granted) {
      _getCurrentLocation();
    } else if (status == PermissionStatus.denied) {
      _showPermissionDeniedDialog();
    } else if (status == PermissionStatus.permanentlyDenied) {
      openAppSettings();
    }
  }

  void _showPermissionDeniedDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Location Permission Denied'),
          content:
              Text('Location permissions are required to use this feature.'),
          actions: <Widget>[
            TextButton(
              child: Text('Retry'),
              onPressed: () {
                Navigator.of(context).pop();
                _requestLocationPermission();
              },
            ),
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);
      setState(() {
        _currentPosition = position;
        _initialPosition = CameraPosition(
          target: LatLng(position.latitude, position.longitude),
          zoom: 18.0,
        );
        _userMarker = Marker(
          markerId: MarkerId('userMarker'),
          position: LatLng(position.latitude, position.longitude),
          draggable: true,
          onDragEnd: (newPosition) {
            _getAddressFromLatLng(newPosition.latitude, newPosition.longitude);
          },
        );
      });

      final GoogleMapController controller = await _controller.future;
      controller
          .animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
    } catch (e) {
      print('Failed to get current location: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('현재 위치를 가져오지 못했습니다.'),
      ));
    }
  }

  Future<void> _getAddressFromLatLng(double latitude, double longitude) async {
    try {
      String address = await getPlaceAddress(lat: latitude, lng: longitude);
      setState(() {
        _currentAddress = address;
      });
    } catch (e) {
      print('Failed to get address: $e');
    }
  }

  Future<String> getPlaceAddress({double lat = 0.0, double lng = 0.0}) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?latlng=$lat,$lng&key=$GOOGLE_API_KEY&language=ko';
    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        return data['results'][0]['formatted_address'];
      } else {
        throw Exception('No results found');
      }
    } else {
      throw Exception('Failed to fetch address');
    }
  }

  Future<void> _getSuggestions(String query) async {
    final url =
        'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$GOOGLE_API_KEY&language=ko';
    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['predictions'].isNotEmpty) {
        setState(() {
          _suggestions = List<String>.from(
              data['predictions'].map((p) => p['description']));
        });
      } else {
        setState(() {
          _suggestions = [];
        });
      }
    } else {
      throw Exception('Failed to fetch suggestions');
    }
  }

  Future<void> _searchAndNavigate(String searchText) async {
    final url =
        'https://maps.googleapis.com/maps/api/geocode/json?address=$searchText&key=$GOOGLE_API_KEY&language=ko';
    http.Response response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      var data = jsonDecode(response.body);
      if (data['results'].isNotEmpty) {
        var location = data['results'][0]['geometry']['location'];
        LatLng searchedLocation = LatLng(location['lat'], location['lng']);
        setState(() {
          _initialPosition =
              CameraPosition(target: searchedLocation, zoom: 18.0);
          _userMarker = Marker(
            markerId: MarkerId('searchedLocation'),
            position: searchedLocation,
            draggable: true,
            onDragEnd: (newPosition) {
              _getAddressFromLatLng(
                  newPosition.latitude, newPosition.longitude);
            },
          );
          _suggestions = [];
          _searchController.clear();
        });

        final GoogleMapController controller = await _controller.future;
        controller
            .animateCamera(CameraUpdate.newCameraPosition(_initialPosition));
        _getAddressFromLatLng(location['lat'], location['lng']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('주소를 찾을 수 없습니다.'),
        ));
      }
    } else {
      throw Exception('Failed to search location');
    }
  }

  void _navigateToAddressPage() {
    if (_currentPosition != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AddressPage(
            address: _currentAddress,
            previousPage: widget.previousPage,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('현재 위치를 가져오지 못했습니다.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('위치'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    prefixIcon: IconButton(
                      icon: Icon(Icons.search),
                      onPressed: () {
                        _searchAndNavigate(_searchController.text);
                      },
                    ),
                    hintText: '위치 검색',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                ),
                if (_suggestions.isNotEmpty)
                  ConstrainedBox(
                    constraints: BoxConstraints(maxHeight: 200),
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _suggestions.length,
                      itemBuilder: (context, index) {
                        return ListTile(
                          title: Text(_suggestions[index]),
                          onTap: () {
                            _searchAndNavigate(_suggestions[index]);
                          },
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: GoogleMap(
              mapType: MapType.normal,
              initialCameraPosition: _initialPosition,
              onMapCreated: (GoogleMapController controller) {
                if (!_controller.isCompleted) {
                  _controller.complete(controller);
                }
              },
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              markers: _userMarker != null ? {_userMarker!} : {},
              onCameraMove: (CameraPosition position) {
                setState(() {
                  _isMapMoving = true;
                  _userMarker = _userMarker?.copyWith(
                    positionParam: position.target,
                  );
                });
              },
              onCameraIdle: () async {
                if (_isMapMoving && _userMarker != null) {
                  _isMapMoving = false;
                  await _getAddressFromLatLng(_userMarker!.position.latitude,
                      _userMarker!.position.longitude);
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                Text(
                  _currentAddress,
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8.0),
                ElevatedButton(
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.blue[50],
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(10),
                      ),
                    ),
                  ),
                  onPressed: _navigateToAddressPage,
                  child: Text(
                    '이 위치로 주소 설정',
                    style: TextStyle(
                      color: Color(0xFF1C1C21),
                      fontSize: 15,
                      fontFamily: 'Epilogue',
                      height: 0.07,
                      letterSpacing: -0.27,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class AddressPage extends StatelessWidget {
  final String address;
  final String previousPage;

  AddressPage({required this.address, required this.previousPage});

  Future<void> _updateUserLocation(String address) async {
    User? user = FirebaseAuth.instance.currentUser; // 현재 로그인된 사용자 가져오기
    if (user == null) {
      print('로그아웃되어있습니다.');
      return;
    }

    if (user.isAnonymous) {
      String uid = user.uid;

      // uid를 통해 Firestore에서 nonmember 문서 찾기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('non_members')
          .where('uid', isEqualTo: uid)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 문서가 존재하면 업데이트
        DocumentReference nonMemberDoc = querySnapshot.docs[0].reference;
        await nonMemberDoc.update({'location': address}).catchError((error) {
          print('비회원 위치 업데이트 실패 : $error');
        });
        print('비회원 위치 업데이트 성공 : $address');
      } else {
        print('회원정보를 찾을 수 없습니다.');
      }
    } else {
      String email = user.email!;

      // 이메일을 통해 Firestore에서 사용자 문서 찾기
      QuerySnapshot querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('email', isEqualTo: email)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        // 문서가 존재하면 업데이트
        DocumentReference userDoc = querySnapshot.docs[0].reference;
        await userDoc.update({'location': address}).catchError((error) {
          print('회원 위치 업데이트 실패 : $error');
        });
        print('회원 위치 업데이트 성공 : $address');
      } else {
        print('회원정보를 찾을 수 없습니다.');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    TextEditingController _detailAddressController = TextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '상세주소',
          style: TextStyle(
            color: Color(0xFF1C1C21),
            fontSize: 18,
            fontFamily: 'Epilogue',
            fontWeight: FontWeight.w700,
            height: 0.07,
            letterSpacing: -0.27,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              address,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16.0),
            TextField(
              controller: _detailAddressController,
              decoration: InputDecoration(
                labelText: '상세 주소 입력',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.blue[50],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(
                    Radius.circular(10),
                  ),
                ),
              ),
              onPressed: () async {
                String detailAddress = _detailAddressController.text;
                print('Detail Address: $detailAddress');
                String fullAddress = "$address, $detailAddress";

                // 사용자 위치를 Firestore에 업데이트
                await _updateUserLocation(fullAddress);

                // Navigate back to the previous page
                if (previousPage == 'UserSearch') {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/search', (route) => false);
                } else if (previousPage == 'RestaurantReg') {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/regRestaurant', (route) => false);
                } else if (previousPage == 'RestaurantEdit') {
                  Navigator.pushNamedAndRemoveUntil(
                      context, '/editRestaurant', (route) => false);
                }
              },
              child: Text(
                '상세 주소 저장',
                style: TextStyle(
                  color: Color(0xFF1C1C21),
                  fontSize: 15,
                  fontFamily: 'Epilogue',
                  height: 0.07,
                  letterSpacing: -0.27,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
