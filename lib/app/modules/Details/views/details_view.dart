import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:newsapp/app/repository/response.dart';
import 'package:newsapp/app/utils/contants.dart';

import '../controllers/details_controller.dart';

class DetailsView extends GetView<DetailsController> {
  final DetailsController _controller = Get.put(DetailsController());
  final Article news;
  DetailsView({super.key, required this.news});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Details'),
        centerTitle: true,
      ),
      body: SafeArea(
          child: Padding(
        padding: EdgeInsets.all(context.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Image.network(news.urlToImage ?? dummyImage),
            SizedBox(height: context.height * 0.025),
            Text(
              news.title ?? "".toUpperCase(),
              style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            SizedBox(height: context.height * 0.025),
            Text(
              news.description ?? "".toUpperCase(),
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
            SizedBox(height: context.height * 0.025),
            Text(
              "Author : ${news.author ?? ""}".toUpperCase(),
              style: const TextStyle(
                  overflow: TextOverflow.ellipsis,
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 22),
            ),
            SizedBox(height: context.height * 0.05),
            news.url == null
                ? const SizedBox.shrink()
                : InkWell(
                    onTap: () {
                      _controller.gotoUrl(url: news.url!);
                    },
                    child: const Text(
                      "Click here to read the full article.",
                      style: TextStyle(
                          overflow: TextOverflow.ellipsis,
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 15),
                    ),
                  ),
          ],
        ),
      )),
    );
  }
}
