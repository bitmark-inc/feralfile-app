import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_bloc.dart';
import 'package:autonomy_flutter/screen/collection_pro/collection_pro_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CollectionProScreen extends StatefulWidget {
  const CollectionProScreen({super.key});

  @override
  State<CollectionProScreen> createState() => _CollectionProScreenState();
}

class _CollectionProScreenState extends State<CollectionProScreen> {
  final _bloc = injector.get<CollectionProBloc>();
  final controller = ScrollController();
  @override
  void initState() {
    _bloc.add(LoadCollectionEvent());
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: BlocBuilder(
        bloc: _bloc,
        builder: (context, state) {
          if (state is CollectionInitState) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is CollectionLoadingState) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CollectionLoadedState) {
            final listAlbumByMedium = state.listAlbumByMedium;
            final listAlbumByArtist = state.listAlbumByArtist;
            return CustomScrollView(
              controller: controller,
              slivers: [
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
                          return ListTile(
                            title: Text(album?.name ?? ''),
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
