import 'package:get/get.dart';
import 'package:user_app/app/modules/trip/controllers/trip_controller.dart';

class TripBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<TripController>(
      () => TripController(),
    );
  }
}
