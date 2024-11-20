import 'package:autonomy_flutter/view/au_toggle.dart';
import 'package:feralfile_app_theme/extensions/theme_extension.dart';
import 'package:flutter/material.dart';

class PreferenceItem extends StatelessWidget {
  final String title;
  final String description;
  final bool isEnabled;
  final ValueChanged<bool> onChanged;

  const PreferenceItem({
    required this.title,
    required this.description,
    required this.isEnabled,
    required this.onChanged,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.ppMori400Black16),
            AuToggle(
              value: isEnabled,
              onToggle: onChanged,
            ),
          ],
        ),
        const SizedBox(height: 7),
        Text(
          description,
          style: theme.textTheme.ppMori400Black14,
        ),
      ],
    );
  }
}
