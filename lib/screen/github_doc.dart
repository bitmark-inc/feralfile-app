//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:url_launcher/url_launcher_string.dart';

class GithubDocPage extends StatefulWidget {
  final Map<String, String> payload;

  const GithubDocPage({Key? key, required this.payload}) : super(key: key);
  @override
  State<GithubDocPage> createState() => _GithubDocPageState();
}

class _GithubDocPageState extends State<GithubDocPage> {
  late String document;
  late String title;

  _GithubDocPageState() {
    document = widget.payload["document"]!;
    title = widget.payload["title"]!;
  }

  final dio = Dio(BaseOptions(
    baseUrl: "https://raw.githubusercontent.com",
    connectTimeout: 2000,
  ));

  @override
  void initState() {
    super.initState();
    dio.interceptors.add(LoggingInterceptor());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsets,
        child: FutureBuilder<Response<String>>(
          builder: (context, snapshot) => CustomScrollView(
            slivers: [
              if (title.isNotEmpty) ...[
                SliverToBoxAdapter(
                    child: Text(
                  title,
                  style: appTextTheme.headline1,
                )),
                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
              _contentView(context, snapshot)
            ],
          ),
          future: _githubPathForDocument(document)
              .then((path) => dio.get<String>(path)),
        ),
      ),
    );
  }

  Widget _contentView(
      BuildContext context, AsyncSnapshot<Response<String>> snapshot) {
    if (snapshot.hasData && snapshot.data?.statusCode == 200) {
      return SliverToBoxAdapter(
          child: Markdown(
              data: snapshot.data!.data!,
              softLineBreak: true,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 50),
              styleSheet: markDownLightStyle,
              onTapLink: (text, href, title) async {
                if (href == null) return;
                if (!(await canLaunchUrlString(href))) {
                  Navigator.of(context).pushNamed(AppRouter.githubDocPage,
                      arguments: {
                        "prefix": widget.payload["prefix"] ?? '',
                        "document": href,
                        "title": ""
                      });
                } else {
                  launchUrlString(href);
                }
              }));
    } else if (snapshot.hasError ||
        (snapshot.data != null && snapshot.data?.statusCode != 200)) {
      return SliverFillRemaining(
          child: Center(
              child: Text(
        "Error when loading the content",
        style: appTextTheme.headline4,
      )));
    } else {
      return const SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()));
    }
  }

  Future<String> _githubPathForDocument(String docFileName) async {
    var prefix = widget.payload["prefix"] ?? '';

    if (prefix.isEmpty) {
      prefix = (await isAppCenterBuild() || kDebugMode)
          ? "/bitmark-inc/autonomy-apps/develop/docs/"
          : "/bitmark-inc/autonomy-apps/main/docs/";
    }

    return prefix + docFileName;
  }
}
