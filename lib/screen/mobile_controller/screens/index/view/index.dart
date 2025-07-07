import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/channels_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/collection_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/playlists/playlists_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/view/works_page.dart';
import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/header.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

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
      const CollectionPage(),
    ];
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderWidget(
            selectedIndex: _selectedPageIndex,
            onPageChanged: (index) {
              setState(() {
                _selectedPageIndex = index;
              });
              _pageController.jumpToPage(index);
            },
          ),
          const SizedBox(height: 45),
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

  Widget _myCollectionButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle navigation to My Collection
        Navigator.of(context).pushNamed(
          AppRouter.oldHomePage,
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppColor.primaryBlack,
          borderRadius: BorderRadius.circular(90),
        ),
        padding: ResponsiveLayout.paddingAll,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'My Collection',
              style: Theme.of(context).textTheme.ppMori400White12,
            ),
            const SizedBox(width: 20),
            SvgPicture.asset(
              'assets/images/arraw-left.svg',
            ),
          ],
        ),
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
