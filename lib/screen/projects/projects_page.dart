import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/screen/projects/projects_bloc.dart';
import 'package:autonomy_flutter/screen/projects/projects_state.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ProjectsPage extends StatefulWidget {
  const ProjectsPage({super.key});

  @override
  State<ProjectsPage> createState() => _ProjectsPageState();
}

class _ProjectsPageState extends State<ProjectsPage>
    with AfterLayoutMixin<ProjectsPage> {
  @override
  void afterFirstLayout(BuildContext context) {
    context.read<ProjectsBloc>().add(GetProjectsEvent());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: getBackAppBar(context,
          title: 'rnd'.tr(), onBack: () => Navigator.pop(context)),
      body: BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) {
          if (state.loading) {
            return Center(child: loadingIndicator());
          }
          return _projectsList(context, state);
        },
      ));

  Widget _projectsList(BuildContext context, ProjectsState state) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addTitleSpace(),
        ...state.projects.map((e) => Column(
              children: [
                TappableForwardRow(
                    padding: ResponsiveLayout.paddingAll,
                    leftWidget: Text(
                      e.title,
                      style: theme.textTheme.ppMori400Black14,
                    ),
                    onTap: () async {
                      await Navigator.of(context).pushNamed(
                        e.route,
                        arguments: e.arguments,
                      );
                    }),
                addDivider()
              ],
            ))
      ],
    );
  }
}
