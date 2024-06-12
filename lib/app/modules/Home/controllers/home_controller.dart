import 'dart:developer';

import 'package:get/get.dart';
import 'package:newsapp/app/repository/apis.dart';
import 'package:newsapp/app/repository/response.dart';

class HomeController extends GetxController {
  final List<String> nameOfCategories = [
    'business',
    'entertainment',
    'general',
    'health',
    'science',
    'sports',
    'technology'
  ];

  List<Article> listOfNews = [];
  bool isLoading = false;

  getNewsByCategory({required int index}) async {
    isLoading = true;
    update();
    final response =
        await MyApi().getNewsByCategory(category: nameOfCategories[index]);
    if (response != null) {
      final data = CategoryNewsResponse.fromJson(response);
      if (data.status == "ok" && data.articles != null) {
        listOfNews.clear();
        listOfNews.addAll(data.articles!);
      } else {
        listOfNews.clear();
      }
    }
    isLoading = false;
    update();
  }
}
