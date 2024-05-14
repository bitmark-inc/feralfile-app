import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/pair.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/service/metric_client_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/exhibition_detail_last_page.dart';
import 'package:autonomy_flutter/view/exhibition_detail_preview.dart';
import 'package:autonomy_flutter/view/ff_artwork_preview.dart';
import 'package:autonomy_flutter/view/note_view.dart';
import 'package:autonomy_flutter/view/post_view.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class ExhibitionDetailPage extends StatefulWidget {
  const ExhibitionDetailPage({required this.payload, super.key});

  final ExhibitionDetailPayload payload;

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage>
    with AfterLayoutMixin {
  late final ExhibitionDetailBloc _exBloc;

  // late final CanvasDeviceBloc _canvasDeviceBloc;
  final _metricClientService = injector<MetricClientService>();
  final _canvasDeviceBloc = injector<CanvasDeviceBloc>();

  late final PageController _controller;
  int _currentIndex = 0;
  late int _carouselIndex;

  @override
  void initState() {
    super.initState();
    _exBloc = context.read<ExhibitionDetailBloc>();
    _exBloc.add(GetExhibitionDetailEvent(
        widget.payload.exhibitions[widget.payload.index].id));
    _controller = PageController();
    _carouselIndex = 0;
  }

  @override
  Widget build(BuildContext context) =>
      BlocConsumer<ExhibitionDetailBloc, ExhibitionDetailState>(
        builder: (context, state) => Scaffold(
          appBar: _getAppBar(context, state.exhibitionDetail),
          backgroundColor: AppColor.primaryBlack,
          body: _body(context, state),
        ),
        listener: (context, state) {},
      );

  Widget _body(BuildContext context, ExhibitionDetailState state) {
    final exhibitionDetail = state.exhibitionDetail;
    if (exhibitionDetail == null) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final viewingArtworks = exhibitionDetail.representArtworks;
    final itemCount = viewingArtworks.length + 3;
    return Column(
      children: [
        Expanded(
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (index) {
              setState(() {
                _currentIndex = index;
              });
              final controllingDevice =
                  _canvasDeviceBloc.state.controllingDevice;
              log.info('onPageChanged: $_currentIndex');
              if (controllingDevice != null) {
                final request = _getCastExhibitionRequest(exhibitionDetail);
                log.info('onPageChanged: request: $request');
                _canvasDeviceBloc.add(
                  CanvasDeviceCastExhibitionEvent(controllingDevice, request),
                );
              }
            },
            scrollDirection: Axis.vertical,
            itemCount: itemCount,
            itemBuilder: (context, index) {
              if (index == itemCount - 1) {
                return ExhibitionDetailLastPage(
                  startOver: () => setState(() {
                    _currentIndex = 0;
                    _controller.jumpToPage(0);
                  }),
                  nextPayload: widget.payload.next(),
                );
              }

              switch (index) {
                case 0:
                  return _getPreviewPage(exhibitionDetail.exhibition);
                case 1:
                  return _notePage(exhibitionDetail);
                default:
                  final seriesIndex = index - 2;
                  final series = exhibitionDetail.getSeriesByIndex(seriesIndex);
                  final artwork =
                      exhibitionDetail.representArtworkByIndex(seriesIndex);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: FeralFileArtworkPreview(
                      payload: FeralFileArtworkPreviewPayload(
                        artwork: artwork,
                        series: series,
                      ),
                    ),
                  );
              }
            },
          ),
        ),
        if (_currentIndex == 0 || _currentIndex == 1) _nextButton()
      ],
    );
  }

  Widget _getPreviewPage(Exhibition exhibition) => Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ExhibitionPreview(
            exhibition: exhibition,
          ),
        ],
      );

  Widget _nextButton() => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: RotatedBox(
          quarterTurns: 3,
          child: IconButton(
            padding: const EdgeInsets.all(0),
            onPressed: () async => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn),
            icon: SvgPicture.asset(
              'assets/images/ff_back_dark.svg',
            ),
          ),
        ),
      );

  Widget _notePage(ExhibitionDetail exhibitionDetail) {
    final exhibition = exhibitionDetail.exhibition;
    return LayoutBuilder(
      builder: (context, constraints) => Center(
        child: CarouselSlider(
          items: [
            ExhibitionNoteView(
              exhibition: exhibition,
              onReadMore: () async {
                await Navigator.pushNamed(
                  context,
                  AppRouter.exhibitionNotePage,
                  arguments: exhibition,
                );
              },
            ),
            ...exhibition.posts?.map((e) => ExhibitionPostView(
                      post: e,
                    )) ??
                []
          ],
          options: CarouselOptions(
            aspectRatio: constraints.maxWidth / constraints.maxHeight,
            viewportFraction: 0.76,
            enableInfiniteScroll: false,
            enlargeCenterPage: true,
          ),
        ),
      ),
    );
  }

  AppBar _getAppBar(
          BuildContext buildContext, ExhibitionDetail? exhibitionDetail) =>
      getFFAppBar(
        buildContext,
        onBack: () => Navigator.pop(buildContext),
        action: exhibitionDetail == null ||
                exhibitionDetail.exhibition.status != 4
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 14, bottom: 10, top: 10),
                child: FFCastButton(
                  onDeviceSelected: (device) async {
                    final request = _getCastExhibitionRequest(exhibitionDetail);
                    _canvasDeviceBloc.add(
                      CanvasDeviceCastExhibitionEvent(device, request),
                    );
                  },
                ),
              ),
      );

  Pair<ExhibitionKatalog, String?> _getCurrentKatalogInfo(
      ExhibitionDetail exhibitionDetail) {
    ExhibitionKatalog? katalog;
    String? katalogId;
    switch (_currentIndex) {
      case 0:
        katalog = ExhibitionKatalog.HOME;
        break;
      case 1:
        if (_carouselIndex == 0) {
          katalog = ExhibitionKatalog.CURATOR_NOTE;
        } else {
          katalog = ExhibitionKatalog.RESOURCE;
          katalogId = exhibitionDetail.exhibition.posts![_carouselIndex - 1].id;
        }
        break;
      default:
        katalog = ExhibitionKatalog.ARTWORK;
        final seriesIndex = _currentIndex - 2;
        final currentArtwork =
            exhibitionDetail.representArtworkByIndex(seriesIndex).id;
        katalogId = currentArtwork;
        break;
    }
    return Pair(katalog, katalogId);
  }

  CastExhibitionRequest _getCastExhibitionRequest(
      ExhibitionDetail exhibitionDetail) {
    final exhibitionId = exhibitionDetail.exhibition.id;
    final katalogInfo = _getCurrentKatalogInfo(exhibitionDetail);
    final katalog = katalogInfo.first;
    final katalogId = katalogInfo.second;
    CastExhibitionRequest request = CastExhibitionRequest(
      exhibitionId: exhibitionId,
      katalog: katalog,
      katalogId: katalogId,
    );
    return request;
  }

  // Future<void> _onCastTap(
  //     BuildContext context, ExhibitionDetail exhibitionDetail) async {
  //   if (exhibitionDetail.artworks == null ||
  //       exhibitionDetail.artworks!.isEmpty) {
  //     return;
  //   }
  //   final tokenIds = exhibitionDetail.artworks
  //       ?.map((e) => exhibitionDetail.getArtworkTokenId(e)!)
  //       .toList();
  //   final sceneId = exhibitionDetail.exhibition.id;
  //   final playlistModel = PlayListModel(
  //     name: exhibitionDetail.exhibition.title,
  //     id: sceneId,
  //     thumbnailURL: exhibitionDetail.exhibition.coverUrl,
  //     tokenIDs: tokenIds,
  //     playControlModel: PlayControlModel(timer: 30),
  //   );
  //   await UIHelper.showFlexibleDialog(
  //     context,
  //     BlocProvider.value(
  //       value: _canvasDeviceBloc,
  //       child: CanvasDeviceView(
  //         sceneId: sceneId,
  //         isCollection: true,
  //         playlist: playlistModel,
  //         onClose: () {
  //           Navigator.of(context).pop();
  //         },
  //       ),
  //     ),
  //     isDismissible: true,
  //   );
  //   await _fetchDevice(sceneId);
  // }

  // Future<void> _fetchDevice(String exhibitionId) async {
  //   _canvasDeviceBloc
  //       .add(CanvasDeviceGetDevicesEvent(exhibitionId, syncAll: false));
  // }

  @override
  FutureOr<void> afterFirstLayout(BuildContext context) {
    _metricClientService.addEvent(
      MixpanelEvent.viewExhibition,
      data: {
        MixpanelProp.exhibitionId:
            widget.payload.exhibitions[widget.payload.index].id,
      },
    );
  }
}

class ExhibitionDetailPayload {
  final List<Exhibition> exhibitions;
  final int index;

  const ExhibitionDetailPayload({
    required this.exhibitions,
    required this.index,
  });

  // copyWith function
  ExhibitionDetailPayload copyWith({
    List<Exhibition>? exhibitions,
    int? index,
  }) =>
      ExhibitionDetailPayload(
        exhibitions: exhibitions ?? this.exhibitions,
        index: index ?? this.index,
      );

  // next function: increase index by 1, if index is out of range, return null
  ExhibitionDetailPayload? next() {
    if (index + 1 >= exhibitions.length) {
      return null;
    }
    return copyWith(index: index + 1);
  }
}
