import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/feralfile_home/artwork_view.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ArtistWorksPagePayload {
  final FFUser user;

  ArtistWorksPagePayload(this.user);
}

class ArtistWorksPage extends StatefulWidget {
  final ArtistWorksPagePayload payload;

  const ArtistWorksPage({required this.payload, super.key});

  @override
  State<ArtistWorksPage> createState() => _ArtistWorksPageState();
}

class _ArtistWorksPageState extends State<ArtistWorksPage> {
  List<FFSeries>? _seriesList;

  Future<List<FFSeries>> _fetchSeriesList() async {
    final artist = widget.payload.user;
    final artistId = artist.id;
    final linkedAccountIds = artist.alumniAccount?.linkedAddresses ?? [];
    final response = await injector<FeralFileService>().exploreArtworks(
      artistIds: [artistId, ...linkedAccountIds],
    );
    setState(() {
      _seriesList = response.result;
    });
    return response.result;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_fetchSeriesList());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final artist = widget.payload.user;
    return Scaffold(
      appBar: getFFAppBar(context,
          onBack: () => Navigator.of(context).pop(),
          title: Column(
            children: [
              Text(
                artist.displayAlias,
                style: theme.textTheme.ppMori400White14,
              ),
              const SizedBox(height: 4),
              Text('_artworks'.tr(), style: theme.textTheme.ppMori700White14),
            ],
          )),
      backgroundColor: AppColor.primaryBlack,
      body: _buildBody(context),
    );
  }

  Widget _loadingView(BuildContext context) => const Center(
        child: LoadingWidget(),
      );

  Widget _emptyView(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Text(
        'no_artwork_found'.tr(),
        style: theme.textTheme.ppMori400White14,
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    final seriesList = _seriesList;
    if (seriesList == null) {
      return _loadingView(context);
    }
    if (seriesList.isEmpty) {
      return _emptyView(context);
    }
    return SeriesView(
      series: seriesList,
      padding: const EdgeInsets.only(bottom: 48),
    );
  }
}
