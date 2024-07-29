import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'UserBottom.dart';
import 'UserSearch.dart';
import 'notification.dart';

class home extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70.0),
        child: AppBar(
          backgroundColor: Colors.white,
          toolbarHeight: 80,
          automaticallyImplyLeading: false,
          title: Text(
            'waitez',
            style: TextStyle(
              color: Color(0xFF1C1C21),
              fontSize: 18,
              fontFamily: 'Epilogue',
              fontWeight: FontWeight.w700,
              height: 0.07,
              letterSpacing: -0.27,
            ),
          ), // 타이틀
          centerTitle: true, // 타이틀 텍스트를 가운데로 정렬 시킴
          actions: [
            // 우측의 액션 버튼들
            IconButton(onPressed: () {}, icon: Icon(Icons.refresh)),
            IconButton(
                onPressed: () {
                  Navigator.pushNamed(context, '/noti');
                },
                icon: Icon(Icons.notifications))
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                SizedBox(height: 10),
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(context, '/search');
                  },
                  child: Container(
                    width: screenWidth * 0.9,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: ShapeDecoration(
                      color: Color(0xFFEDEFF2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.search),
                        SizedBox(width: 12),
                        Text(
                          '검색',
                          style: TextStyle(
                            color: Color(0xFF3D3F49),
                            fontSize: 16,
                            fontFamily: 'Epilogue',
                            fontWeight: FontWeight.w400,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '안녕하세요,\n이런 음식은 어떤가요?',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                AdBanner(),
                SizedBox(height: 30),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '음식점 예약하기',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        Card(
                          color: Color(0xFFFFE4C4),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.restaurant,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 20),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/search');
                                    }, 
                                    child: Text('예약하기')),
                                Text(
                                  'reservation',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          color: Color(0xFF87CEFA),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.article,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/waitingNumber');
                                    },
                                    child: Text('대기순번')
                                    ),
                                SizedBox(height: 4),
                                Text(
                                  'waiting list',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          color: Color(0xFFFFB6C1),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.view_stream,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(
                                          context, '/historyList');
                                    }, child: Text('이력조회')
                                    ),
                                SizedBox(height: 4),
                                Text(
                                  'history',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          color: Color(0xFFDFE9ED),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/favorite');
                                    }, child: Text('즐겨찾기')
                                    ),
                                SizedBox(height: 4),
                                Text(
                                  'favorite',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Card(
                          color: Color(0xFFB8D38F),
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.groups,
                                  size: 40,
                                  color: Colors.blue,
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                    onPressed: () {
                                      Navigator.pushNamed(context, '/community');
                                    }, child: Text('커뮤니티')
                                    ),
                                SizedBox(height: 4),
                                Text(
                                  'community',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: menuButtom(),
    );
  }
}

class AdBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      elevation: 4,
      child: Container(
        width: 350,
        height: 150,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15.0),
        ),
        child: Stack(
          children: [
            PageView(children: [
              Container(
                child: Text(
                  '김밥\n어떠신가요!',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  image: DecorationImage(
                    image: AssetImage('assets/images/kimbab.png'), // 배너 이미지 경로
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                child: Text(
                  '오늘은\n매콤한게 땡기지 않으신가요?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  image: DecorationImage(
                    image:
                        AssetImage('assets/images/malatang.png'), // 배너 이미지 경로
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Container(
                child: Text(
                  '다이어트\n고민중이신가요?',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15.0),
                  image: DecorationImage(
                    image: AssetImage('assets/images/salad.png'), // 배너 이미지 경로
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
