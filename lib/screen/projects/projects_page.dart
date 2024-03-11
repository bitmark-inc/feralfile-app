import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/feralfile_artwork_preview/feralfile_artwork_preview_page.dart';
import 'package:autonomy_flutter/screen/projects/projects_bloc.dart';
import 'package:autonomy_flutter/screen/projects/projects_state.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
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
          if (state.showYokoOno) {
            return _projectsList(context, state);
          }
          return Padding(
              padding: padding,
              child: Text('no_project_found'.tr(),
                  style: Theme.of(context).textTheme.ppMori400Black14));
        },
      ));

  Widget _projectsList(BuildContext context, ProjectsState state) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addTitleSpace(),
        if (state.showYokoOno)
          TappableForwardRow(
              padding:
                  EdgeInsets.symmetric(horizontal: ResponsiveLayout.padding),
              leftWidget: Text(
                'yoko_ono_public_version'.tr(),
                style: theme.textTheme.ppMori400Black14,
              ),
              onTap: () async {
                final config = injector<RemoteConfigService>();
                final artwork = Artwork.createFake(
                    config.getConfig(ConfigGroup.exhibition,
                        ConfigKey.publicVersionThumbnail, ''),
                    config.getConfig(ConfigGroup.exhibition,
                        ConfigKey.publicVersionPreview, ''),
                    'software');
                await Navigator.of(context).pushNamed(
                  AppRouter.ffArtworkPreviewPage,
                  arguments: FeralFileArtworkPreviewPagePayload(
                    artwork: artwork,
                  ),
                );
              })
      ],
    );
  }
}
