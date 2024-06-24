import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:newsapp/app/modules/Details/views/details_view.dart';
import 'package:newsapp/app/modules/googleVision/views/google_vision_view.dart';
import 'package:newsapp/app/utils/contants.dart';
import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  HomeView({super.key});

  final HomeController _controller = Get.put(HomeController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          IconButton(
              onPressed: () {
                Get.to(() => QRScannerOverlay());
              },
              icon: const Icon(
                Icons.stop_circle,
                size: 50,
              ))
        ],
      ),
      body: SafeArea(
          child: Padding(
        padding: EdgeInsets.all(context.width * .025),
        child: Column(
          children: [
            Container(
              height: context.height / 3,
              decoration:
                  BoxDecoration(borderRadius: BorderRadius.circular(20)),
              child: ListView.separated(
                  separatorBuilder: (context, index) => SizedBox(
                        width: context.width * 0.05,
                      ),
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) => GestureDetector(
                        onTap: () {
                          _controller.getNewsByCategory(index: index);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Container(
                                width: context.width / 1.25,
                                height: context.height / 4,
                                decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: const BorderRadius.all(
                                        Radius.circular(25)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: Colors.grey[400]!,
                                          blurRadius: 17,
                                          spreadRadius: 1,
                                          offset: const Offset(5, 5)),
                                      const BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 17,
                                          spreadRadius: 1,
                                          offset: Offset(-5, -5))
                                    ]),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 25),
                                      child: Text(
                                        _controller.nameOfCategories[index]
                                            .toUpperCase(),
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontWeight: FontWeight.bold,
                                            fontSize: 22),
                                      ),
                                    ),
                                    Text(
                                      'Click here to load news',
                                      style: TextStyle(
                                          color: Colors.grey[400],
                                          fontWeight: FontWeight.bold,
                                          fontSize: 22),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                  itemCount: _controller.nameOfCategories.length),
            ),
            // SizedBox(height: context.height * 0.025),
            GetBuilder<HomeController>(
              builder: (controller) {
                return Expanded(
                  child: Center(
                    child: _controller.isLoading
                        ? const CircularProgressIndicator()
                        : _controller.listOfNews.isEmpty
                            ? const Text(
                                "Please select a category from above",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold),
                              )
                            : ListView.separated(
                                separatorBuilder: (context, index) => SizedBox(
                                      width: context.height * 0.025,
                                    ),
                                itemBuilder: (context, index) => Padding(
                                      padding: const EdgeInsets.all(10),
                                      child: GestureDetector(
                                        onTap: () {
                                          Get.to(() => DetailsView(
                                              news: _controller
                                                  .listOfNews[index]));
                                        },
                                        child: Container(
                                          width: context.width / 1.125,
                                          height: context.height / 6,
                                          decoration: BoxDecoration(
                                              color: Colors.white,
                                              borderRadius:
                                                  const BorderRadius.all(
                                                      Radius.circular(25)),
                                              boxShadow: [
                                                BoxShadow(
                                                    color: Colors.grey[400]!,
                                                    blurRadius: 17,
                                                    spreadRadius: 1,
                                                    offset: const Offset(5, 5)),
                                                const BoxShadow(
                                                    color: Colors.white,
                                                    blurRadius: 17,
                                                    spreadRadius: 1,
                                                    offset: Offset(-5, -5))
                                              ]),
                                          child: Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceAround,
                                            children: [
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceEvenly,
                                                children: [
                                                  Image.network(
                                                    _controller
                                                            .listOfNews[index]
                                                            .urlToImage ??
                                                        dummyImage,
                                                    width: context.width * 0.25,
                                                    height:
                                                        context.height * 0.1,
                                                  ),
                                                  SizedBox(
                                                    width: context.width / 1.75,
                                                    child: Text(
                                                      _controller
                                                              .listOfNews[index]
                                                              .title ??
                                                          "".toUpperCase(),
                                                      maxLines: 3,
                                                      style: TextStyle(
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          color:
                                                              Colors.grey[600],
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          fontSize: 22),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                itemCount: _controller.listOfNews.length),
                  ),
                );
              },
            )
          ],
        ),
      )),
    );
  }
}
