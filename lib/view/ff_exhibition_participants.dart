import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/feralfile_alumni_ext.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FFExhibitionParticipants extends StatelessWidget {
  final List<AlumniAccount> listAlumni;
  final TextStyle textStyle;

  const FFExhibitionParticipants({
    required this.listAlumni,
    required this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) => RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          children: exhibitionParticipantSpans(listAlumni),
          style: textStyle,
        ),
      );
}

List<TextSpan> exhibitionParticipantSpans(List<AlumniAccount> participants) {
  final spans = <TextSpan>[];

  TextSpan alumniNameItem(AlumniAccount alumni) => TextSpan(
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (alumni.slug != null) {
              await (alumni.isCurator == true
                  ? injector<NavigationService>()
                      .openFeralFileCuratorPage(alumni.slug!)
                  : injector<NavigationService>()
                      .openFeralFileArtistPage(alumni.slug!));
            } else if (alumni.websiteUrl.isNotEmpty) {
              await launchUrl(Uri.parse(alumni.websiteUrl.first));
            }
          },
        text: alumni.displayAlias,
        style: TextStyle(
          decoration: alumni.slug != null || alumni.websiteUrl.isNotEmpty
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      );

  for (int i = 0; i < participants.length; i++) {
    final participant = participants[i];
    spans.add(
      alumniNameItem(participant),
    );

    // Add a comma and space after each curator except the last one
    if (i < participants.length - 1) {
      spans.add(
        const TextSpan(
          text: ', ',
        ),
      );
    }
  }

  return spans;
}
