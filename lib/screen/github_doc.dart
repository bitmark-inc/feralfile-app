//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/dio_interceptors.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/theme_manager.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class GithubDocPage extends StatefulWidget {
  static const String tag = 'github_doc';

  final Map<String, String> payload;

  const GithubDocPage({Key? key, required this.payload}) : super(key: key);
  @override
  State<GithubDocPage> createState() =>
      _GithubDocPageState(payload["document"]!, payload["title"]!);
}

class _GithubDocPageState extends State<GithubDocPage> {
  final String document;
  final String title;

  _GithubDocPageState(this.document, this.title);

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
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin: pageEdgeInsets,
        child: FutureBuilder<Response<String>>(
          builder: (context, snapshot) => CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                  child: Text(
                title,
                style: appTextTheme.headline1,
              )),
              SliverPadding(padding: EdgeInsets.only(bottom: 40)),
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
              physics: NeverScrollableScrollPhysics(),
              padding: EdgeInsets.only(bottom: 50),
              styleSheet: MarkdownStyleSheet.fromTheme(
                  AuThemeManager.get(AppTheme.markdownThemeBlack))));
    } else if (snapshot.hasError ||
        (snapshot.data != null && snapshot.data?.statusCode != 200)) {
      return SliverFillRemaining(
          child: Center(
              child: Text(
        "Error when loading the content",
        style: appTextTheme.headline4,
      )));
    } else {
      return SliverFillRemaining(
          child: Center(child: CupertinoActivityIndicator()));
    }
  }

  Future<String> _githubPathForDocument(String docFileName) async {
    final prefix = (await isAppCenterBuild() || kDebugMode)
        ? "/bitmark-inc/autonomy-apps/develop/docs/"
        : "/bitmark-inc/autonomy-apps/main/docs/";
    return prefix + docFileName;
  }
}
