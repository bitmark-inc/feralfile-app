import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/view/text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class TextNamePlaylist extends StatefulWidget {
  final Function(String)? onEditPlaylistName;
  final FocusNode? focusNode;

  const TextNamePlaylist({
    required this.playList,
    super.key,
    this.onEditPlaylistName,
    this.focusNode,
  });

  final PlayListModel? playList;

  @override
  State<TextNamePlaylist> createState() => _TextNamePlaylistState();
}

class _TextNamePlaylistState extends State<TextNamePlaylist> {
  final _playlistNameC = TextEditingController();

  @override
  void initState() {
    _playlistNameC.text = widget.playList?.name ?? '';
    super.initState();
  }

  @override
  void dispose() {
    _playlistNameC.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant TextNamePlaylist oldWidget) {
    _playlistNameC.text = widget.playList?.name ?? '';
    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return TextFieldWidget(
      focusNode: widget.focusNode,
      hintText: tr('untitled'),
      controller: _playlistNameC,
      cursorColor: AppColor.white,
      style: theme.textTheme.ppMori700Black36.copyWith(color: AppColor.white),
      hintStyle: theme.textTheme.ppMori700Black36
          .copyWith(color: AppColor.disabledColor),
      textAlign: TextAlign.left,
      border: InputBorder.none,
      onChanged: (value) {
        widget.onEditPlaylistName?.call(value);
      },
    );
  }
}
