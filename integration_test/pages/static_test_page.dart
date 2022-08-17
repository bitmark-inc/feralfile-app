//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

final releaseNotes = find.text("Release notes");
final versionFinder = find.byKey(const Key("version"));
final privacyPolicy = find.text("Privacy Policy");
final eula = find.text("EULA");

Finder mdObj = find.byType(Markdown);
Finder mdGithub = find.byKey(const Key("githubMarkdown"));
//Markdown releaseNotesMD = releaseNotesFinder.evaluate().single.widget as Markdown;
//Finder versionWidget = versionFinder.evaluate().single.widget as Text;

String getStringFromMarkdown(Finder md, int from, int to){
  return getMarkdownData(md).substring(from,to)?? "";
}
String getVersion(Finder versionF){
  Text str = versionF.evaluate().single.widget as Text;
  return str.data?.substring(8,str.data?.indexOf("("))?? "-";
}
String getMarkdownData(Finder mdFinder){
  Markdown md = mdFinder.evaluate().single.widget as Markdown;
  return md.data;
}