import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';
import 'package:newsapp/app/modules/googleVision/views/croped_view.dart';
import 'package:image/image.dart' as img;

class GoogleVisionController extends GetxController {
  @override
  void onInit() {
    initCamera();
    super.onInit();
  }

  RxString data = ''.obs;
  CameraController? cameraController;

  bool isProcessing = true;
  List<String> capturedImagePath = [];

  Future<void> captureImage() async {
    if (cameraController!.value.isTakingPicture) {
      log('Camera is already in use');
      return;
    }
    if (capturedImagePath.length == 2) {
      log("Both images captured");
      return;
    }
    try {
      isProcessing = true;
      update();
      var image = await cameraController!.takePicture();
      var croped = await cropImage(image.path);
      capturedImagePath.add(croped);
      isProcessing = false;
      update();
    } catch (e) {
      print('Error capturing image: $e');
    }
  }

  Future<void> initCamera() async {
    final cameras = await availableCameras();
    cameraController = CameraController(cameras[0], ResolutionPreset.max);
    await cameraController?.initialize();
    isProcessing = false;
    update();
  }

  Future<String> cropImage(String filePath) async {
    final File imageFile = File(filePath);
    final img.Image originalImage =
        img.decodeImage(await imageFile.readAsBytes())!;

    // Calculate the new height (65% of the original image height)
    final int cropHeight = (originalImage.height * 0.60).toInt();

    // Calculate the y-coordinate to start cropping from (35% from the top)
    final int cropY = (originalImage.height * 0.40).toInt();

    // Crop the image from the specified y-coordinate down to the bottom
    final img.Image croppedImage = img.copyCrop(
        originalImage,
        0, // x-coordinate (start from the left)
        cropY, // y-coordinate (start 35% from the top)
        originalImage.width, // full width of the original image
        cropHeight // calculated height (65% of the original height)
        );

    // Save the cropped image
    final String croppedFilePath = '$filePath-cropped.jpg';
    final File croppedFile = File(croppedFilePath)
      ..writeAsBytesSync(img.encodeJpg(croppedImage));

    log('Cropped image saved to $croppedFilePath');
    return croppedFilePath;
  }

  getData() async {
    try {
      final bytes = await File(capturedImagePath.first).readAsBytes();
      final base64Image = base64Encode(bytes);

      const apiKey = 'AIzaSyB3JBAHr5-k3ALVhMSZL878HIS5HiszeBA';
      const apiUrl =
          'https://vision.googleapis.com/v1/images:annotate?key=$apiKey';

      final response = await Dio().post(
        apiUrl,
        options: Options(headers: {'Content-Type': 'application/json'}),
        data: jsonEncode({
          'requests': [
            {
              'image': {'content': base64Image},
              'features': [
                {'type': 'TEXT_DETECTION'}
              ]
            }
          ]
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(jsonEncode(response.data));
        final fullTextAnnotation = data['responses'][0]['fullTextAnnotation'];
        log(fullTextAnnotation['text']);
        findingDataFromNationalId(text: fullTextAnnotation['text']);
        // GROUP AND BLOCK SYSTEM CODE
        // if (fullTextAnnotation != null) {
        //   List<List<String>> groupedBlocks = groupBlocks(fullTextAnnotation);
        //   for (int i = 0; i < groupedBlocks.length; i++) {
        //     print('Group ${i + 1}:');
        //     for (int j = 0; j < groupedBlocks[i].length; j++) {
        //       log('  block no ${j + 1}: ${groupedBlocks[i][j]}');
        //     }
        //   }
        // }
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      log("Google vision api failed >>> $e");
    }
  }

  findingDataFromNationalId({required String text}) {
    RegExp issueDateRegex = RegExp(r"សុពលភាព:\s*([០-៩./]+)");
    RegExp expiryDateRegex = RegExp(r"ដល់ថ្ងៃ\s*([០-៩./]+)");
    RegExp idNumberRegex = RegExp(r"IDKHM(\d+)");
    String issueDate = issueDateRegex.firstMatch(text)?.group(1) ?? "Not found";
    String expiryDate =
        expiryDateRegex.firstMatch(text)?.group(1) ?? "Not found";
    String idNumber = idNumberRegex.firstMatch(text)?.group(1) ?? "Not found";

    // Print extracted data
    print("Name: ${findNameFromNationalId(text: text)}");
    print("Date of Birth: ${extractDateOfBirth(text: text)}");
    print("Gender: ${findGenderFromNationalId(text: text)}");
    print("Date of Issue: $issueDate");
    print("Date of Expiry: $expiryDate");
    print("ID Number: $idNumber");
    print('Address ${extractAddress(text: text)}');
  }

  String findGenderFromNationalId({required String text}) {
    // Assuming there is only two genders (as per research) checking for male and female words in the text
    if (text.contains("ប្រុស")) {
      return 'ប្រុស';
    } else if (text.contains("ស្រី")) {
      return 'ស្រី';
    } else {
      return ''; // not found
    }
  }

  String extractAddress({required String text}) {
    String addressKey = "អាសយដ្ឋាន:";
    String addressKey2 = "អាសយដ្ឋាន";

    int startIndex = text.contains(addressKey)
        ? text.indexOf(addressKey)
        : text.indexOf(addressKey2);
    if (startIndex != -1) {
      startIndex += addressKey.length;
      String addressPart = text.substring(startIndex).trim();

      // Find the next keyword or end of text to determine the end of the address
      List<String> stopKeywords = ["ទីកន្លែងកំណើត:", "សុពលភាព:", "IDKHM"];
      int endIndex = text.length;
      for (String keyword in stopKeywords) {
        int keywordIndex = addressPart.indexOf(keyword);
        if (keywordIndex != -1 && keywordIndex < endIndex) {
          endIndex = keywordIndex;
        }
      }

      // Extract the address substring
      addressPart = addressPart.substring(0, endIndex).trim();
      return addressPart;
    }
    return "Not found";
  }

  String extractDateOfBirth({required String text}) {
    String dobKey = "ថ្ងៃខែឆ្នាំកំណើត:";
    String dobKey2 = "ថ្ងៃខែឆ្នាំកំណើត";

    int startIndex =
        !text.contains(dobKey) ? text.indexOf(dobKey2) : text.indexOf(dobKey);
    if (startIndex != -1) {
      var subs = text
          .substring(startIndex, startIndex + 35)
          .replaceAll(RegExp(r'[^០-៩,./]'), '');
      return subs;
    }
    return "Not found";
  }

  findNameFromNationalId({required String text}) {
    int startIndex = text.indexOf("គោត្តនាមនិងនាម") + "គោត្តនាមនិងនាម".length;
    int endIndex = text.indexOf("ថ្ងៃខែឆ្នាំកំណើត");

    // Extract the name substring
    String nameSection = text.substring(startIndex, endIndex).trim();

    // The name is the first line of the name section
    // Find the position of the last colon and get the substring after it
    int colonIndex = nameSection.lastIndexOf(":");
    if (colonIndex != -1) {
      nameSection = nameSection.substring(colonIndex + 1);
    }

    // Regular expression to match and remove English letters, digits, and symbols
    RegExp nonKhmerRegex =
        RegExp(r"[a-zA-Z0-9\[\]{}()<>!@#\$%^&*_\-+=|\\:;\\'<>,.?/~`]");

    // Replace all non-Khmer characters with an empty string
    return nameSection.replaceAll(nonKhmerRegex, "").trim();
  }

  List<List<String>> groupBlocks(Map<String, dynamic> fullTextAnnotation) {
    List<List<String>> groupedBlocks = [];
    List<dynamic> blocks = [];

    for (var page in fullTextAnnotation['pages']) {
      for (var block in page['blocks']) {
        blocks.add(block);
      }
    }

    blocks.sort((a, b) => getMinY(a).compareTo(getMinY(b)));

    int i = 0;
    while (i < blocks.length) {
      double minY = getMinY(blocks[i]);
      double maxY = getMaxY(blocks[i]);
      List<String> currentGroup = [getBlockText(blocks[i])];
      i++;
      while (i < blocks.length && getMinY(blocks[i]) <= maxY) {
        currentGroup.add(getBlockText(blocks[i]));
        i++;
      }
      groupedBlocks.add(currentGroup);
    }

    return groupedBlocks;
  }

  double getMinY(Map<String, dynamic> block) {
    final vertices = block['boundingBox']['vertices'];
    return vertices
        .map((v) => (v['y'] ?? 0).toDouble())
        .reduce((a, b) => a < b ? a : b);
  }

  double getMaxY(Map<String, dynamic> block) {
    final vertices = block['boundingBox']['vertices'];
    return vertices
        .map((v) => (v['y'] ?? 0).toDouble())
        .reduce((a, b) => a > b ? a : b);
  }

  String getBlockText(Map<String, dynamic> block) {
    StringBuffer blockText = StringBuffer();
    for (var paragraph in block['paragraphs']) {
      for (var word in paragraph['words']) {
        for (var symbol in word['symbols']) {
          blockText.write(symbol['text']);
        }
        blockText.write(' '); // Space between words
      }
      blockText.write('\n'); // New line after each paragraph
    }
    return blockText.toString().trim();
  }
}
