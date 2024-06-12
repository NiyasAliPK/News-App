import 'package:get/get.dart';

import 'package:newsapp/app/modules/Details/bindings/details_binding.dart';
import 'package:newsapp/app/modules/Details/views/details_view.dart';
import 'package:newsapp/app/modules/Home/bindings/home_binding.dart';
import 'package:newsapp/app/modules/Home/views/home_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    // GetPage(
    //   name: _Paths.HOME,
    //   page: () => HomeView(),
    //   binding: HomeBinding(),
    // ),
    // GetPage(
    //   name: _Paths.DETAILS,
    //   page: () => DetailsView(),
    //   binding: DetailsBinding(),
    // ),
  ];
}
