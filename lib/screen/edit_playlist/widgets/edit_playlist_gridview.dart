import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist.dart';
import 'package:autonomy_flutter/view/au_button_clipper.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class EditPlaylistGridView extends StatefulWidget {
  final List<AssetToken?> tokens;
  final Function(String tokenID, bool value)? onChangedSelect;
  final List<String>? selectedTokens;
  final Function(List<AssetToken?>) onReorder;
  final Function()? onAddTap;
  const EditPlaylistGridView({
    Key? key,
    required this.tokens,
    this.onChangedSelect,
    this.selectedTokens,
    required this.onReorder,
    this.onAddTap,
  }) : super(key: key);

  @override
  State<EditPlaylistGridView> createState() => _EditPlaylistGridViewState();
}

class _EditPlaylistGridViewState extends State<EditPlaylistGridView> {
  final int cellPerRowPhone = 3;
  final int cellPerRowTablet = 6;
  final double cellSpacing = 3.0;
  late int cellPerRow;

  @override
  void initState() {
    cellPerRow = ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();

    return ReorderableGridView.count(
      footer: [
        Visibility(
          visible: widget.tokens.isNotEmpty,
          child: GestureDetector(
            onTap: widget.onAddTap,
            child: const AddTokenWidget(),
          ),
        ),
      ],
      onDragStart: (dragIndex) {
        Vibrate.feedback(FeedbackType.light);
      },
      onReorder: (oldIndex, newIndex) {
        setState(() {
          final element = widget.tokens.removeAt(oldIndex);
          if (element != null) widget.tokens.insert(newIndex, element);
          widget.tokens.removeWhere((element) => element == null);
        });
        widget.onReorder.call(List.from(widget.tokens));
      },
      crossAxisCount: cellPerRow,
      crossAxisSpacing: cellSpacing,
      mainAxisSpacing: cellSpacing,
      children: widget.tokens
          .map(
            (e) => e != null
                ? ThubnailPlaylistItem(
                    key: ValueKey(e),
                    token: e,
                    cachedImageSize: cachedImageSize,
                    showTriggerOrder: true,
                    isSelected: widget.selectedTokens?.contains(e.id) ?? false,
                    onChanged: (value) {
                      widget.onChangedSelect?.call(e.id, value ?? false);
                    },
                  )
                : const SizedBox.shrink(),
          )
          .toList(),
    );
  }
}

class AddTokenWidget extends StatelessWidget {
  const AddTokenWidget({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipPath(
      clipper: AutonomyTopRightRectangleClipper(),
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.transparent,
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              border: Border.all(color: theme.primaryColor),
              borderRadius: BorderRadius.circular(64),
            ),
            child: Text(
              'add'.tr(),
              style: theme.textTheme.ppMori400Black12,
            ),
          ),
        ),
      ),
    );
  }
}
