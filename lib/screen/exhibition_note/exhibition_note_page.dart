import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/note_view.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';

class ExhibitionNotePage extends StatelessWidget {
  const ExhibitionNotePage({required this.exhibition, super.key});

  final Exhibition exhibition;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: getFFAppBar(
          context,
          onBack: () => Navigator.pop(context),
        ),
        backgroundColor: AppColor.primaryBlack,
        body: Padding(
          padding: const EdgeInsets.fromLTRB(14, 0, 14, 20),
          child: SingleChildScrollView(
            child: ExhibitionNoteView(
              exhibition: exhibition,
              isFull: true,
            ),
          ),
        ),
      );
}
