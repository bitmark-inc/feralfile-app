import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/mobile_controller/home_mobile_controller/ff_directories_bloc.dart';
import 'package:autonomy_flutter/screen/mobile_controller/models/directory.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/tappable_forward_row.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListDirectoryPage extends StatefulWidget {
  const ListDirectoryPage({super.key});

  @override
  State<ListDirectoryPage> createState() => _ListDirectoryPageState();
}

class _ListDirectoryPageState extends State<ListDirectoryPage>
    with AutomaticKeepAliveClientMixin {
  final FFDirectoriesBloc _bloc = injector<FFDirectoriesBloc>();

  @override
  void initState() {
    super.initState();
    // _bloc.add(GetDirectoriesEvent());
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: AppColor.auGreyBackground,
      body: SafeArea(
        child: BlocBuilder<FFDirectoriesBloc, FFDirectoriesState>(
          bloc: _bloc,
          builder: (context, state) {
            if (state.loading) {
              return _loadingView(context);
            } else if (state.error != null) {
              return _errorView(context, state.error!);
            } else {
              return _contentView(
                context,
                state,
              );
            }
          },
        ),
      ),
    );
  }

  Widget _loadingView(BuildContext context) {
    return Center(
      child: LoadingWidget(
        backgroundColor: AppColor.auGreyBackground,
      ),
    );
  }

  Widget _errorView(BuildContext context, Object error) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsets,
        child: Text(
          'Error: $error',
          style: theme.textTheme.ppMori400Black12,
        ),
      ),
    );
  }

  Widget _contentView(BuildContext context, FFDirectoriesState state) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 170),
          _header(context),
          const SizedBox(height: 110),
          _directoryList(context, state.directories),
          const SizedBox(height: 15),
          Padding(
            padding: ResponsiveLayout.pageHorizontalEdgeInsets,
            child: _myCollectionButton(context),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: ResponsiveLayout.pageHorizontalEdgeInsets,
      child: Row(
        children: [
          Expanded(
            child: Text(
              'INDEX',
              style: theme.textTheme.ppMori400White12,
            ),
          ),
          Text(
            'A-Z',
            style: theme.textTheme.ppMori400White12,
          )
        ],
      ),
    );
  }

  Widget _directoryList(BuildContext context, List<FFDirectory> directories) {
    final theme = Theme.of(context);
    return ListView.builder(
      shrinkWrap: true,
      itemCount: directories.length,
      itemBuilder: (context, index) {
        final directory = directories[index];
        return Column(
          children: [
            Padding(
              padding: ResponsiveLayout.pageHorizontalEdgeInsets
                  .copyWith(top: 10, bottom: 10),
              child: TappableForwardRow(
                onTap: () {},
                leftWidget: Text(
                  directory.name,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.ppMori400White12,
                ),
              ),
            ),
            addOnlyDivider(color: AppColor.primaryBlack),
          ],
        );
      },
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
        padding: EdgeInsets.all(ResponsiveLayout.padding),
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
