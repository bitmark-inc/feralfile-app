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
          title: 'projects'.tr(), onBack: () => Navigator.pop(context)),
      body: BlocBuilder<ProjectsBloc, ProjectsState>(
        builder: (context, state) {
          if (state.loading) {
            return Center(child: loadingIndicator());
          }
          final padding = EdgeInsets.fromLTRB(
              ResponsiveLayout.padding, 40, ResponsiveLayout.padding, 32);

          if (state.projects.isEmpty) {
            return Padding(
                padding: padding,
                child: Text('no_project_found'.tr(),
                    style: Theme.of(context).textTheme.ppMori400Black14));
          }
          return _projectsList(context, state);
        },
      ));

  Widget _projectsList(BuildContext context, ProjectsState state) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addTitleSpace(),
        ...state.projects.map((e) => TappableForwardRow(
            padding: EdgeInsets.symmetric(horizontal: ResponsiveLayout.padding),
            leftWidget: Text(
              e.title,
              style: theme.textTheme.ppMori400Black14,
            ),
            onTap: () async {
              await Navigator.of(context).pushNamed(
                e.route,
                arguments: e.arguments,
              );
            }))
      ],
    );
  }
}
