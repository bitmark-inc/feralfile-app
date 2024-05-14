import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ExhibitionPostView extends StatelessWidget {
  final Post post;

  const ExhibitionPostView({
    required this.post,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, y');
    final timeFormat = DateFormat('HH:mm');
    return Center(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: AppColor.auGreyBackground,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                post.displayType,
                style: theme.textTheme.ppMori400White12,
              ),
              const SizedBox(height: 30),
              Image.network(
                post.thumbnailUrl,
                fit: BoxFit.fitWidth,
              ),
              const SizedBox(height: 20),
              Text(
                post.title,
                style: theme.textTheme.ppMori700White14,
              ),
              if (post.type != 'close-up') ...[
                const SizedBox(height: 20),
                Text(
                  'Date: ${dateFormat.format(post.dateTime ?? post.createdAt)}',
                  style: theme.textTheme.ppMori400White14,
                ),
                Text(
                  'Time: ${timeFormat.format(post.dateTime ?? post.createdAt)}',
                  style: theme.textTheme.ppMori400White14,
                ),
              ],
              if (post.author != null) ...[
                const SizedBox(height: 10),
                Text(
                  'by ${post.author}',
                  style: theme.textTheme.ppMori400White12,
                ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {},
                child: Text(
                  post.type == 'close-up' ? 'read_more'.tr() : 'watch'.tr(),
                  style: theme.textTheme.ppMori400White14.copyWith(
                    decoration: TextDecoration.underline,
                    decorationColor: AppColor.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
