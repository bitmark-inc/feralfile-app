import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

const List<String> pageTitles = [
  'Playlists',
  'Channels',
  'Works',
];

class HeaderWidget extends StatelessWidget {
  const HeaderWidget({
    required this.selectedIndex,
    required this.onPageChanged,
    super.key,
  });

  final int selectedIndex;
  final void Function(int) onPageChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Row(
        children: pageTitles
            .map(
              (title) => _headerButton(
                context,
                title,
                pageTitles.indexOf(title),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _headerButton(BuildContext context, String title, int index) {
    final theme = Theme.of(context);
    final isSelected = selectedIndex == index;

    return TextButton(
      onPressed: () {
        onPageChanged(index);
      },
      child: Text(
        title,
        style: isSelected
            ? theme.textTheme.ppMori400White12
            : theme.textTheme.ppMori400Grey12,
      ),
    );
  }
}
