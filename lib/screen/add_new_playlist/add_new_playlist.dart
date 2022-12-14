import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/model/sent_artwork.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist_bloc.dart';
import 'package:autonomy_flutter/screen/add_new_playlist/add_new_playlist_state.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:nft_collection/nft_collection.dart';
import 'package:autonomy_flutter/service/account_service.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:roundcheckbox/roundcheckbox.dart';
import '../../util/token_ext.dart';

class AddNewPlaylistScreen extends StatefulWidget {
  final PlayListModel? playListModel;
  const AddNewPlaylistScreen({Key? key, this.playListModel}) : super(key: key);

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
    _playlistNameC.text = widget.playListModel?.name ?? '';
    bloc.add(InitPlaylist(playListModel: widget.playListModel));
  }

  List<AssetToken> setupPlayList({
    required List<AssetToken> tokens,
    List<String>? selectedTokens,
  }) {
    tokens.sortToken();

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
          Navigator.pop(context, state.playListModel);
        }
      },
      builder: (context, state) {
        final selectedCount = tokensPlaylist
            .where(
                (element) => state.selectedIDs?.contains(element.id) ?? false)
            .length;
        final isSeletedAll = selectedCount == tokensPlaylist.length;
        return Scaffold(
          backgroundColor: theme.primaryColor,
          body: AnnotatedRegion<SystemUiOverlayStyle>(
            value: SystemUiOverlayStyle.light,
            child: SafeArea(
              bottom: false,
              child: Stack(
                children: [
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 40,
                              ),
                              Align(
                                alignment: Alignment.centerLeft,
                                child: SvgPicture.asset(
                                  "assets/images/penrose_moma.svg",
                                  color: theme.colorScheme.secondary,
                                  width: 50,
                                ),
                              ),
                              const SizedBox(
                                height: 30,
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tr('playlist_name'),
                                    style: theme.textTheme.ppMori400Grey12,
                                  ),
                                  TextFormField(
                                    controller: _playlistNameC,
                                    cursorColor: theme.colorScheme.secondary,
                                    style:
                                        theme.primaryTextTheme.ppMori700White24,
                                    decoration: InputDecoration(
                                      hintText: tr('untitled'),
                                      hintStyle:
                                          theme.textTheme.ppMori700Grey24,
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
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Row(
                                  children: [
                                    Text(
                                      tr(
                                        selectedCount != 1
                                            ? 'artworks_selected'
                                            : 'artwork_selected',
                                        args: [selectedCount.toString()],
                                      ),
                                      style: theme.textTheme.ppMori400White12,
                                    ),
                                    const Spacer(),
                                    GestureDetector(
                                      onTap: () => bloc.add(SelectItemPlaylist(
                                          isSelectAll: !isSeletedAll)),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 4,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border.all(
                                            color: theme.disableColor,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(64),
                                        ),
                                        child: Text(
                                          isSeletedAll
                                              ? tr('unselect_all')
                                              : tr('select_all'),
                                          style:
                                              theme.textTheme.ppMori400Grey12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: BlocConsumer<NftCollectionBloc,
                              NftCollectionBlocState>(
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
                                  selectedTokens: state.selectedIDs,
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
                  Positioned(
                    bottom: 30,
                    child: SizedBox(
                      width: MediaQuery.of(context).size.width,
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            PrimaryButton(
                              onTap: () {
                                Navigator.pop(context);
                              },
                              width: 170,
                              text: tr('undo'),
                              color: theme.auLightGrey,
                            ),
                            PrimaryButton(
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
                              width: 170,
                              text: tr('save'),
                              color: selectedCount <= 0
                                  ? theme.auLightGrey
                                  : theme.auSuperTeal,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
  final bool showTriggerOrder;

  const ThubnailPlaylistItem({
    Key? key,
    required this.token,
    required this.cachedImageSize,
    this.showSelect = true,
    this.isSelected = false,
    this.onChanged,
    this.showTriggerOrder = false,
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
            top: 10,
            right: 10,
            child: Visibility(
              visible: widget.showSelect,
              child: RoundCheckBox(
                border: Border.all(
                  color: theme.colorScheme.secondary,
                  width: 1.5,
                ),
                uncheckedColor: theme.colorScheme.primary,
                uncheckedWidget: Container(
                  padding: const EdgeInsets.all(4),
                ),
                checkedColor: theme.colorScheme.primary,
                checkedWidget: Container(
                  padding: const EdgeInsets.all(4),
                  child: SvgPicture.asset(
                    'assets/images/check-icon.svg',
                    color: theme.colorScheme.secondary,
                  ),
                ),
                animationDuration: const Duration(milliseconds: 100),
                isChecked: isSelected,
                size: 24,
                onTap: onChanged,
              ),
            ),
          ),
          Visibility(
            visible: widget.showTriggerOrder,
            child: Positioned(
              bottom: 10,
              left: 0,
              right: 0,
              child: Align(
                child: Column(
                  children: [
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(
                      height: 2,
                    ),
                    Container(
                      width: 24,
                      height: 2,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(60),
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                  ],
                ),
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
