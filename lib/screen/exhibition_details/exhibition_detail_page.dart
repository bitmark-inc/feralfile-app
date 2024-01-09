import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/play_control_model.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/screen/exhibition_note/exhibition_note_page.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/canvas_device_view.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/event_view.dart';
import 'package:autonomy_flutter/view/exhibition_detail_last_page.dart';
import 'package:autonomy_flutter/view/exhibition_detail_preview.dart';
import 'package:autonomy_flutter/view/ff_artwork_preview.dart';
import 'package:autonomy_flutter/view/note_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';

class ExhibitionDetailPage extends StatefulWidget {
  const ExhibitionDetailPage({required this.payload, super.key});

  final ExhibitionDetailPayload payload;

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  late final ExhibitionDetailBloc _exBloc;
  late final CanvasDeviceBloc _canvasDeviceBloc;

  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _exBloc = context.read<ExhibitionDetailBloc>();
    _canvasDeviceBloc = context.read<CanvasDeviceBloc>();
    _exBloc.add(GetExhibitionDetailEvent(
        widget.payload.exhibitions[widget.payload.index].id));

    _controller = PageController();
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

    final viewingArtworks = exhibitionDetail.representArtworks
      ..sort((a, b) => a.seriesID.compareTo(b.seriesID));

    final tokenIds = viewingArtworks
        .map((e) => exhibitionDetail.getArtworkTokenId(e)!)
        .toList();
    final itemCount = tokenIds.length + 3;
    return Stack(
      children: [
        PageView.builder(
          controller: _controller,
          onPageChanged: (index) {
            setState(() {
              _currentIndex = index;
            });
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
                return _notePage(exhibitionDetail.exhibition);
              default:
                final seriesIndex = index - 2;
                final series = exhibitionDetail.exhibition.series!.firstWhere(
                    (element) =>
                        element.id == viewingArtworks[seriesIndex].seriesID);
                return FeralFileArtworkPreview(
                  payload: FeralFileArtworkPreviewPayload(
                    tokenId: tokenIds[seriesIndex],
                    artwork: viewingArtworks[seriesIndex],
                    series: series,
                  ),
                );
            }
          },
        ),
        if (_currentIndex == 0 || _currentIndex == 1)
          Align(
            alignment: Alignment.bottomCenter,
            child: _nextButton(),
          ),
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
            onPressed: () async => _controller.nextPage(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeIn),
            icon: SvgPicture.asset(
              'assets/images/ff_back_dark.svg',
            ),
          ),
        ),
      );

  Widget _notePage(Exhibition exhibition) {
    const horizontalPadding = 14.0;
    const peekWidth = 50.0;
    final width =
        MediaQuery.sizeOf(context).width - horizontalPadding * 2 - peekWidth;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 14),
              child: ExhibitionNoteView(
                exhibition: exhibition,
                width: width,
                onReadMore: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExhibitionNotePage(
                        exhibition: exhibition,
                      ),
                    ),
                  );
                },
              ),
            ),
            ...exhibition.resources?.map((e) => ExhibitionEventView(
                      exhibitionEvent: e,
                      width: width,
                    )) ??
                []
          ],
        ),
      ),
    );
  }

  AppBar _getAppBar(
          BuildContext buildContext, ExhibitionDetail? exhibitionDetail) =>
      getFFAppBar(
        buildContext,
        onBack: () => Navigator.pop(buildContext),
        action: exhibitionDetail == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 14, bottom: 10, top: 10),
                child: CastButton(
                  text: _currentIndex == 0 ? 'stream_to_device'.tr() : null,
                  onCastTap: () async {
                    await _onCastTap(buildContext, exhibitionDetail);
                  },
                ),
              ),
      );

  Future<void> _onCastTap(
      BuildContext context, ExhibitionDetail exhibitionDetail) async {
    if (exhibitionDetail.artworks == null ||
        exhibitionDetail.artworks!.isEmpty) {
      return;
    }
    exhibitionDetail.artworks!.sort((a, b) {
      if (a.index != b.index) {
        a.index.compareTo(b.index);
      }
      return a.seriesID.compareTo(b.seriesID);
    });
    final tokenIds = exhibitionDetail.artworks
        ?.map((e) => exhibitionDetail.getArtworkTokenId(e)!)
        .toList();
    final sceneId = exhibitionDetail.exhibition.id;
    final playlistModel = PlayListModel(
      name: exhibitionDetail.exhibition.title,
      id: sceneId,
      thumbnailURL: exhibitionDetail.exhibition.coverUrl,
      tokenIDs: tokenIds,
      playControlModel: PlayControlModel(timer: 30),
    );
    await UIHelper.showFlexibleDialog(
      context,
      BlocProvider.value(
        value: _canvasDeviceBloc,
        child: CanvasDeviceView(
          sceneId: sceneId,
          isCollection: true,
          playlist: playlistModel,
          onClose: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      isDismissible: true,
    );
    await _fetchDevice(sceneId);
  }

  Future<void> _fetchDevice(String exhibitionId) async {
    _canvasDeviceBloc
        .add(CanvasDeviceGetDevicesEvent(exhibitionId, syncAll: false));
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
