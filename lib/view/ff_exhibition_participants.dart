import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class FFExhibitionParticipants extends StatelessWidget {
  final List<FFUser> users;
  final TextStyle textStyle;

  const FFExhibitionParticipants({
    required this.users,
    required this.textStyle,
    super.key,
  });

  @override
  Widget build(BuildContext context) => RichText(
        textScaler: MediaQuery.textScalerOf(context),
        text: TextSpan(
          children: exhibitionParticipantSpans(users),
          style: textStyle,
        ),
      );
}

List<TextSpan> exhibitionParticipantSpans(List<FFUser> participants) {
  final spans = <TextSpan>[];

  TextSpan userNameItem(FFUser user) => TextSpan(
        recognizer: TapGestureRecognizer()
          ..onTap = () async {
            if (user.alumniAccount?.slug != null) {
              await (user.isCurator == true
                  ? injector<NavigationService>()
                      .openFeralFileCuratorPage(user.alumniAccount!.slug!)
                  : injector<NavigationService>()
                      .openFeralFileArtistPage(user.alumniAccount!.slug!));
            } else if (user.alumniAccount?.website != null) {
              await launchUrl(Uri.parse(user.alumniAccount!.website!));
            }
          },
        text: user.displayAlias,
        style: TextStyle(
          decoration: user.alumniAccount?.slug != null ||
                  user.alumniAccount?.website != null
              ? TextDecoration.underline
              : TextDecoration.none,
        ),
      );

  for (int i = 0; i < participants.length; i++) {
    final user = participants[i];
    spans.add(
      userNameItem(user),
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
