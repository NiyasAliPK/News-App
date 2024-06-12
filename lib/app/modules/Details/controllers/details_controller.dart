import 'dart:developer';

import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';

class DetailsController extends GetxController {
  gotoUrl({required String url}) async {
    try {
      await launchUrl(Uri.parse(url));
    } catch (e) {
      log("Failed to launch url >>>>$e");
      Get.showSnackbar(const GetSnackBar(
        message: "Failed to launch the url.",
        duration: Duration(seconds: 3),
      ));
    }
  }
}
