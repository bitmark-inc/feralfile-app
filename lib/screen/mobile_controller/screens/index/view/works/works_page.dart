import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class WorksPage extends StatefulWidget {
  const WorksPage({super.key});

  @override
  State<WorksPage> createState() => _WorksPageState();
}

class _WorksPageState extends State<WorksPage>
    with AutomaticKeepAliveClientMixin {
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Center(
            child: Text(
              'Works page',
              style: theme.textTheme.ppMori400White12,
            ),
          ),
        ),
      ],
    );
  }

  @override
  bool get wantKeepAlive => true;
}
