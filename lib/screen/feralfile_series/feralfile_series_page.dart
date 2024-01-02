import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_bloc.dart';
import 'package:autonomy_flutter/screen/feralfile_series/feralfile_series_state.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/ff_artwork_thumbnail_view.dart';
import 'package:autonomy_flutter/view/series_title_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FeralFileSeriesPage extends StatefulWidget {
  const FeralFileSeriesPage({required this.payload, super.key});

  final FeralFileSeriesPagePayload payload;

  @override
  State<FeralFileSeriesPage> createState() => _FeralFileSeriesPageState();
}

class _FeralFileSeriesPageState extends State<FeralFileSeriesPage> {
  late final FeralFileSeriesBloc _feralFileSeriesBloc;

  @override
  void initState() {
    super.initState();
    _feralFileSeriesBloc = context.read<FeralFileSeriesBloc>();
    _feralFileSeriesBloc
        .add(FeralFileSeriesGetSeriesEvent(widget.payload.seriesId));
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<FeralFileSeriesBloc, FeralFileSeriesState>(
          builder: (context, state) => Scaffold(
              appBar: _getAppBar(context, state.series),
              backgroundColor: AppColor.primaryBlack,
              body: _body(context, state)),
          listener: (context, state) {});

  AppBar _getAppBar(BuildContext buildContext, FFSeries? series) => getFFAppBar(
        buildContext,
        onBack: () => Navigator.pop(buildContext),
        title: series == null
            ? const SizedBox()
            : SeriesTitleView(
                series: series,
                artist: series.artist,
                crossAxisAlignment: CrossAxisAlignment.center),
      );

  Widget _body(BuildContext context, FeralFileSeriesState state) {
    final series = state.series;
    if (series == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    return _artworkGridView(context, state.exhibitionDetail, state.artworks);
  }

  Widget _artworkGridView(BuildContext context,
          ExhibitionDetail? exhibitionDetail, List<Artwork> artworks) =>
      Padding(
        padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
        child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (context, index) {
              final artwork = artworks[index];
              return FFArtworkThumbnailView(
                artwork: artwork,
                onTap: () {},
              );
            },
            itemCount: artworks.length),
      );
}

class FeralFileSeriesPagePayload {
  final String seriesId;

  const FeralFileSeriesPagePayload({
    required this.seriesId,
  });
}
