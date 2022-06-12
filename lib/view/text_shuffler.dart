import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class TextShuffler extends StatefulWidget {
  final String text;
  final TextStyle? style;
  const TextShuffler({Key? key, required this.text, required this.style})
      : super(key: key);

  @override
  State<TextShuffler> createState() => _TextShufflerState();
}

enum ShufflerStep { dashes, filling, finalizing, finished }

class _TextShufflerState extends State<TextShuffler> {
  String _targetText = '';
  int _targetTextLength = 0;
  String _currentText = '';
  int _numberOfInitialDashes = 0;
  ShufflerStep _step = ShufflerStep.dashes;
  final characters =
      "AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890!@#\$%^&*-=";
  Random _rnd = Random();

  @override
  void initState() {
    _targetText = widget.text;
    _targetTextLength = _targetText.length;
    _numberOfInitialDashes = (_targetTextLength * 0.25).round();
    _shuffle();

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentText,
      style: widget.style,
    );
  }

  void _shuffle() {
    Timer.periodic(Duration(milliseconds: ((250) / _targetTextLength).round()),
        (timer) {
      late String updatedText;
      switch (_step) {
        case ShufflerStep.dashes:
          updatedText = _addDashes();
          break;

        case ShufflerStep.filling:
          updatedText = _fillRandomPositions();
          break;

        case ShufflerStep.finalizing:
          updatedText = _finalizeRandomPositions();
          break;

        case ShufflerStep.finished:
          timer.cancel();
          return;

        default:
          return;
      }
      setState(() {
        _currentText = updatedText;
      });
    });
  }

  String _addDashes() {
    if (_currentText.length >= _numberOfInitialDashes) {
      _step = ShufflerStep.filling;
      return _currentText;
    }

    return _currentText + "-";
  }

  String _fillRandomPositions() {
    if (_currentText.length < _targetTextLength) {
      final randChar = _randomCharacter();
      final randIndex = _rnd.nextInt(_currentText.length);
      return _currentText.replaceRange(randIndex, randIndex + 1,
          randChar + _currentText[randIndex]); // insert
    } else {
      _step = ShufflerStep.finalizing;
      return _currentText;
    }
  }

  String _finalizeRandomPositions() {
    if (_currentText == _targetText) {
      _step = ShufflerStep.finished;
      return _currentText;
    }

    final randIndex = _rnd.nextInt(_currentText.length);
    if (_currentText[randIndex] == _targetText[randIndex]) {
      return _finalizeRandomPositions();
    }

    return _currentText.replaceRange(
        randIndex, randIndex + 1, _targetText[randIndex]); // repace
  }

  String _randomCharacter() => characters[_rnd.nextInt(characters.length)];
}
