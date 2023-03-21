import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InappWebviewPage extends StatefulWidget {
  final String url;

  const InappWebviewPage({super.key, required this.url});

  @override
  State<InappWebviewPage> createState() => _InappWebviewPageState();
}

class _InappWebviewPageState extends State<InappWebviewPage> {
  late WebViewController webViewController;
  late String title;
  @override
  void initState() {
    title = Uri.parse(widget.url).host;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getCloseAppBar(
        context,
        title: title,
        onClose: () {
          Navigator.of(context).pop();
        },
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: WebView(
                initialUrl: widget.url,
                javascriptMode: JavascriptMode.unrestricted,
                onWebViewCreated: (c) {
                  webViewController = c;
                },
                onPageStarted: (url) {
                  setState(() {
                    title = Uri.parse(url).host;
                  });
                },
              ),
            ),
            addOnlyDivider(),
            _bottomBar(context)
          ],
        ),
      ),
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(AuIcon.chevron),
            onPressed: () async {
              if (await webViewController.canGoBack()) {
                await webViewController.goBack();
              }
            },
          ),
          const Spacer(),
          IconButton(
            icon:
                const RotatedBox(quarterTurns: 2, child: Icon(AuIcon.chevron)),
            onPressed: () async {
              if (await webViewController.canGoForward()) {
                await webViewController.goForward();
              }
            },
          ),
          const Spacer(),
          IconButton(
            icon: SvgPicture.asset("assets/images/Reload.svg"),
            onPressed: () {
              webViewController.reload();
            },
          ),
          const Spacer(),
          IconButton(
            icon: SvgPicture.asset("assets/images/Share.svg"),
            onPressed: () async {
              final currentUrl = await webViewController.currentUrl();
              if (currentUrl != null) {
                launchUrl(
                  Uri.parse(currentUrl),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
          ),
        ],
      ),
    );
  }
}
