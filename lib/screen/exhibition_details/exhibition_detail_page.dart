import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_theme/style/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ExhibitionDetailPage extends StatefulWidget {
  const ExhibitionDetailPage({required this.payload, super.key});

  final ExhibitionDetailPayload payload;

  @override
  State<ExhibitionDetailPage> createState() => _ExhibitionDetailPageState();
}

class _ExhibitionDetailPageState extends State<ExhibitionDetailPage> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    print(widget.payload.exhibitions.first.toJson());
    return Scaffold(
      appBar: getFFAppBar(
        context,
        onBack: () => Navigator.pop(context),
      ),
      backgroundColor: AppColor.primaryBlack,
      body: BlocConsumer<ExhibitionDetailBloc, ExhibitionDetailState>(
          builder: (context, state) {
            return Container();
          },
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
