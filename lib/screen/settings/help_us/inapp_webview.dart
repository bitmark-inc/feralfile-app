import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

class InAppWebViewPage extends StatefulWidget {
  final InAppWebViewPayload payload;

  const InAppWebViewPage({required this.payload, super.key});

  @override
  State<InAppWebViewPage> createState() => _InAppWebViewPageState();
}

class _InAppWebViewPageState extends State<InAppWebViewPage> {
  InAppWebViewController? webViewController;
  late String title;
  late bool isLoading;
  final _configurationService = injector<ConfigurationService>();
  late bool _canGoBack;
  late bool _canGoForward;

  @override
  void initState() {
    title = Uri.parse(widget.payload.url).host;
    isLoading = false;
    _canGoBack = false;
    _canGoForward = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    var version = _configurationService.getVersionInfo();
    final isIOS = Platform.isIOS;
    final platform = isIOS ? 'ios' : 'android';
    return Scaffold(
      appBar: getDarkEmptyAppBar(Colors.black),
      backgroundColor: widget.payload.backgroundColor ?? theme.primaryColor,
      body: Column(
        children: [
          if (!widget.payload.isPlainUI) ...[
            _header(context),
            addOnlyDivider(color: AppColor.auGrey)
          ],
          Expanded(
            child: Stack(
              children: [
                InAppWebView(
                    initialUrlRequest:
                        URLRequest(url: WebUri(widget.payload.url)),
                    initialSettings: InAppWebViewSettings(
                      userAgent: 'user_agent'
                          .tr(namedArgs: {'version': '$version ($platform)'}),
                      isInspectable: true,
                    ),
                    onPermissionRequest: (InAppWebViewController controller,
                        permissionRequest) async {
                      if (permissionRequest.resources
                          .contains(PermissionResourceType.MICROPHONE)) {
                        await Permission.microphone.request();
                        final status = await Permission.microphone.status;
                        if (status.isPermanentlyDenied || status.isDenied) {
                          return PermissionResponse(
                              resources: permissionRequest.resources);
                        }
                        return PermissionResponse(
                            resources: permissionRequest.resources,
                            action: PermissionResponseAction.GRANT);
                      }
                      return PermissionResponse(
                          resources: permissionRequest.resources);
                    },
                    onWebViewCreated: (controller) {
                      if (widget.payload.onWebViewCreated != null) {
                        widget.payload.onWebViewCreated!(controller);
                      }
                      webViewController = controller;
                    },
                    onConsoleMessage: widget.payload.onConsoleMessage,
                    onLoadStart: (controller, uri) {
                      setState(() {
                        isLoading = true;
                        title = uri!.host;
                      });
                    },
                    onLoadStop: (controller, uri) {
                      setState(() {
                        isLoading = false;
                      });
                    },
                    onUpdateVisitedHistory: (controller, uri, _) {
                      setState(() {
                        title = uri!.host;
                      });
                      unawaited(refreshAppBarStatus());
                    }),
                if (isLoading)
                  Container(
                    color: AppColor.white,
                    child: Center(
                      child: loadingIndicator(),
                    ),
                  )
                else
                  const SizedBox(),
              ],
            ),
          ),
          if (!widget.payload.isPlainUI) ...[
            addOnlyDivider(color: AppColor.auGrey),
            _bottomBar(context)
          ],
        ],
      ),
    );
  }

  Widget _header(BuildContext context) => Stack(
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

  AppBar _appBar(BuildContext context,
      {required Function()? onClose, String title = ''}) {
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
          tooltip: 'CLOSE',
          onPressed: onClose,
          icon: closeIcon(),
        )
      ],
      backgroundColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
    );
  }

  Future<void> refreshAppBarStatus() async {
    final canGoBack = await webViewController?.canGoBack() ?? false;
    final canGoForward = await webViewController?.canGoForward() ?? false;
    setState(() {
      _canGoBack = canGoBack;
      _canGoForward = canGoForward;
    });
  }

  Widget _bottomBar(BuildContext context) => Container(
        color: AppColor.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 50),
        child: Row(
          children: [
            IconButton(
              icon: Icon(AuIcon.chevron,
                  color: _canGoBack
                      ? AppColor.primaryBlack
                      : AppColor.disabledColor),
              onPressed: () async {
                if (await webViewController?.canGoBack() ?? false) {
                  await webViewController?.goBack();
                  await refreshAppBarStatus();
                }
              },
            ),
            const Spacer(),
            IconButton(
              icon: RotatedBox(
                  quarterTurns: 2,
                  child: Icon(
                    AuIcon.chevron,
                    color: _canGoForward
                        ? AppColor.primaryBlack
                        : AppColor.disabledColor,
                  )),
              onPressed: () async {
                if (await webViewController?.canGoForward() ?? false) {
                  await webViewController?.goForward();
                  await refreshAppBarStatus();
                }
              },
            ),
            const Spacer(),
            IconButton(
              icon: SvgPicture.asset('assets/images/Reload.svg'),
              onPressed: () async {
                await webViewController?.reload();
                await refreshAppBarStatus();
              },
            ),
            const Spacer(),
            IconButton(
              icon: SvgPicture.asset('assets/images/Share.svg'),
              onPressed: () async {
                final currentUrl = await webViewController?.getUrl();
                if (currentUrl != null) {
                  unawaited(launchUrl(
                    currentUrl,
                    mode: LaunchMode.externalApplication,
                  ));
                }
              },
            ),
          ],
        ),
      );
}

class InAppWebViewPayload {
  final String url;
  final bool isPlainUI;
  final Color? backgroundColor;
  Function(InAppWebViewController controler)? onWebViewCreated;
  Function(InAppWebViewController controler, ConsoleMessage consoleMessage)?
      onConsoleMessage;

  InAppWebViewPayload(this.url,
      {this.isPlainUI = false,
      this.onWebViewCreated,
      this.onConsoleMessage,
      this.backgroundColor});
}
