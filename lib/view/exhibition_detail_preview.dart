import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:autonomy_flutter/view/header.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:collection/collection.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ExhibitionPreview extends StatelessWidget {
  ExhibitionPreview({required this.exhibition, super.key});

  final _navigationService = injector<NavigationService>();

  final Exhibition exhibition;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subTextStyle = theme.textTheme.ppMori400Grey12
        .copyWith(color: AppColor.feralFileMediumGrey);
    final artistTextStyle = theme.textTheme.ppMori400White16.copyWith(
      decoration: TextDecoration.underline,
      decorationColor: Colors.white,
    );

    return Container(
      padding: const EdgeInsets.only(left: 14, right: 14, bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: CachedNetworkImage(
              imageUrl: exhibition.coverUrl,
              fit: BoxFit.fitWidth,
            ),
          ),
          HeaderView(
            title: exhibition.title,
            padding: const EdgeInsets.symmetric(vertical: 20),
          ),
          if (exhibition.curator != null) ...[
            Text('curator'.tr(), style: subTextStyle),
            const SizedBox(height: 3),
            GestureDetector(
              child: Text(exhibition.curator!.alias,
                  style: artistTextStyle.copyWith()),
              onTap: () async {
                await _navigationService
                    .openFeralFileCuratorPage(exhibition.curator!.alias);
              },
            ),
          ],
          const SizedBox(height: 10),
          Text('group_exhibition'.tr(), style: subTextStyle),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              children: exhibition.artists!
                  .map((e) {
                    final isLast = exhibition.artists!.last == e;
                    return [
                      TextSpan(
                          style: artistTextStyle,
                          recognizer: TapGestureRecognizer()
                            ..onTap = () async {
                              await _navigationService
                                  .openFeralFileArtistPage(e.alias);
                            },
                          text: e.alias),
                      if (!isLast)
                        const TextSpan(
                          text: ', ',
                        )
                    ];
                  })
                  .flattened
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}
