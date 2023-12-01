//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

class CarouselWithIndicator extends StatefulWidget {
  final List<Widget> items;

  const CarouselWithIndicator({required this.items, super.key});

  @override
  State<StatefulWidget> createState() => _CarouselWithIndicatorState();
}

class _CarouselWithIndicatorState extends State<CarouselWithIndicator> {
  int _current = 0;
  final CarouselController _controller = CarouselController();

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) {
      return Container();
    }
    if (widget.items.length == 1) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        child: widget.items[0],
      );
    }
    return Column(children: [
      CarouselSlider(
        items: widget.items
            .map((e) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16), child: e))
            .toList(),
        carouselController: _controller,
        options: CarouselOptions(
          aspectRatio: 345 / 173,
          onPageChanged: (index, reason) {
            setState(() {
              _current = index;
            });
          },
          viewportFraction: 1,
        ),
      ),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: widget.items
            .asMap()
            .entries
            .map((entry) => GestureDetector(
                  onTap: () => unawaited(_controller.animateToPage(entry.key)),
                  child: Container(
                    width: 12,
                    height: 12,
                    margin:
                        const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (Theme.of(context).brightness == Brightness.dark
                                ? Colors.white
                                : Colors.black)
                            .withOpacity(_current == entry.key ? 0.9 : 0.4)),
                  ),
                ))
            .toList(),
      ),
    ]);
  }
}
