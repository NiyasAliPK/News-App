import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:newsapp/app/modules/googleVision/controllers/google_vision_controller.dart';

class InvertedClipper extends CustomClipper<Path> {
  late Size scanArea;
  late double borderRadius;
  final double offsetY;

  InvertedClipper(
      {required this.scanArea,
      this.borderRadius = 20.0,
      required this.offsetY});

  @override
  Path getClip(Size size) {
    return Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(
          Rect.fromCenter(
              center: Offset(size.width / 2, size.height / 2 - offsetY),
              width: scanArea.width,
              height: scanArea.height),
          Radius.circular(borderRadius - 4)))
      ..fillType = PathFillType.evenOdd;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => true;
}

// ignore: must_be_immutable
class QRScannerOverlay extends StatelessWidget {
  final GoogleVisionController controller = Get.put(GoogleVisionController());

  QRScannerOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          margin: EdgeInsets.all(context.width * .025),
          child: Stack(children: [
            GetBuilder<GoogleVisionController>(
                builder: (_) => controller.isProcessing
                    ? const Center(
                        child: CircularProgressIndicator(),
                      )
                    : CameraPreview(controller.cameraController!)),
            ClipPath(
              clipper: InvertedClipper(
                  scanArea: Size(context.width - 40, context.height / 3 - 20),
                  borderRadius: 20,
                  offsetY: context.height * 0.075),
              child: const SizedBox.expand(
                child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.white)),
              ),
            ),
            Container(
              margin: EdgeInsets.only(bottom: context.height * 0.15),
              alignment: Alignment.center,
              child: CustomPaint(
                foregroundPainter: const BorderPainter(
                  borderRadius: 20,
                  borderColor: Colors.orange,
                  borderStrokeWidth: 5,
                ),
                child: SizedBox(
                  width: context.width,
                  height: context.height / 3,
                ),
              ),
            ),
            Positioned(
              // top: context.height * 0.05,
              left: context.width * 0.02,
              child: Row(
                children: [
                  SizedBox(
                    width: context.width * 0.1,
                    height: context.height * 0.0475,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey.shade200,
                        padding: EdgeInsets.only(right: context.width * 0.005),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Get.back();
                      },
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Colors.black,
                      ),
                    ),
                  ),
                  SizedBox(width: context.width * 0.05),
                  Text(
                    "Take Document Photo",
                    style: TextStyle(
                        fontSize: context.width * 0.06,
                        fontWeight: FontWeight.bold),
                  )
                ],
              ),
            ),
            Positioned(
              bottom: 0,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.only(left: context.width * 0.375),
                    child: CircleAvatar(
                      radius: context.width * 0.1,
                      backgroundColor: Colors.orange,
                      child: IconButton(
                        icon: Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: context.width * 0.08,
                        ),
                        onPressed: () {
                          controller.captureImage();
                        },
                      ),
                    ),
                  ),
                  SizedBox(height: context.height * 0.02),
                  Text(
                    'Cambodia National ID',
                    style: TextStyle(fontSize: context.width * 0.045),
                  ),
                  SizedBox(height: context.height * 0.02),
                  GetBuilder<GoogleVisionController>(builder: (_) {
                    return Row(
                      children: [
                        FrontBackImageHolder(
                          isSelected: controller.capturedImagePath.isEmpty,
                          shouldShowImage:
                              controller.capturedImagePath.isNotEmpty,
                          path: controller.capturedImagePath.isNotEmpty
                              ? controller.capturedImagePath.first
                              : '',
                          text: 'Front',
                        ),
                        SizedBox(width: context.width * .05),
                        FrontBackImageHolder(
                          isSelected: controller.capturedImagePath.isNotEmpty &&
                              controller.capturedImagePath.length == 1,
                          shouldShowImage:
                              controller.capturedImagePath.isNotEmpty &&
                                  controller.capturedImagePath.length == 2,
                          path: controller.capturedImagePath.isNotEmpty &&
                                  controller.capturedImagePath.length == 2
                              ? controller.capturedImagePath.last
                              : '',
                          text: 'Back',
                        ),
                        SizedBox(width: context.width * 0.05),
                      ],
                    );
                  }),
                  SizedBox(height: context.height * 0.02),
                  GetBuilder<GoogleVisionController>(builder: (_) {
                    return ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            controller.capturedImagePath.length == 2
                                ? Colors.orange
                                : Colors.grey,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                          horizontal: context.width / 2.5,
                          vertical: context.height * 0.02,
                        ),
                        textStyle: TextStyle(fontSize: context.width * 0.045),
                      ),
                      onPressed: controller.capturedImagePath.length == 2
                          ? () {
                              controller.getData();
                            }
                          : null,
                      child: const Text('Upload'),
                    );
                  }),
                ],
              ),
            )
          ]),
        ),
      ),
    );
  }
}

class FrontBackImageHolder extends StatelessWidget {
  final bool isSelected;
  final bool shouldShowImage;
  final String path;
  final String text;
  const FrontBackImageHolder({
    super.key,
    required this.isSelected,
    required this.shouldShowImage,
    required this.path,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            width: 2.5,
            color: isSelected || shouldShowImage
                ? Colors.orange
                : Colors.grey.shade300,
          ),
          image: shouldShowImage
              ? DecorationImage(fit: BoxFit.fill, image: FileImage(File(path)))
              : null),
      child: Center(
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.orange : Colors.grey.shade300,
          ),
        ),
      ),
    );
  }
}

// Creates the white borders
class BorderPainter extends CustomPainter {
  final double borderRadius;
  final Color borderColor;
  final double borderStrokeWidth;

  const BorderPainter({
    required this.borderRadius,
    required this.borderColor,
    required this.borderStrokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(
      borderStrokeWidth / 2,
      borderStrokeWidth / 2,
      size.width - borderStrokeWidth,
      size.height - borderStrokeWidth,
    );
    final rrect = RRect.fromRectAndRadius(rect, Radius.circular(borderRadius));

    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderStrokeWidth;

    canvas.drawRRect(rrect, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return false;
  }
}
