import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/preview/canvas_device_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:feralfile_app_tv_proto/feralfile_app_tv_proto.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ExhibitionsPage extends StatefulWidget {
  const ExhibitionsPage({super.key});

  @override
  State<ExhibitionsPage> createState() => ExhibitionsPageState();
}

class ExhibitionsPageState extends State<ExhibitionsPage> with RouteAware {
  late ExhibitionBloc _exhibitionBloc;
  late ScrollController _controller;
  final _navigationService = injector<NavigationService>();
  static const _padding = 14.0;
  final _canvasDeviceBloc = injector<CanvasDeviceBloc>();
  static const _exhibitionInfoDivideWidth = 20.0;

  // initState
  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _exhibitionBloc = injector<ExhibitionBloc>();
    _exhibitionBloc.add(GetAllExhibitionsEvent());
  }

  void scrollToTop() {
    unawaited(_controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn));
  }

  @override
  void dispose() {
    _controller.dispose();
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void didPopNext() {
    super.didPopNext();
    refreshExhibitions();
  }

  void refreshExhibitions() {
    _exhibitionBloc.add(GetAllExhibitionsEvent());
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getDarkEmptyAppBar(Colors.transparent),
        extendBody: true,
        extendBodyBehindAppBar: true,
        backgroundColor: AppColor.primaryBlack,
        body: CustomScrollView(
          controller: _controller,
          slivers: [
            SliverToBoxAdapter(
              child: SizedBox(
                height: MediaQuery.of(context).padding.top,
              ),
            ),
            SliverToBoxAdapter(
              child: HeaderView(
                title: 'exhibitions'.tr(),
              ),
            ),
            SliverToBoxAdapter(child: _listExhibitions(context))
          ],
        ),
      );

  Widget _exhibitionItem({
    required BuildContext context,
    required List<Exhibition> viewExhibition,
    required Exhibition exhibition,
  }) {
    final theme = Theme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final estimatedHeight = (screenWidth - _padding * 2) / 16 * 9;
    final estimatedWidth = screenWidth - _padding * 2;
    final index = viewExhibition.indexOf(exhibition);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            GestureDetector(
              onTap: exhibition.canViewDetails && index >= 0
                  ? () async {
                      final device = _canvasDeviceBloc.state.controllingDevice;
                      if (device != null) {
                        final castRequest = CastExhibitionRequest(
                          exhibitionId: exhibition.id,
                          katalog: ExhibitionKatalog.HOME,
                        );
                        _canvasDeviceBloc.add(CanvasDeviceCastExhibitionEvent(
                            device, castRequest));
                      }
                      await Navigator.of(context)
                          .pushNamed(AppRouter.exhibitionDetailPage,
                              arguments: ExhibitionDetailPayload(
                                exhibitions: viewExhibition,
                                index: index,
                              ));
                    }
                  : null,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: exhibition.id == SOURCE_EXHIBITION_ID
                    ? SvgPicture.network(
                        exhibition.coverUrl,
                        height: estimatedHeight,
                        placeholderBuilder: (context) => SizedBox(
                          height: estimatedHeight,
                          child: const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              backgroundColor: AppColor.auQuickSilver,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      )
                    : Image.network(
                        exhibition.coverUrl,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return SizedBox(
                            height: estimatedHeight,
                            child: const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                backgroundColor: AppColor.auQuickSilver,
                                strokeWidth: 2,
                              ),
                            ),
                          );
                        },
                        fit: BoxFit.fitWidth,
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (!exhibition.canViewDetails) ...[
                      _lockIcon(),
                      const SizedBox(width: 5),
                    ],
                    SizedBox(
                      width: (estimatedWidth - _exhibitionInfoDivideWidth) / 2 -
                          (exhibition.canViewDetails ? 0 : 13 + 5),
                      child: AutoSizeText(
                        exhibition.title,
                        style: theme.textTheme.ppMori400White16,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: _exhibitionInfoDivideWidth),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (exhibition.curator != null)
                        RichText(
                            text: TextSpan(
                                style: theme.textTheme.ppMori400Grey14.copyWith(
                                    decorationColor: AppColor.disabledColor),
                                children: [
                              TextSpan(text: 'curated_by'.tr()),
                              TextSpan(
                                  recognizer: TapGestureRecognizer()
                                    ..onTap = () async {
                                      await _navigationService
                                          .openFeralFileCuratorPage(
                                              exhibition.curator!.alias);
                                    },
                                  text: exhibition.curator!.alias,
                                  style: const TextStyle(
                                    decoration: TextDecoration.underline,
                                  )),
                            ])),
                      Text(
                          exhibition.isGroupExhibition
                              ? 'group_exhibition'.tr()
                              : 'solo_exhibition'.tr(),
                          style: theme.textTheme.ppMori400Grey14),
                      if (exhibition.getSeriesArtworkModelText != null)
                        Text(exhibition.getSeriesArtworkModelText!,
                            style: theme.textTheme.ppMori400Grey14),
                    ],
                  ),
                )
              ],
            )
          ],
        ),
      ],
    );
  }

  Widget _listExhibitions(BuildContext context) =>
      BlocConsumer<ExhibitionBloc, ExhibitionsState>(
        builder: (context, state) {
          final theme = Theme.of(context);
          if (state.freeExhibitions == null || state.proExhibitions == null) {
            return const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
                backgroundColor: AppColor.auQuickSilver,
                strokeWidth: 2,
              ),
            );
          } else {
            final freeExhibitions =
                state.freeExhibitions!.map((e) => e.exhibition).toList();
            final proExhibitions =
                state.proExhibitions!.map((e) => e.exhibition).toList();
            final isSubscribed = state.isSubscribed;
            final viewExhibitions = isSubscribed
                ? freeExhibitions + proExhibitions
                : freeExhibitions;
            final divider = addDivider(
                height: 40, color: AppColor.auQuickSilver, thickness: 0.5);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: _padding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!isSubscribed && freeExhibitions.isNotEmpty) ...[
                    Text('current_exhibition'.tr(),
                        style: theme.textTheme.ppMori400White14),
                    Text('for_essential_members'.tr(),
                        style: theme.textTheme.ppMori400Grey14),
                    const SizedBox(height: 18),
                  ],
                  ...freeExhibitions
                      .map((e) => [
                            _exhibitionItem(
                              context: context,
                              viewExhibition: viewExhibitions,
                              exhibition: e,
                            ),
                            divider,
                          ])
                      .flattened,
                  if (!isSubscribed && freeExhibitions.isNotEmpty)
                    _pastExhibitionHeader(context),
                  ...proExhibitions
                      .map((e) => [
                            _exhibitionItem(
                              context: context,
                              viewExhibition: viewExhibitions,
                              exhibition: e,
                            ),
                            divider,
                          ])
                      .flattened,
                  const SizedBox(height: 40)
                ],
              ),
            );
          }
        },
        listener: (context, state) {},
      );

  Widget _pastExhibitionHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('past_exhibition'.tr(),
                  style: theme.textTheme.ppMori400White14),
              Row(
                children: [
                  _lockIcon(),
                  const SizedBox(width: 5),
                  Text('premium_membership'.tr(),
                      style: theme.textTheme.ppMori400Grey14),
                ],
              ),
            ],
          ),
          PrimaryButton(
            color: AppColor.feralFileLightBlue,
            padding: EdgeInsets.zero,
            elevatedPadding: const EdgeInsets.symmetric(horizontal: 15),
            borderRadius: 20,
            text: 'get_premium'.tr(),
            onTap: () async {
              await Navigator.of(context).pushNamed(AppRouter.subscriptionPage);
            },
          ),
        ],
      ),
    );
  }

  Widget _lockIcon() => SizedBox(
        width: 13,
        height: 13,
        child: SvgPicture.asset('assets/images/lock_icon.svg',
            colorFilter: const ColorFilter.mode(
                AppColor.auQuickSilver, BlendMode.srcIn)),
      );
}
