import 'package:get/get.dart';

/// Base interface for controllers with common reactive state
abstract class BaseInterfaceController {
  /// Reactive loading state
  RxBool get isLoading;

  /// Reactive error message
  RxnString get error;
}

/// Base controller class that provides common reactive state
/// Controllers can extend this to inherit isLoading and error
abstract class BaseController extends GetxController
    implements BaseInterfaceController {
  /// Reactive loading state
  @override
  final RxBool isLoading = false.obs;

  /// Reactive error message
  @override
  final RxnString error = RxnString();
}
