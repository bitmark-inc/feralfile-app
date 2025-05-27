import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: PrimaryButton)
Widget buildCoolButtonUseCase(BuildContext context) {
  return PrimaryButton(
    text: "Hello World!",
  );
}
