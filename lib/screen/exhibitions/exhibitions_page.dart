import 'dart:async';

import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_page.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_bloc.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExhibitionsPage extends StatefulWidget {
  const ExhibitionsPage({super.key});

  @override
  State<ExhibitionsPage> createState() => ExhibitionsPageState();
}

class ExhibitionsPageState extends State<ExhibitionsPage> {
  late ExhibitionBloc _exhibitionBloc;
  late ScrollController _controller;

  // initState
  @override
  void initState() {
    super.initState();
    _controller = ScrollController();
    _exhibitionBloc = context.read<ExhibitionBloc>();
    _exhibitionBloc.add(GetAllExhibitionsEvent());
  }

  void scrollToTop() {
    unawaited(_controller.animateTo(0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.fastOutSlowIn));
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

  Widget _exhibitionItem(
      BuildContext context, ExhibitionDetail exhibitionDetail) {
    final theme = Theme.of(context);
    final exhibition = exhibitionDetail.exhibition;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('current_exhibition'.tr(),
              style: theme.textTheme.ppMori400White14),
          if (exhibition.isFreeToStream)
            Text('free_to_stream'.tr(), style: theme.textTheme.ppMori400Grey14),
          const SizedBox(height: 18),
          Column(
            children: [
              GestureDetector(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    exhibition.coverUrl,
                    fit: BoxFit.fitWidth,
                  ),
                ),
                onTap: () async {
                  await Navigator.of(context)
                      .pushNamed(AppRouter.exhibitionDetailPage,
                          arguments: ExhibitionDetailPayload(
                            exhibitions: _exhibitionBloc.state.exhibitions!
                                .map((e) => e.exhibition)
                                .toList(),
                          ));
                },
              ),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(exhibition.title,
                        style: theme.textTheme.ppMori400White16),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (exhibition.curator != null)
                          RichText(
                              text: TextSpan(
                                  style: theme.textTheme.ppMori400Grey14,
                                  children: [
                                TextSpan(text: 'curated_by'.tr()),
                                TextSpan(
                                    recognizer: TapGestureRecognizer()
                                      ..onTap = () {},
                                    text: exhibition.curator?.alias ?? '',
                                    style: const TextStyle(
                                      decoration: TextDecoration.underline,
                                    )),
                              ])),
                        Text(
                            exhibition.isGroupExhibition
                                ? 'group_exhibition'.tr()
                                : 'solo_exhibition'.tr(),
                            style: theme.textTheme.ppMori400Grey14),
                        Text(
                            '_works'.tr(args: [
                              exhibitionDetail.artworks?.length.toString() ??
                                  '-'
                            ]),
                            style: theme.textTheme.ppMori400Grey14),
                      ],
                    ),
                  )
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _listExhibitions(BuildContext context) =>
      BlocConsumer<ExhibitionBloc, ExhibitionsState>(
        builder: (context, state) {
          final exhibitions = state.exhibitions;
          if (exhibitions == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
          return Column(
            children: [
              ...exhibitions
                  .map((e) =>
                      [_exhibitionItem(context, e), const SizedBox(height: 40)])
                  .flattened
            ],
          );
        },
        listener: (context, state) {},
      );
}
