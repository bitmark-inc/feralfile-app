import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/mobile_controller/home_mobile_controller/ff_directories_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/home_mobile_controller/list_directories.dart';
import 'package:autonomy_flutter/screen/mobile_controller/record_controller.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class MobileControllerHomePage extends StatefulWidget {
  const MobileControllerHomePage({super.key, this.initialPageIndex = 0});

  final int initialPageIndex;

  @override
  State<MobileControllerHomePage> createState() =>
      _MobileControllerHomePageState();
}

class _MobileControllerHomePageState extends State<MobileControllerHomePage> {
  late int _currentPageIndex;
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _currentPageIndex = widget.initialPageIndex;
    _pageController = PageController(initialPage: _currentPageIndex);
    injector<FFDirectoriesBloc>().add(GetDirectoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const RecordControllerScreen(),
      const ListDirectoryPage(),
    ];
    return Scaffold(
      appBar: getDarkEmptyAppBar(AppColor.auGreyBackground),
      backgroundColor: AppColor.primaryBlack,
      body: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: const EdgeInsets.all(2),
          color: Colors.amberAccent,
          child: _buildPageView(
            pages,
          ),
        ),
      ),
    );
  }

  Widget _buildPageView(List<Widget> pages) {
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: pages.length,
          itemBuilder: (context, index) {
            return Container(
              child: pages[index],
              padding: EdgeInsets.all(2),
              color: Colors.red,
            );
          },
          onPageChanged: (index) {
            setState(() {
              _currentPageIndex = index;
            });
          },
        ),
        // fade effect on top
        Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: IgnorePointer(
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColor.auGreyBackground.withOpacity(0.0),
                      AppColor.auGreyBackground,
                    ],
                  ),
                ),
              ),
            )),
        _buildSwicher(context, _currentPageIndex),
      ],
    );
  }

  Widget _buildSwicher(BuildContext context, int currentIndex) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(top: 40),
        child: IconSwitcher(
          initialIndex: _currentPageIndex,
          items: [
            IconSwticherItem(
              icon: SvgPicture.asset(
                'assets/images/cycle.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              iconOnSelected: SvgPicture.asset(
                'assets/images/cycle.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              onTap: () {
                _pageController.jumpToPage(0);
              },
            ),
            IconSwticherItem(
              icon: SvgPicture.asset(
                'assets/images/list.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.grey,
                  BlendMode.srcIn,
                ),
              ),
              iconOnSelected: SvgPicture.asset(
                'assets/images/list.svg',
                colorFilter: const ColorFilter.mode(
                  Colors.white,
                  BlendMode.srcIn,
                ),
              ),
              onTap: () {
                _pageController.jumpToPage(1);
              },
            ),
          ],
        ),
      ),
    );
  }
}

class IconSwticherItem {
  IconSwticherItem({
    required this.icon,
    required this.iconOnSelected,
    this.onTap,
  });

  final Widget icon;
  final Widget? iconOnSelected;
  final Function? onTap;
}

class IconSwitcher extends StatefulWidget {
  const IconSwitcher({super.key, required this.items, this.initialIndex = 0});

  final List<IconSwticherItem> items;
  final int initialIndex;

  @override
  _IconSwitcherState createState() => _IconSwitcherState();
}

class _IconSwitcherState extends State<IconSwitcher> {
  late int selectedIndex;

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.initialIndex;
  }

  @override
  void didUpdateWidget(IconSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialIndex != widget.initialIndex) {
      setState(() {
        selectedIndex = widget.initialIndex;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = widget.items.length;
    final itemWidth = 56.0;
    final itemHeight = 34.0;
    final padding = 10.0;
    final borderWidth = 2.0;
    final width =
        itemWidth * itemCount + padding * (itemCount - 1) + borderWidth * 2;
    final height = itemHeight;

    return Stack(
      children: [
        AnimatedPositioned(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          left: selectedIndex * itemWidth + selectedIndex * padding,
          top: 0,
          bottom: 0,
          width: itemWidth + borderWidth * 2,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(50),
              border: Border.all(color: Colors.white, width: borderWidth),
            ),
          ),
        ),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
                color: Colors.white.withOpacity(0.4), width: borderWidth),
          ),
          child: Row(
            children: List.generate(itemCount, (index) {
              final item = widget.items[index];
              return Padding(
                padding: (index < itemCount - 1)
                    ? EdgeInsets.only(right: padding)
                    : EdgeInsets.zero,
                child: GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    item.onTap?.call();
                  },
                  child: Container(
                    width: itemWidth,
                    height: itemHeight,
                    alignment: Alignment.center,
                    child: selectedIndex == index
                        ? item.iconOnSelected ?? item.icon
                        : item.icon,
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}
