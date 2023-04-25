import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/screen/album/album_screen.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CollectionPro extends StatefulWidget {
  const CollectionPro({super.key});

  @override
  State<CollectionPro> createState() => CollectionProState();
}

class CollectionProState extends State<CollectionPro>
    with RouteAware, WidgetsBindingObserver {
  final _bloc = injector.get<CollectionProBloc>();
  final controller = ScrollController();
  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    loadCollection();
    super.initState();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  void didPopNext() {
    loadCollection();
    super.didPopNext();
  }

  loadCollection() {
    _bloc.add(LoadCollectionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: BlocBuilder(
        bloc: _bloc,
        builder: (context, state) {
          if (state is CollectionLoadedState) {
            final listAlbumByMedium = state.listAlbumByMedium;
            final listAlbumByArtist = state.listAlbumByArtist;
            final paddingTop = MediaQuery.of(context).viewPadding.top;

            return CustomScrollView(
              controller: controller,
              slivers: [
                SliverToBoxAdapter(
                  child: HeaderView(paddingTop: paddingTop),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Medium',
                        style: theme.textTheme.headlineMedium,
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listAlbumByMedium?.length,
                        itemBuilder: (context, index) {
                          final album = listAlbumByMedium?[index];
                          return ListTile(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.albumPage,
                                arguments: AlbumScreenPayload(
                                  type: AlbumType.medium,
                                  id: album?.id,
                                ),
                              );
                            },
                            title: Text(album?.name ?? ''),
                            trailing: Text('${album?.total ?? 0}'),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Artist',
                        style: theme.textTheme.headlineMedium,
                      ),
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: listAlbumByArtist?.length,
                        itemBuilder: (context, index) {
                          final album = listAlbumByArtist?[index];
                          final artistName = album?.name?.isNotEmpty ?? false
                              ? album?.name ?? ''
                              : album?.id ?? 'Unknown';
                          return ListTile(
                            onTap: () {
                              Navigator.pushNamed(
                                context,
                                AppRouter.albumPage,
                                arguments: AlbumScreenPayload(
                                  type: AlbumType.artist,
                                  id: album?.id,
                                ),
                              );
                            },
                            title: Text(artistName),
                            trailing: Text('${album?.total ?? 0}'),
                          );
                        },
                      ),
                    ],
                  ),
                )
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }
}
