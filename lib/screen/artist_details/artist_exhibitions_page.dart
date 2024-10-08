import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/feralfile_home/list_exhibition_view.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/loading.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ArtistExhibitionsPagePayload {
  final FFUser user;

  ArtistExhibitionsPagePayload(this.user);
}

class ArtistExhibitionsPage extends StatefulWidget {
  final ArtistExhibitionsPagePayload payload;

  const ArtistExhibitionsPage({required this.payload, super.key});

  @override
  State<ArtistExhibitionsPage> createState() => _ArtistExhibitionsPageState();
}

class _ArtistExhibitionsPageState extends State<ArtistExhibitionsPage> {
  List<Exhibition>? _exhibitions;

  Future<List<Exhibition>> _fetchExhibitions() async {
    final artist = widget.payload.user;
    final artistId = artist.id;
    final linkedAccountIds = artist.alumniAccount?.linkedAddresses ?? [];
    final response = await injector<FeralFileService>().getAllExhibitions(
      relatedAccountIDs: [artistId, ...linkedAccountIds],
    );

    setState(() {
      _exhibitions = response;
    });
    return response;
  }

  @override
  void initState() {
    super.initState();
    unawaited(_fetchExhibitions());
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
              Text('exhibitions'.tr(), style: theme.textTheme.ppMori700White14),
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
        child: Text('no_exhibition_found'.tr(),
            style: theme.textTheme.ppMori400White14));
  }

  Widget _buildBody(BuildContext context) {
    final exhibitions = _exhibitions;
    if (exhibitions == null) {
      return _loadingView(context);
    }
    if (exhibitions.isEmpty) {
      return _emptyView(context);
    }
    return ListExhibitionView(
      exhibitions: exhibitions,
      padding: const EdgeInsets.only(bottom: 48, top: 32),
    );
  }
}
