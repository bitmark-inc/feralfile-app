//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/editorial/editorial_page.dart';
import 'package:autonomy_flutter/screen/home/home_page.dart';
import 'package:autonomy_flutter/screen/scan_qr/scan_qr_page.dart';
import 'package:autonomy_flutter/util/au_icons.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:flutter/material.dart';

class HomeNavigationPage extends StatefulWidget {
  const HomeNavigationPage({Key? key}) : super(key: key);

  @override
  State<HomeNavigationPage> createState() => _HomeNavigationPageState();
}

class _HomeNavigationPageState extends State<HomeNavigationPage> {
  int _selectedIndex = 0;
  late PageController _pageController;
  late List<Widget> _pages;
  final GlobalKey<HomePageState> _homePageKey = GlobalKey();

  void _onItemTapped(int index) {
    if (index != 2) {
      setState(() {
        _selectedIndex = index;
      });
      _pageController.jumpToPage(_selectedIndex);
      if (index == 0) {
        _homePageKey.currentState?.refreshTokens();
      }
    } else {
      UIHelper.showDrawerAction(
        context,
        options: [
          OptionItem(
            title: 'Scan',
            icon: const Icon(
              AuIcon.scan,
            ),
            onTap: () {
              Navigator.pop(context);
              Navigator.of(context).pushNamed(
                AppRouter.scanQRPage,
                arguments: ScannerItem.GLOBAL,
              );
            },
          ),
          OptionItem(
              title: 'Settings',
              icon: const Icon(
                AuIcon.settings,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRouter.settingsPage);
              }),
          OptionItem(
              title: 'Help',
              icon: const Icon(
                AuIcon.help,
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamed(AppRouter.supportCustomerPage);
              }),
        ],
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _selectedIndex);
    _pages = <Widget>[
      HomePage(key: _homePageKey),
      const EditorialPage(),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      bottomNavigationBar: BottomNavigationBar(
        showSelectedLabels: false,
        showUnselectedLabels: false,
        currentIndex: _selectedIndex,
        unselectedItemColor: theme.disabledColor,
        selectedItemColor: theme.primaryColor,
        backgroundColor: theme.backgroundColor.withOpacity(0.95),
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(AuIcon.collection),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(AuIcon.discover),
            label: '',
          ),
          BottomNavigationBarItem(
            icon: Icon(AuIcon.drawer),
            label: '',
          ),
        ],
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: _pages,
      ),
    );
  }
}
