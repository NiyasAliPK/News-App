import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:newsapp/app/modules/googleVision/views/croped_view.dart';
import 'package:image/image.dart' as img;

class GoogleVisionController extends GetxController {
  @override
  void onInit() {
    initCamera();
    super.onInit();
  }

  @override
  void dispose() {
    cameraController!.dispose();
    super.dispose();
  }

  RxString data = ''.obs;
  CameraController? cameraController;

  bool isProcessing = true;
  List<String> capturedImagePath = [];

//FUNTIONS FOR CAMERA AND IMAGE START//
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
      Get.to(() => CropImagePage(croped));
      getData(path: croped);
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

    // Calculate the new height (60% of the original image height)
    final int cropHeight = (originalImage.height * 0.50).toInt();

    // Calculate the y-coordinate to start cropping from (40% from the top)
    final int cropY = (originalImage.height * 0.40).toInt();

    // Crop the image from the specified y-coordinate down to the bottom
    final img.Image croppedImage = img.copyCrop(
        originalImage,
        0, // x-coordinate (start from the left)
        cropY, // y-coordinate (start 40% from the top)
        originalImage.width, // full width of the original image
        cropHeight // calculated height (60% of the original height)
        );

    // Save the cropped image
    final String croppedFilePath = '$filePath-cropped.jpg';
    final File croppedFile = File(croppedFilePath)
      ..writeAsBytesSync(img.encodeJpg(croppedImage));

    log('Cropped image saved to $croppedFilePath');
    return croppedFilePath;
  }

//FUNTIONS FOR CAMERA AND IMAGE END//

//FOR GETTING THE DATA FROM THE DOCUMENT
  getData({required String path}) async {
    //should have a param for document type
    try {
      isProcessing = true;
      update();
      final bytes = await File(path).readAsBytes();
      final base64Image = base64Encode(bytes);
      // final bytes = await File(capturedImagePath.first).readAsBytes();
      // final base64Image = base64Encode(bytes);

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
        // should call appropriate function according to the document passed
        final data = jsonDecode(jsonEncode(response.data));
        final fullTextAnnotation = data['responses'][0]['fullTextAnnotation'];
        // log(fullTextAnnotation['text']);
        // extractDataFromCombodianNationalId(text: fullTextAnnotation['text']);
        // GROUP AND BLOCK SYSTEM CODE
        if (fullTextAnnotation != null) {
          var groupOfBlocks = groupBlocks(
              fullTextAnnotation); //NAME AND ADDRESS FOR COMBODIAN PASSPORTS
          extractingNameFromCombodianPassport(groupOfBlocks.first);
          extractAddressFromTheCombodianPassport(groupOfBlocks.last);

          // log(groupOfBlocks.toString());
        }
        // PassportData passportData =
        //     PassportData.fromText(fullTextAnnotation['text']);

        // // // Print extracted data
        // print('Surname: ${passportData.surname}');
        // print('Given Names: ${passportData.givenNames}');
        // print('Nationality: ${passportData.nationality}');
        // print(
        //     'Date of Birth: ${formatDateStringFromMRZdate(passportData.dateOfBirth)}');
        // print('Gender: ${passportData.gender}');
        // print('Document Number: ${passportData.documentNumber}');
        // print('Issuing Country: ${passportData.issuingCountry}');
        // // print(
        // //     'Date of Issue: ${formatDateStringFromMRZdate(passportData.dateOfIssue)}');
        // print(
        //     'Expiry Date: ${formatDateStringFromMRZdate(passportData.expiryDate)}');
        // print('Optional Data: ${passportData.optionalData}');
        // }
        isProcessing = false;
        update();
      } else {
        print('Error: ${response.statusCode}');
      }
    } catch (e) {
      log("Google vision api failed >>> $e");
    }
  }

  extractingNameFromCombodianPassport(List<String> inputList) {
    final khmerRegex = RegExp(r'^[\u1780-\u17FF\s]+$');
    log("Before removal >>> $inputList");
    inputList.removeWhere(
      (element) => !khmerRegex.hasMatch(element),
    );
    log("Name >>>> ${inputList.toString()}");
  }

  extractAddressFromTheCombodianPassport(List<String> inputList) {
    final khmerRegex = RegExp(r'[\u1780-\u17FF]');
    log("Before removal >>> $inputList");
    inputList.removeWhere((element) => !element.contains('/'));
    log("Address>>>>$inputList");
  }

  // containsKhmer(String text) {
  //   final khmerRegex = RegExp(r'[\u1780-\u17FF]');
  //   log(" $text>>>>${khmerRegex.hasMatch(text)}");
  // }

//FUNTIONS FOR EXTRACTING DATA FROM COMBODIAN NATIONAL ID CARD START//

  extractDataFromCombodianNationalId({required String text}) {
    // Print extracted data
    print("Name in khmer: ${extractNameFromCombodianNationalId(text: text)}");
    print(
        'Address in khmer: ${extractAddressFromCombodianNationalId(text: text)}');
    MRZDataModelForCombodianNationalId? result =
        extractMRZDataFromCombodianNationalId(text);
    if (result != null) {
      log(result.toString());
    } else {
      print('No match found or invalid MRZ format.');
    }
  }

  String extractAddressFromCombodianNationalId({required String text}) {
    try {
      String addressKey = "អាសយដ្ឋាន:";
      String addressKey2 = "អាសយដ្ឋាន";

      int startIndex = text.contains(addressKey)
          ? text.indexOf(addressKey)
          : text.indexOf(addressKey2);
      if (startIndex != -1) {
        startIndex += addressKey.length;
        String addressPart = text.substring(startIndex).trim();

        // Find the next keyword or end of text to determine the end of the address
        List<String> stopKeywords = [
          "ទីកន្លែងកំណើត:",
          "សុពលភាព:",
          "សុពលភាព",
          "IDKHM"
        ];
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
    } catch (e) {
      log("Failed to find address");
      return 'Not found';
    }
  }

  extractNameFromCombodianNationalId({required String text}) {
    try {
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
    } catch (e) {
      log("Failed to find name");
    }
  }

  String formatDateStringFromMRZdate(String dateStr) {
    try {
      // Date format in MRZ is YYMMDD
      String year = dateStr.substring(0, 2);
      String month = dateStr.substring(2, 4);
      String day = dateStr.substring(4, 6);

      // Determine the century
      int yearInt = int.parse(year);
      String fullYear = (yearInt >= 50 ? '19' : '20') + year;

      // Return the date in DD-MM-YYYY format
      return '$day-$month-$fullYear';
    } catch (e) {
      log("Failed to format the date");
      return '';
    }
  }

  MRZDataModelForCombodianNationalId? extractMRZDataFromCombodianNationalId(
      String text) {
    // Define the start keyword
    String startKeyword = 'IDKHM';

    // Find the start position of the keyword
    int startIndex = text.indexOf(startKeyword);

    // If the keyword is not found, return null
    if (startIndex == -1) {
      return null;
    }

    // Extract the substring starting from the keyword
    String extractedSection = text.substring(startIndex);

    // Split the extracted section into lines
    List<String> lines =
        extractedSection.split('\n').map((line) => line.trim()).toList();

    // Ensure there are at least 3 lines
    if (lines.length < 3) {
      return null;
    }

    // Extract data from the lines
    String firstLine = lines[0];
    String secondLine = lines[1];
    String thirdLine = lines[2];

    // Document Type and Country Code
    String documentType = firstLine.substring(0, 2);
    String countryCode = firstLine.substring(2, 5);
    String documentNumber = firstLine.substring(5).replaceAll('<', '').trim();

    // Date of Birth, Gender, Expiry Date
    String dateOfBirth =
        formatDateStringFromMRZdate(secondLine.substring(0, 6)); // YYMMDD
    String gender = secondLine.substring(7, 8);
    String expiryDate =
        formatDateStringFromMRZdate(secondLine.substring(8, 14)); // YYMMDD

    // Last Name and First Name
    List<String> names = thirdLine.split('<<');
    String lastName = names[0].replaceAll('<', '').trim();
    String firstName = names[1].replaceAll('<', '').trim();

    return MRZDataModelForCombodianNationalId(
      documentType: documentType,
      countryCode: countryCode,
      documentNumber: documentNumber,
      dateOfBirth: dateOfBirth,
      gender: gender,
      expiryDate: expiryDate,
      lastName: lastName,
      firstName: firstName,
    );
  }
//FUNTIONS FOR EXTRACTING DATA FROM COMBODIAN NATIONAL ID CARD END//

//TRIAL FOR COMBODIAN PASSPORT STARTS FROM HERE//
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

class MRZDataModelForCombodianNationalId {
  final String documentType;
  final String countryCode;
  final String documentNumber;
  final String dateOfBirth;
  final String gender;
  final String expiryDate;
  final String lastName;
  final String firstName;

  MRZDataModelForCombodianNationalId({
    required this.documentType,
    required this.countryCode,
    required this.documentNumber,
    required this.dateOfBirth,
    required this.gender,
    required this.expiryDate,
    required this.lastName,
    required this.firstName,
  });

  @override
  String toString() {
    return 'Document Type: $documentType\n'
        'Country Code: $countryCode\n'
        'Document Number: $documentNumber\n'
        'Date of Birth: $dateOfBirth\n'
        'Gender: $gender\n'
        'Expiry Date: $expiryDate\n'
        'Last Name: $lastName\n'
        'First Name: $firstName';
  }
}

class PassportData {
  String type;
  String issuingCountry;
  String surname;
  String givenNames;
  String documentNumber;
  String nationality;
  String dateOfBirth;
  String gender;
  String expiryDate;

  String optionalData;

  PassportData({
    required this.type,
    required this.issuingCountry,
    required this.surname,
    required this.givenNames,
    required this.documentNumber,
    required this.nationality,
    required this.dateOfBirth,
    required this.gender,
    required this.expiryDate,
    required this.optionalData,
  });

  factory PassportData.fromText(String text) {
    try {
      // Find the section containing potential MRZ data

      final splittedText = text.split('\n');

      // Assuming the first match contains the MRZ data
      String mrzText =
          splittedText[splittedText.length - 2] + splittedText.last;

      // Extracting information from the MRZ lines
      String firstLine = mrzText.substring(0, 44);
      String secondLine = mrzText.substring(44, 88);

      // Parsing first line
      String type = firstLine.substring(0, 2); // Document type
      String issuingCountry = firstLine.substring(2, 5); // Issuing country code
      String surname =
          firstLine.substring(5, 14).replaceAll('<', ' '); // Surname
      String givenNames =
          firstLine.substring(14, 29).replaceAll('<', ' '); // Given names

      // Parsing second line
      String documentNumber = secondLine.substring(0, 9); // Document number
      String nationality = secondLine.substring(10, 13); // Nationality code
      String dateOfBirth = secondLine.substring(13, 19); // Date of birth
      String gender = secondLine.substring(20, 21); // Gender
      String expiryDate = secondLine.substring(21, 27); // Expiry date
      String dateOfIssue = secondLine.substring(28, 34); // Date of issue
      String optionalData = secondLine.substring(34, 44); // Optional data

      // Return PassportData object with extracted information
      return PassportData(
        type: type,
        issuingCountry: issuingCountry,
        surname: surname,
        givenNames: givenNames,
        documentNumber: documentNumber,
        nationality: nationality,
        dateOfBirth: dateOfBirth,
        gender: gender,
        expiryDate: expiryDate,
        optionalData: optionalData,
      );
    } catch (e) {
      log('Failed to parse the passport data');
      return PassportData(
          type: '',
          issuingCountry: '',
          surname: '',
          givenNames: '',
          documentNumber: '',
          nationality: '',
          dateOfBirth: '',
          gender: '',
          expiryDate: '',
          optionalData: '');
    }
  }
}
