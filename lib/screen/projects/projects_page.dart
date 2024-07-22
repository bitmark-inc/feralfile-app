import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/model/project.dart';
import 'package:autonomy_flutter/screen/projects/projects_bloc.dart';
import 'package:autonomy_flutter/screen/projects/projects_state.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/ff_artwork_thumbnail_view.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/title_text.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

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
        appBar: getFFAppBar(
          context,
          title: TitleText(
            title: 'rnd'.tr(),
          ),
          centerTitle: false,
          onBack: () => Navigator.pop(context),
        ),
        extendBody: true,
        // extendBodyBehindAppBar: true,
        backgroundColor: AppColor.primaryBlack,
        body: Padding(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: CustomScrollView(
            slivers: [
              const SliverToBoxAdapter(
                child: SizedBox(
                  height: 42,
                ),
              ),
              SliverToBoxAdapter(
                child: BlocBuilder<ProjectsBloc, ProjectsState>(
                  builder: (context, state) {
                    if (state.loading) {
                      return Center(child: loadingIndicatorLight());
                    }
                    if (state.projects.isEmpty) {
                      return Center(
                        child: Text(
                          'no_project_found'.tr(),
                          style: Theme.of(context).textTheme.ppMori400White14,
                        ),
                      );
                    }
                    return _projectsList(context, state);
                  },
                ),
              ),
            ],
          ),
        ),
      );

  Widget _projectsList(BuildContext context, ProjectsState state) {
    final theme = Theme.of(context);
    return Column(
      children: [
        ...state.projects.map(
          (e) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                child: Container(
                  padding: EdgeInsets.all(ResponsiveLayout.padding * 3.5),
                  decoration: BoxDecoration(
                    color: AppColor.auGreyBackground,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: _buildProjectDelegate(context, e),
                ),
                onTap: () async => Navigator.of(context).pushNamed(
                  e.route,
                  arguments: e.arguments,
                ),
              ),
              SizedBox(height: ResponsiveLayout.padding),
              Text(
                e.title,
                style: theme.textTheme.ppMori400White14,
              ),
              addTitleSpace(),
            ],
          ),
        )
      ],
    );
  }

  Widget _buildProjectDelegate(BuildContext context, ProjectInfo project) {
    final cachedImageSize = (MediaQuery.sizeOf(context).width -
            ResponsiveLayout.padding * 2 -
            ResponsiveLayout.padding * 3.5) ~/
        1;
    switch (project.delegate.runtimeType) {
      case const (CompactedAssetToken):
        final asset = project.delegate as CompactedAssetToken;
        return asset.pending == true && !asset.hasMetadata
            ? PendingTokenWidget(
                thumbnail: asset.galleryThumbnailURL,
                tokenId: asset.tokenId,
                shouldRefreshCache: asset.shouldRefreshThumbnailCache,
              )
            : tokenGalleryThumbnailWidget(
                context,
                asset,
                cachedImageSize,
                useHero: false,
                usingThumbnailID: false,
              );
      case const (Artwork):
        return IgnorePointer(
          child: AspectRatio(
            aspectRatio: 1,
            child: FFArtworkThumbnailView(
              artwork: project.delegate as Artwork,
              cacheWidth: cachedImageSize,
              cacheHeight: cachedImageSize,
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }
}
