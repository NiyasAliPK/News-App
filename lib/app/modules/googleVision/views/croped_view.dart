import 'dart:io';

import 'package:flutter/material.dart';

class CropImagePage extends StatefulWidget {
  final String imagePath;

  const CropImagePage(this.imagePath, {super.key});

  @override
  _CropImagePageState createState() => _CropImagePageState();
}

class _CropImagePageState extends State<CropImagePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Image')),
      body: Center(
        child: Container(
          decoration: BoxDecoration(
              image: DecorationImage(image: FileImage(File(widget.imagePath)))),
        ),
      ),
    );
  }
}
