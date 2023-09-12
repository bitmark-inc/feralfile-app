import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:flutter/material.dart';

class PostcardDrawerItem extends StatefulWidget {
  final OptionItem item;

  const PostcardDrawerItem({
    Key? key,
    required this.item,
  }) : super(key: key);

  @override
  State<PostcardDrawerItem> createState() => _PostcardDrawerItemState();
}

class _PostcardDrawerItemState extends State<PostcardDrawerItem> {
  late bool isProcessing;

  @override
  void initState() {
    isProcessing = false;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final item = widget.item;
    final defaultTextStyle =
        theme.textTheme.moMASans700Black16.copyWith(fontSize: 18);
    final defaultProcessingTextStyle =
        defaultTextStyle.copyWith(color: AppColor.disabledColor);
    final child = Container(
      color: Colors.transparent,
      width: MediaQuery.of(context).size.width,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          vertical: 20,
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(
                  width: 15,
                ),
                SizedBox(
                    width: 30,
                    child: isProcessing
                        ? (item.iconOnProcessing ?? item.icon)
                        : item.icon),
                const SizedBox(
                  width: 18,
                ),
                Expanded(
                  child: Text(
                    item.title ?? '',
                    maxLines: 3,
                    style: isProcessing
                        ? item.titleStyleOnPrecessing ??
                            defaultProcessingTextStyle
                        : item.titleStyle ?? defaultTextStyle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    return GestureDetector(
      onTap: () async {
        if (isProcessing) return;
        setState(() {
          isProcessing = true;
        });
        await item.onTap?.call();
        setState(() {
          isProcessing = false;
        });
      },
      child: child,
    );
  }
}
