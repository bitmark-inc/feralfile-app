import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/view/text_field.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:autonomy_theme/autonomy_theme.dart';

class TextNamePlaylist extends StatefulWidget {
  final Function(String)? onEditPlaylistName;
  const TextNamePlaylist({
    Key? key,
    required this.playList,
    this.onEditPlaylistName,
  }) : super(key: key);

  final PlayListModel? playList;

  @override
  State<TextNamePlaylist> createState() => _TextNamePlaylistState();
}

class _TextNamePlaylistState extends State<TextNamePlaylist> {
  final _playlistNameC = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    _playlistNameC.text = widget.playList?.name ?? '';
    super.initState();
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
      focusNode: _focusNode,
      hintText: tr('untitled'),
      controller: _playlistNameC,
      cursorColor: theme.colorScheme.primary,
      style: theme.textTheme.ppMori700Black14,
      hintStyle: theme.textTheme.ppMori700Black14,
      textAlign: TextAlign.center,
      border: InputBorder.none,
      onChanged: (value) {
        widget.onEditPlaylistName?.call(value);
      },
      onFieldSubmitted: (value) {
        widget.onEditPlaylistName?.call(value);
      },
    );
  }
}
