import 'dart:developer';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class MyApi {
  MyApi._privateConsturctor();

  static final _instance = MyApi._privateConsturctor();

  factory MyApi() {
    return _instance;
  }

  final String _apiKey = '&apiKey=6256b7c18d824edbb1e5604312f5adad';
  final String _urlForNewsByCategory =
      'https://newsapi.org/v2/top-headlines?country=in&category=';

  final Dio _dio = Dio();

  Future<dynamic> getNewsByCategory({required String category}) async {
    try {
      log("API Key >>>> $_urlForNewsByCategory$category$_apiKey");
      final response =
          await _dio.get('$_urlForNewsByCategory$category$_apiKey');
      return response.data;
    } catch (e) {
      log("Something went wrong while fetching all the news >>>$e");
      return null;
    }
  }
}
