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
  bool isEditing = false;
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
    return !isEditing
        ? Row(
            children: [
              Expanded(
                child: Text(
                  _playlistNameC.text.isNotEmpty
                      ? _playlistNameC.text
                      : tr('untitled'),
                  style: _playlistNameC.text.isEmpty
                      ? theme.textTheme.atlasSpanishGreyBold36
                      : theme.textTheme.headline1,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() {
                    isEditing = true;
                    _focusNode.requestFocus();
                  });
                },
                icon: Icon(
                  Icons.edit,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          )
        : TextFieldWidget(
            focusNode: _focusNode,
            hintText: tr('untitled'),
            controller: _playlistNameC,
            cursorColor: theme.colorScheme.primary,
            style: theme.textTheme.headline1,
            hintStyle: theme.textTheme.atlasSpanishGreyBold36,
            border: UnderlineInputBorder(
              borderSide: BorderSide(
                width: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                width: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                width: 2,
                color: theme.colorScheme.primary,
              ),
            ),
            onFieldSubmitted: (value) {
              setState(() {
                isEditing = false;
              });
              widget.onEditPlaylistName?.call(value);
            },
          );
  }
}
