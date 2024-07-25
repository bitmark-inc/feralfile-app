import 'dart:async';

import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';

class AuSearchBar extends StatefulWidget {
  final Function(String)? onChanged;
  final Function(String)? onSearch;
  final Function(String)? onClear;

  const AuSearchBar({super.key, this.onChanged, this.onSearch, this.onClear});

  @override
  State<AuSearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<AuSearchBar> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: AppColor.auGreyBackground,
        borderRadius: BorderRadius.circular(5),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          Expanded(
            child: Center(
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                style: theme.textTheme.ppMori400White12,
                cursorColor: AppColor.white,
                cursorWidth: 0.5,
                cursorHeight: 17,
                decoration: InputDecoration(
                  // contentPadding: const EdgeInsets.only(bottom: 10),
                  hintText: 'search_by_'.tr(),
                  hintStyle: theme.textTheme.ppMori400Grey12
                      .copyWith(color: AppColor.auQuickSilver),
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  _timer?.cancel();
                  _timer = Timer(const Duration(milliseconds: 300), () {
                    _callOnSearch(value);
                  });
                },
                onSubmitted: (value) {
                  _callOnSearch(value);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _callOnSearch(String value) {
    widget.onSearch?.call(value.trim());
  }
}

class ActionBar extends StatefulWidget {
  final AuSearchBar searchBar;
  final Function()? onCancel;

  const ActionBar({required this.searchBar, super.key, this.onCancel});

  @override
  State<ActionBar> createState() => _ActionBarState();
}

class _ActionBarState extends State<ActionBar> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: widget.searchBar,
          ),
          Container(
            color: Colors.yellow,
            child: IconButton(
              icon: const Padding(
                padding: EdgeInsets.all(5),
                child: Icon(
                  AuIcon.close,
                  size: 18,
                  color: AppColor.white,
                ),
              ),
              constraints: const BoxConstraints(maxWidth: 44, maxHeight: 44),
              onPressed: () {
                widget.onCancel?.call();
              },
            ),
          )
        ],
      );
}
