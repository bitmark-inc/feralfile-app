import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class NoEditAddressesList extends StatelessWidget {
  const NoEditAddressesList({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'no_edit_addresses'.tr(),
            style: Theme.of(context).textTheme.ppMori700Black16,
          ),
          const SizedBox(height: 8),
          Text(
            'add_edit_address'.tr(),
            style: Theme.of(context).textTheme.ppMori400Black14,
          ),
        ],
      ),
    );
  }
}
