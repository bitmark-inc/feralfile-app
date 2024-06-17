import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class ExhibitionPostView extends StatefulWidget {
  final Post post;
  final String exhibitionID;

  const ExhibitionPostView({
    required this.post,
    required this.exhibitionID,
    super.key,
  });

  @override
  State<ExhibitionPostView> createState() => _ExhibitionPostViewState();
}

class _ExhibitionPostViewState extends State<ExhibitionPostView> {
  late String? thumbnailUrl;
  late int loadThumbnailFailedCount;

  @override
  void initState() {
    thumbnailUrl = widget.post.thumbnailUrls[0];
    loadThumbnailFailedCount = 0;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dateFormat = DateFormat('EEEE, MMM d, y');
    final timeFormat = DateFormat('HH:mm');
    final dateTime = widget.post.dateTime ?? widget.post.createdAt;
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
                widget.post.displayType,
                style: theme.textTheme.ppMori400White12,
              ),
              const SizedBox(height: 30),
              _buildThumbnailWidget(),
              const SizedBox(height: 20),
              Text(
                widget.post.title,
                style: theme.textTheme.ppMori700White14,
              ),
              if (widget.post.type != 'close-up') ...[
                const SizedBox(height: 20),
                Text(
                  'Date: ${dateFormat.format(dateTime)}',
                  style: theme.textTheme.ppMori400White14,
                ),
                Text(
                  'Time: ${timeFormat.format(dateTime)}',
                  style: theme.textTheme.ppMori400White14,
                ),
              ],
              if (widget.post.author?.isNotEmpty ?? false) ...[
                const SizedBox(height: 10),
                Text(
                  'by ${widget.post.author}',
                  style: theme.textTheme.ppMori400White12,
                ),
              ],
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () async {
                  await injector<NavigationService>()
                      .openFeralFilePostPage(widget.post, widget.exhibitionID);
                },
                child: Text(
                  widget.post.type == 'close-up'
                      ? 'read_more'.tr()
                      : 'watch'.tr(),
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

  Widget _buildThumbnailWidget() => Image.network(
        thumbnailUrl!,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          loadThumbnailFailedCount++;
          if (loadThumbnailFailedCount >= widget.post.thumbnailUrls.length) {
            return const SizedBox();
          }
          thumbnailUrl = widget.post.thumbnailUrls[loadThumbnailFailedCount];
          return _buildThumbnailWidget();
        },
      );
}
