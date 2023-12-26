import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExhibitionDetailPage extends StatefulWidget {
  const ExhibitionDetailPage({required this.payload, super.key});

  final ExhibitionDetailPayload payload;

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  late final ExhibitionDetailBloc _exBloc;

  @override
  void initState() {
    super.initState();
    _exBloc = context.read<ExhibitionDetailBloc>();
    _exBloc.add(
        SaveExhibitionEvent(widget.payload.exhibitions[widget.payload.index]));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getFFAppBar(
        context,
        onBack: () => Navigator.pop(context),
      ),
      backgroundColor: AppColor.primaryBlack,
      body: BlocConsumer<ExhibitionDetailBloc, ExhibitionDetailState>(
          builder: (context, state) => ExhibitionPreview(
                exhibition:
                    state.exhibition ?? widget.payload.exhibitions.first,
              ),
          listener: (context, state) {}),
    );
  }
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
  const ExhibitionPreview({super.key, required this.exhibition});

  final Exhibition exhibition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTextStyle = theme.textTheme.ppMori400Grey12;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(
                  exhibition.coverUrl,
                  fit: BoxFit.fitWidth,
                ),
              ),
              const SizedBox(height: 20),
              HeaderView(title: exhibition.title),
              const SizedBox(height: 20),

              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                        Text('180 Works',
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
}
