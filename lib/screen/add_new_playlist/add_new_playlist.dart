import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_flutter/view/text_field.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';

class AddNewPlaylistScreen extends StatefulWidget {
  const AddNewPlaylistScreen({Key? key}) : super(key: key);

  @override
  State<AddNewPlaylistScreen> createState() => _AddNewPlaylistScreenState();
}

class _AddNewPlaylistScreenState extends State<AddNewPlaylistScreen> {
  final bloc = injector.get<AddNewPlaylistBloc>();
  final nftBloc = injector.get<NftCollectionBloc>();
  final _playlistNameC = TextEditingController();
  List<String> hiddenTokens = [];
  List<SentArtwork> sentArtworks = [];

  final _formKey = GlobalKey<FormState>();
  List<AssetToken> tokensPlaylist = [];

  @override
  void initState() {
    super.initState();
    hiddenTokens =
        injector<ConfigurationService>().getTempStorageHiddenTokenIDs();
    sentArtworks = injector<ConfigurationService>().getRecentlySentToken();
    injector<AccountService>().getAllAddresses().then((value) {
      nftBloc.add(RefreshTokenEvent(addresses: value));
      nftBloc.add(RequestIndexEvent(value));
    });
    bloc.add(InitPlaylist());
  }

  List<AssetToken> setupPlayList({
    required List<AssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    tokens.sort((a, b) {
      final aSource = a.source?.toLowerCase() ?? INDEXER_UNKNOWN_SOURCE;
      final bSource = b.source?.toLowerCase() ?? INDEXER_UNKNOWN_SOURCE;

      if (aSource == INDEXER_UNKNOWN_SOURCE &&
          bSource == INDEXER_UNKNOWN_SOURCE) {
        return b.lastUpdateTime.compareTo(a.lastUpdateTime);
      }

      if (aSource == INDEXER_UNKNOWN_SOURCE) return 1;
      if (bSource == INDEXER_UNKNOWN_SOURCE) return -1;

      return b.lastUpdateTime.compareTo(a.lastUpdateTime);
    });
    final expiredTime = DateTime.now().subtract(SENT_ARTWORK_HIDE_TIME);

    tokens = tokens
        .where(
          (element) =>
              !hiddenTokens.contains(element.id) &&
              !sentArtworks.any(
                (e) => e.isHidden(
                    tokenID: element.id,
                    address: element.ownerAddress,
                    timestamp: expiredTime),
              ),
        )
        .toList();

    tokensPlaylist = tokens;

    return tokensPlaylist;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<AddNewPlaylistBloc, AddNewPlaylistState>(
      bloc: bloc,
      listener: (context, state) {
        if (state.isAddSuccess == true) {
          Navigator.pop(context);
          Navigator.pushNamed(context, AppRouter.viewPlayListPage,
              arguments: state.playListModel);
        }
      },
      builder: (context, state) {
        final selectedCount = state.playListModel?.tokenIDs?.length ?? 0;
        final isSeletedAll = selectedCount == tokensPlaylist.length;
        return Scaffold(
          appBar: AppBar(
            elevation: 0,
            backgroundColor: theme.primaryColor,
            automaticallyImplyLeading: false,
            title: Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Text(
                    tr('back'),
                    style: theme.primaryTextTheme.button,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    if (selectedCount <= 0) {
                      return;
                    }
                    bloc.add(
                      CreatePlaylist(
                        name: _playlistNameC.text.isNotEmpty
                            ? _playlistNameC.text
                            : null,
                      ),
                    );
                  },
                  child: Text(
                    tr('save').toUpperCase(),
                    style: selectedCount == 0
                        ? theme.primaryTextTheme.button?.copyWith(
                            color: AppColor.secondaryDimGrey,
                          )
                        : theme.primaryTextTheme.button,
                  ),
                ),
              ],
            ),
          ),
          backgroundColor: theme.primaryColor,
          body: SafeArea(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      children: [
                        Center(
                          child: SvgPicture.asset(
                            "assets/images/penrose_moma.svg",
                            color: theme.colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        TextFieldWidget(
                          labelText: tr('playlist_name').toUpperCase(),
                          hintText: tr('untitled'),
                          controller: _playlistNameC,
                          cursorColor: theme.colorScheme.secondary,
                          style: theme.primaryTextTheme.headline1,
                          hintStyle: theme.textTheme.atlasSpanishGreyBold36,
                          border: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          focusedBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(
                              width: 2,
                              color: theme.colorScheme.secondary,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              Text(
                                tr(
                                  selectedCount > 1
                                      ? 'artworks_selected'
                                      : 'artwork_selected',
                                  args: [selectedCount.toString()],
                                ),
                                style: theme.textTheme.atlasWhiteMedium12,
                              ),
                              const Spacer(),
                              GestureDetector(
                                onTap: () => bloc.add(SelectItemPlaylist(
                                    isSelectAll: !isSeletedAll)),
                                child: Text(
                                  isSeletedAll
                                      ? tr('unselect_all')
                                      : tr('select_all'),
                                  style: theme.textTheme.atlasWhiteMedium12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child:
                        BlocConsumer<NftCollectionBloc, NftCollectionBlocState>(
                      bloc: nftBloc,
                      builder: (context, nftState) {
                        return NftCollectionGrid(
                          state: nftState.state,
                          tokens: nftState.tokens,
                          loadingIndicatorBuilder: loadingView,
                          customGalleryViewBuilder: (context, tokens) =>
                              _assetsWidget(
                            context,
                            setupPlayList(tokens: tokens),
                            onChanged: (tokenID, value) => bloc.add(
                              UpdateItemPlaylist(
                                  tokenID: tokenID, value: value),
                            ),
                            selectedTokens: state.playListModel?.tokenIDs,
                          ),
                        );
                      },
                      listener: (context, nftState) {
                        state.tokens = List.from(nftState.tokens);
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _assetsWidget(
    BuildContext context,
    List<AssetToken> tokens, {
    Function(String tokenID, bool value)? onChanged,
    List<String>? selectedTokens,
  }) {
    int cellPerRow =
        ResponsiveLayout.isMobile ? cellPerRowPhone : cellPerRowTablet;

    final estimatedCellWidth = MediaQuery.of(context).size.width / cellPerRow -
        cellSpacing * (cellPerRow - 1);
    final cachedImageSize = (estimatedCellWidth * 3).ceil();

    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cellPerRow,
        crossAxisSpacing: cellSpacing,
        mainAxisSpacing: cellSpacing,
      ),
      itemBuilder: (context, index) {
        return ThubnailPlaylistItem(
          token: tokens[index],
          cachedImageSize: cachedImageSize,
          isSelected: selectedTokens?.contains(tokens[index].id) ?? false,
          onChanged: (value) {
            onChanged?.call(tokens[index].id, value ?? false);
          },
        );
      },
      itemCount: tokens.length,
    );
  }
}

class ThubnailPlaylistItem extends StatefulWidget {
  final bool showSelect;
  final bool isSelected;
  final AssetToken token;
  final Function(bool?)? onChanged;
  final int cachedImageSize;
  const ThubnailPlaylistItem({
    Key? key,
    required this.token,
    required this.cachedImageSize,
    this.showSelect = true,
    this.isSelected = false,
    this.onChanged,
  }) : super(key: key);

  @override
  State<ThubnailPlaylistItem> createState() => _ThubnailPlaylistItemState();
}

class _ThubnailPlaylistItemState extends State<ThubnailPlaylistItem> {
  bool isSelected = false;

  @override
  void initState() {
    super.initState();
    isSelected = widget.isSelected;
  }

  @override
  void didUpdateWidget(covariant ThubnailPlaylistItem oldWidget) {
    setState(() {
      isSelected = widget.isSelected;
    });
    super.didUpdateWidget(oldWidget);
  }

  onChanged(value) {
    setState(() {
      isSelected = !isSelected;
      widget.onChanged?.call(isSelected);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () => onChanged(isSelected),
      child: Stack(
        children: [
          SizedBox(
            width: double.infinity,
            height: double.infinity,
            child: tokenGalleryWidget(
              context,
              widget.token,
              widget.cachedImageSize,
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Visibility(
              visible: widget.showSelect,
              child: Checkbox(
                checkColor: Colors.white,
                fillColor: MaterialStateProperty.all(theme.primaryColor),
                side: const BorderSide(color: Colors.white, width: 10),
                value: isSelected,
                shape: const CircleBorder(),
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Widget loadingView(BuildContext context) {
  final theme = Theme.of(context);
  return Center(
      child: Column(
    children: [
      CircularProgressIndicator(
        backgroundColor: Colors.white60,
        color: theme.colorScheme.secondary,
        strokeWidth: 2,
      ),
    ],
  ));
}
