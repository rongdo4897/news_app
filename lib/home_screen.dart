import 'dart:convert';

import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'article_model.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String searchText = '';
  int currentCategory = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Ngày tháng
              Text(
                DateFormat('EEE, dd\'th\' MMMM yyyy').format(DateTime.now()),
                style: GoogleFonts.tinos(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              // Title
              Text(
                'Explore',
                style: GoogleFonts.tinos(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 24),

              // Input tìm kiếm
              Container(
                margin: const EdgeInsets.only(right: 16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                clipBehavior: Clip.antiAlias,
                child: TextFormField(
                  decoration: InputDecoration(
                    fillColor: Colors.grey.shade300,
                    filled: true,
                    border: InputBorder.none,
                    prefixIcon: const Icon(Icons.search),
                    hintText: 'Search for article',
                  ),
                  onChanged: (value) {
                    setState(
                      () {
                        searchText = value; // Cập nhật giá trị biến khi dữ liệu trong ô input thay đổi
                      },
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              // Thanh danh sách thể loại
              SizedBox(
                height: 40,
                child: CategoriesBar(onSelectCategory: (category) {
                    setState(() {
                      currentCategory = category; // Update currentCategory
                    });
                  },
                ),
              ),
              // Danh sách bài báo
              const SizedBox(height: 24),
              Expanded(child: ArticleList(searchText: searchText, currentCategory: currentCategory)),
            ],
          ),
        ),
      ),
    );
  }
}

// Định nghĩa callback cho giá trị currentCategory
typedef CategoryCallback = void Function(int);

class CategoriesBar extends StatefulWidget {
  final CategoryCallback onSelectCategory;

  const CategoriesBar({Key? key, required this.onSelectCategory})
      : super(key: key);

  @override
  State<CategoriesBar> createState() => _CategoriesBarState();
}

class _CategoriesBarState extends State<CategoriesBar> {
  List<String> categories = const [
    'All',
    'Politics',
    'Sports',
    'Health',
    'Music',
    'Tech'
  ];

  int currentCategory = 0;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: categories.length,
      itemBuilder: (context, index) {
        return GestureDetector(
          onTap: () {
            widget.onSelectCategory(index);
            setState(
              () {
                currentCategory = index; // Cập nhật giá trị biến khi dữ liệu trong ô input thay đổi
              },
            );
          },
          child: Container(
            margin: const EdgeInsets.only(right: 8.0),
            padding: const EdgeInsets.symmetric(
              // vertical: 8.0,
              horizontal: 20.0,
            ),
            decoration: BoxDecoration(
              color: currentCategory == index ? Colors.black : Colors.white,
              border: Border.all(),
              borderRadius: BorderRadius.circular(16.0),
            ),
            child: Center(
              child: Text(
                categories.elementAt(index),
                style: TextStyle(
                  color: currentCategory == index ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class ArticleList extends StatelessWidget {
  final String searchText;
  final int currentCategory;

  const ArticleList({Key? key, required this.searchText, required this.currentCategory}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getArticles(searchText, currentCategory),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.none:
          case ConnectionState.active:
          case ConnectionState.waiting:
            return const Center(
              child: CircularProgressIndicator(),
            );
          case ConnectionState.done:
            final data = snapshot.data ?? [];
            return ListView.builder(
              padding: const EdgeInsets.only(right: 16.0),
              itemCount: data.length,
              itemBuilder: (context, index) {
                return ArticleTile(
                  article: data.elementAt(index),
                );
              },
            );
        }
      },
    );
  }

  Future<List<Article>> getArticles(String searchText, int category) async {
    const url =
        'https://newsapi.org/v2/top-headlines?country=us&category=business&apiKey=b82b2d915636455c91c6d71f76d7a403';
    final res = await http.get(Uri.parse(url));

    final body = json.decode(res.body) as Map<String, dynamic>;

    List<Article> result = [];
    for (final article in body['articles']) {
      result.add(
        Article(
          title: article['title'],
          urlToImage: article['urlToImage'],
        ),
      );
    }

    // Xử lý khi lựa chọn category
    if (category != 0) {
      // Số lượng phần tử của từng cate
      int rangeCate = result.length ~/ 5;
      int startIndex = (category - 1) * rangeCate;
      int endIndex = startIndex + rangeCate;
      result = result.sublist(startIndex, endIndex);
    }

    // Xử lý cho phần search text theo dạng convert text và title về chữ thường
    if (searchText != "") {
      result = result
          .where((element) =>
              element.title.toLowerCase().contains(searchText.toLowerCase()))
          .toList();
    }

    return result;
  }
}

class ArticleTile extends StatelessWidget {
  const ArticleTile({super.key, required this.article});

  final Article article;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 128,
      margin: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.0),
            ),
            clipBehavior: Clip.antiAlias,
            child: Image.network(
              article.urlToImage ?? '',
              fit: BoxFit.cover,
              height: 128,
              width: 128,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 128,
                  width: 128,
                  color: Colors.lightBlue,
                );
              },
            ),
          ),
          // TODO: Thêm thông tin bài báo
          const Expanded(
            child: SizedBox(),
          ),
        ],
      ),
    );
  }
}
