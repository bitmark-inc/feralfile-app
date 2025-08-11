import 'package:autonomy_flutter/screen/mobile_controller/constants/ui_constants.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels/channels_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/playlists_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/works/works_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/header.dart';
import 'package:flutter/material.dart';

class ListDirectoryPage extends StatefulWidget {
  const ListDirectoryPage({super.key});

  @override
  State<ListDirectoryPage> createState() => _ListDirectoryPageState();
}

class _ListDirectoryPageState extends State<ListDirectoryPage>
    with AutomaticKeepAliveClientMixin {
  late PageController _pageController;
  int _selectedPageIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    final pages = [
      const PlaylistsPage(),
      const ChannelsPage(),
      const WorksPage(),
    ];
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: MediaQuery.of(context).padding.top,
          ),
          const SizedBox(
            height: 154,
          ),
          HeaderWidget(
            selectedIndex: _selectedPageIndex,
            onPageChanged: (index) {
              setState(() {
                _selectedPageIndex = index;
              });
              _pageController.jumpToPage(index);
            },
          ),
          const SizedBox(height: UIConstants.detailPageHeaderPadding),
          // _myCollectionButton(context),
          Expanded(
            child: PageView.builder(
              physics: const NeverScrollableScrollPhysics(),
              controller: _pageController,
              itemCount: pages.length,
              itemBuilder: (context, index) {
                return pages[index];
              },
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
