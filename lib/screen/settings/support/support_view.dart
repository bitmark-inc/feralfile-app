import 'package:autonomy_flutter/util/log.dart';
import 'package:flutter/material.dart';
import 'package:flutter_email_sender/flutter_email_sender.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Support",
          style: Theme.of(context).textTheme.headline1,
        ),
        SizedBox(height: 24.0),
        _supportItem(
          context,
          "Contact us by email",
          onTap: _emailUs,
        ),
        Divider(),
        SizedBox(height: 16.0),
        _supportItem(
          context,
          "Reach out to us on Discord",
          onTap: _launchDiscord,
        ),
      ],
    );
  }

  Widget _supportItem(BuildContext context, String title,
      {GestureTapCallback? onTap}) {
    return Container(
        padding: EdgeInsets.only(bottom: 16.0),
        child: GestureDetector(
          onTap: onTap,
          child: Row(
            children: [
              Text(title, style: Theme.of(context).textTheme.headline5),
              Spacer(),
              SvgPicture.asset("assets/images/cil_external-link.svg")
            ],
          ),
        ));
  }

  void _emailUs() async {
    final logFiles = await getLogFiles();

    final Email email = Email(
      body: '',
      subject: 'Autonomy Support',
      recipients: ['support@bitmark.com'],
      attachmentPaths: logFiles,
      isHTML: false,
    );

    await FlutterEmailSender.send(email);
  }

  void _launchDiscord() async {
    if (!await launch('https://discord.com/invite/Wm2ZvGSxqg',
        forceSafariVC: false)) throw 'could not launch discord';
  }
}
