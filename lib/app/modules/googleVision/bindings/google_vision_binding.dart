import 'package:get/get.dart';

import '../controllers/google_vision_controller.dart';

class GoogleVisionBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<GoogleVisionController>(
      () => GoogleVisionController(),
    );
  }
}
