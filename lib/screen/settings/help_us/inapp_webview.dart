import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  late bool isLoading;
  @override
  void initState() {
    title = Uri.parse(widget.url).host;
    isLoading = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          systemNavigationBarDividerColor: Colors.transparent,
        ),
      ),
      backgroundColor: theme.primaryColor,
      body: Column(
        children: [
          _header(context),
          addOnlyDivider(color: AppColor.auGrey),
          Expanded(
            child: Stack(
              children: [
                WebView(
                  initialUrl: widget.url,
                  javascriptMode: JavascriptMode.unrestricted,
                  onWebViewCreated: (c) {
                    webViewController = c;
                  },
                  onPageStarted: (url) {
                    setState(() {
                      title = Uri.parse(url).host;
                      isLoading = true;
                    });
                  },
                  onPageFinished: (url) {
                    setState(() {
                      isLoading = false;
                    });
                  },
                  backgroundColor: AppColor.white,
                ),
                isLoading
                    ? Container(
                        color: AppColor.white,
                        child: Center(
                          child: loadingIndicator(),
                        ),
                      )
                    : const SizedBox(),
              ],
            ),
          ),
          addOnlyDivider(color: AppColor.auGrey),
          _bottomBar(context)
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Container(
            decoration: const BoxDecoration(
                color: AppColor.greyMedium,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  topRight: Radius.circular(10),
                )),
            height: 75,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Container(
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(10),
                topRight: Radius.circular(10),
              ),
            ),
            height: 75,
            child: SizedBox(
                height: 50,
                child: _appBar(
                  context,
                  title: title,
                  onClose: () {
                    Navigator.of(context).pop();
                  },
                )),
          ),
        ),
      ],
    );
  }

  AppBar _appBar(BuildContext context,
      {String title = "", required Function()? onClose}) {
    final theme = Theme.of(context);
    return AppBar(
      centerTitle: true,
      automaticallyImplyLeading: false,
      title: Text(
        title,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.ppMori400Black16,
        textAlign: TextAlign.center,
      ),
      actions: [
        IconButton(
          tooltip: "CLOSE",
          onPressed: onClose,
          icon: closeIcon(),
        )
      ],
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
    );
  }

  Widget _bottomBar(BuildContext context) {
    return Container(
      color: AppColor.white,
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
