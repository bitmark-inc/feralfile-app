import 'package:autonomy_flutter/screen/mobile_controller/screens/home/view/home_mobile_controller.dart';
import 'package:autonomy_flutter/widgetbook/components/mock_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart';

// widgetbook component for HomePage
@UseCase(
  name: 'Home Page',
  type: MobileControllerHomePage,
)
Widget homePageComponent(BuildContext context) {
  return const MockWrapper(
    child: MobileControllerHomePage(),
  );
}
