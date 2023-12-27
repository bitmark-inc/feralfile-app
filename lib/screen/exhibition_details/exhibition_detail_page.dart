import 'package:autonomy_flutter/model/ff_account.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/cast_button.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
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

  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _exBloc = context.read<ExhibitionDetailBloc>();
    _exBloc.add(GetExhibitionDetailEvent(
        widget.payload.exhibitions[widget.payload.index].id));

    _controller = PageController();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(context,
            onBack: () => Navigator.pop(context),
            action: CastButton(
                text: _currentIndex == 0 ? 'stream_to_device'.tr() : null)),
        backgroundColor: AppColor.primaryBlack,
        body: BlocConsumer<ExhibitionDetailBloc, ExhibitionDetailState>(
            builder: (context, state) {
              final exhibitionDetail = state.exhibitionDetail;
              if (exhibitionDetail == null) {
                return Container();
              }

              final viewingArtworks = exhibitionDetail.representArtworks;
              final tokenIds = viewingArtworks
                  .map((e) => exhibitionDetail.getArtworkTokenId(e))
                  .toList();
              return Stack(
                children: [
                  Column(
                    children: [
                      Expanded(
                        child: PageView.builder(
                            controller: _controller,
                            onPageChanged: (index) {
                              setState(() {
                                _currentIndex = index;
                              });
                            },
                            scrollDirection: Axis.vertical,
                            itemCount: tokenIds.length + 1,
                            itemBuilder: (context, index) {
                              switch (index) {
                                case 0:
                                  return _getPreviewPage(
                                      exhibitionDetail.exhibition);
                                default:
                                  final series = exhibitionDetail
                                      .exhibition.series!
                                      .firstWhere((element) =>
                                          element.id ==
                                          viewingArtworks[index - 1].seriesID);
                                  return FeralFileArtworkPreview(
                                      payload: FeralFileArtworkPreviewPayload(
                                    tokenId: tokenIds[index - 1],
                                    artwork: viewingArtworks[index - 1],
                                    series: series,
                                  ));
                              }
                            }),
                      ),
                    ],
                  ),
                  if (_currentIndex == 0)
                    Align(
                        alignment: Alignment.bottomCenter,
                        child: _nextButton()),
                ],
              );
            },
            listener: (context, state) {}),
      );

  Widget _getPreviewPage(Exhibition exhibition) => Column(
        children: [
          ExhibitionPreview(
            exhibition: exhibition,
          )
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
}

class ExhibitionDetailPayload {
  final List<Exhibition> exhibitions;
  final int index;

  const ExhibitionDetailPayload({
    required this.exhibitions,
    this.index = 0,
  });
}

class ExhibitionPreview extends StatelessWidget {
  const ExhibitionPreview({required this.exhibition, super.key});

  final Exhibition exhibition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTextStyle = theme.textTheme.ppMori400Grey12
        .copyWith(color: AppColor.feralFileMediumGrey);
    final artistTextStyle = theme.textTheme.ppMori400White16
        .copyWith(decoration: TextDecoration.underline);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              exhibition.coverUrl,
              fit: BoxFit.fitWidth,
            ),
          ),
          HeaderView(
            title: exhibition.title,
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          Text('curator'.tr(), style: subTextStyle),
          const SizedBox(height: 3),
          GestureDetector(
            child:
                Text(exhibition.curator?.alias ?? '', style: artistTextStyle),
            onTap: () {},
          ),
          const SizedBox(height: 10),
          Text('group_exhibition'.tr(), style: subTextStyle),
          const SizedBox(height: 3),
          RichText(
              text: TextSpan(
                  children: exhibition.artists!
                      .map((e) {
                        final isLast = exhibition.artists!.last == e;
                        return [
                          TextSpan(
                              style: artistTextStyle,
                              recognizer: TapGestureRecognizer()..onTap = () {},
                              text: e.alias),
                          if (!isLast)
                            const TextSpan(
                              text: ', ',
                            )
                        ];
                      })
                      .flattened
                      .toList())),
        ],
      ),
    );
  }
}

class FeralFileArtworkPreview extends StatelessWidget {
  const FeralFileArtworkPreview({required this.payload, super.key});

  final FeralFileArtworkPreviewPayload payload;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: ArtworkPreviewWidget(
            identity: ArtworkIdentity(payload.tokenId, ''),
            useIndexer: true,
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SeriesTitleView(
                  series: payload.series, artist: payload.series.artist),
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Text(
                  '${payload.artwork.index + 1}/${payload.series.settings?.maxArtwork ?? '--'}',
                  style:
                      theme.textTheme.ppMori400White12.copyWith(fontSize: 10),
                ),
              )
            ],
          ),
        ),
      ],
    );
  }
}

class FeralFileArtworkPreviewPayload {
  final String tokenId;
  final FFSeries series;
  final Artwork artwork;

  const FeralFileArtworkPreviewPayload({
    required this.tokenId,
    required this.series,
    required this.artwork,
  });
}

class SeriesTitleView extends StatelessWidget {
  const SeriesTitleView(
      {required this.series, super.key, this.crossAxisAlignment, this.artist});

  final FFSeries series;
  final FFArtist? artist;
  final CrossAxisAlignment? crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: crossAxisAlignment ?? CrossAxisAlignment.start,
      children: [
        Text(
          artist?.alias ?? '',
          style: theme.textTheme.ppMori400White14,
        ),
        const SizedBox(height: 3),
        Text(
          series.title,
          style: theme.textTheme.ppMori700White14.copyWith(
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}
