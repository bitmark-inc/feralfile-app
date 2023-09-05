import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/followee.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
import 'package:autonomy_flutter/gateway/pubdoc_api.dart';
import 'package:autonomy_flutter/model/suggested_artist.dart';
import 'package:autonomy_flutter/screen/bloc/identity/identity_bloc.dart';
import 'package:autonomy_flutter/screen/discover/following_bloc.dart';
import 'package:autonomy_flutter/service/domain_service.dart';
import 'package:autonomy_flutter/service/followee_service.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/string_ext.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/add_button.dart';
import 'package:autonomy_flutter/view/au_text_field.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

class FollowingPage extends StatefulWidget {
  static const tag = "following_page";

  const FollowingPage({Key? key}) : super(key: key);

  @override
  State<FollowingPage> createState() => _FollowingPageState();
}

class _FollowingPageState extends State<FollowingPage> with RouteAware {
  final TextEditingController _controller = TextEditingController();
  GlobalKey _followingListKey = GlobalKey();
  bool _validAddress = false;
  String? _address;
  Timer? _timer;
  final List<SuggestedArtist> _suggestedArtistList = [];
  final FolloweeService _followeeService = injector<FolloweeService>();
  static const int _suggestedArtistLimit = 3;

  @override
  void initState() {
    super.initState();
    context.read<FollowingBloc>().add(GetFolloweeEvent());
    _syncFolloweeDatabase();
    WidgetsBinding.instance.addPostFrameCallback((context) {
      _fetchSuggestedArtists();
    });
  }

  @override
  void didPopNext() {
    super.didPopNext();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  Future<void> _syncFolloweeDatabase() async {
    final isUpdate = await _followeeService.syncFromServer();
    isUpdate ? _updateFolloweeList() : null;
  }

  Future<void> _fetchSuggestedArtists() async {
    final suggestedList =
        await injector<PubdocAPI>().getSuggestedArtistsFromGithub();
    final followeeList = await _followeeService
        .getFromAddresses(suggestedList.map((e) => e.address).toList());

    suggestedList.removeWhere((element) =>
        followeeList.any((followee) => followee.address == element.address));
    _suggestedArtistList.addAll(suggestedList);
    _suggestedArtistList.shuffle();
    setState(() {});
  }

  void _updateFolloweeList() {
    setState(() {
      _followingListKey = GlobalKey();
    });
  }

  void _refreshAddress() {
    setState(() {
      _validAddress = false;
      _address = null;
    });
  }

  void _setAddress(String value) {
    setState(() {
      _validAddress = true;
      _address = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(context,
          onBack: () => Navigator.pop(context),
          isWhite: false,
          title: "discover_feed_addresses".tr()),
      backgroundColor: AppColor.primaryBlack,
      body: SingleChildScrollView(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Column(
            children: [
              _addAddress(context),
              _suggestedArtists(context),
              addTitleSpace(),
              FolloweesList(key: _followingListKey),
            ],
          )),
    );
  }

  Widget _addAddress(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        addTitleSpace(),
        AuTextField(
          title: "",
          placeholder: "enter_or_paste_address".tr(),
          isDark: true,
          widePadding: true,
          controller: _controller,
          onChanged: (valueChanged) {
            _refreshAddress();
            _timer?.cancel();
            _timer = Timer(const Duration(milliseconds: 500), () async {
              final value = valueChanged.trim();
              final cryptoType = CryptoType.fromAddress(value);
              if (cryptoType != CryptoType.UNKNOWN) {
                _setAddress(value);
                return;
              }

              final appDb = injector<AppDatabase>();
              final ethAddress = await DomainService.getEthAddress(value);
              if (ethAddress != null) {
                _setAddress(ethAddress);
                appDb.identityDao
                    .insertIdentity(Identity(ethAddress, 'ethereum', value));
                return;
              }

              final tezosAddress = await DomainService.getTezosAddress(value);
              if (tezosAddress != null) {
                _setAddress(tezosAddress);
                appDb.identityDao
                    .insertIdentity(Identity(tezosAddress, 'tezos', value));
                return;
              }

              _refreshAddress();
            });
          },
          suffix: Padding(
            padding: const EdgeInsets.only(right: 10),
            child: _validAddress && _address != null
                ? AddButton(
                    onTap: () {
                      _followeeService.addArtistManual(_address!).then((value) {
                        _refreshAddress();
                        _controller.clear();
                        _updateFolloweeList();
                      });
                    },
                  )
                : SvgPicture.asset(
                    "assets/images/joinFile.svg",
                    colorFilter: const ui.ColorFilter.mode(
                        AppColor.auGrey, BlendMode.srcIn),
                  ),
          ),
        ),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.only(left: 20),
          child: Text(
            "add_following_desc".tr(),
            style: theme.textTheme.ppMori400Grey12
                .copyWith(color: AppColor.auQuickSilver),
          ),
        ),
      ],
    );
  }

  Widget _suggestedArtists(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        addTitleSpace(),
        Text("suggested".tr(), style: theme.textTheme.ppMori400White14),
        addDivider(color: AppColor.auQuickSilver),
        _suggestedArtistsList(context),
      ],
    );
  }

  Widget _suggestedArtistsList(BuildContext context) {
    return ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        shrinkWrap: true,
        itemCount: _suggestedArtistLimit < _suggestedArtistList.length
            ? _suggestedArtistLimit
            : _suggestedArtistList.length,
        itemBuilder: (context, index) {
          return _suggestedArtistItem(context, _suggestedArtistList[index]);
        });
  }

  Widget _suggestedArtistItem(BuildContext context, SuggestedArtist artist) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              artist.domain.isNotEmpty ? artist.domain : artist.name,
              style: theme.textTheme.ppMori700White14,
            ),
          ),
          AddButton(
            onTap: () {
              _followeeService.addArtistManual(artist.address).then((value) {
                _suggestedArtistList.remove(artist);
                if (artist.domain.isNotEmpty) {
                  injector<AppDatabase>().identityDao.insertIdentity(Identity(
                      artist.address, artist.blockchain, artist.domain));
                }
                _updateFolloweeList();
              });
            },
          ),
        ],
      ),
    );
  }
}

class FolloweesList extends StatefulWidget {
  const FolloweesList({Key? key}) : super(key: key);

  @override
  State<FolloweesList> createState() => _FolloweesListState();
}

class _FolloweesListState extends State<FolloweesList> {
  @override
  void initState() {
    super.initState();
    context.read<FollowingBloc>().add(GetFolloweeEvent());
  }

  Followee? _selectedFollowee;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return BlocConsumer<FollowingBloc, FollowingState>(
        builder: (context, state) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("added".tr(), style: theme.textTheme.ppMori400White14),
          addDivider(color: AppColor.auQuickSilver),
          _followeesList(context, state.followees),
        ],
      );
    }, listener: (context, state) {
      context.read<IdentityBloc>().add(
          GetIdentityEvent(state.followees.map((e) => e.address).toList()));
    });
  }

  Widget _followeesList(BuildContext context, List<Followee> followees) {
    return BlocBuilder<IdentityBloc, IdentityState>(builder: (context, state) {
      return ListView.builder(
          physics: const NeverScrollableScrollPhysics(),
          shrinkWrap: true,
          itemCount: followees.length,
          itemBuilder: (context, index) {
            return _followeeItem(context, followees[index],
                state.identityMap[followees[index].address]);
          });
    });
  }

  Widget _followeeItem(
      BuildContext context, Followee followee, String? identity) {
    final theme = Theme.of(context);
    final hasName = identity != null && identity.isNotEmpty;
    final color =
        followee == _selectedFollowee ? AppColor.auQuickSilver : AppColor.white;
    final name = hasName ? identity : followee.address.maskOnly(5);
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 10, 10, 10),
      child: Row(
        children: [
          Text(name,
              style: theme.textTheme.ppMori700White14.copyWith(color: color)),
          const Spacer(),
          followee.canRemove
              ? RemoveButton(
                  onTap: () async {
                    setState(() {
                      _selectedFollowee = followee;
                    });
                    await UIHelper.showMessageAction(
                        context, "is_remove_from_feed".tr(args: [name]), "",
                        closeButton: "cancel".tr(),
                        actionButton: "remove_from_feed".tr(), onAction: () {
                      injector<FolloweeService>()
                          .removeArtistManual(followee)
                          .then((value) {
                        Navigator.pop(context);
                        context.read<FollowingBloc>().add(GetFolloweeEvent());
                      });
                    });
                    setState(() {
                      _selectedFollowee = null;
                    });
                  },
                  color: color,
                )
              : GestureDetector(
                  onTap: () async {
                    setState(() {
                      _selectedFollowee = followee;
                    });
                    await UIHelper.showInfoDialog(context,
                        "why_can_remove".tr(), "why_can_remove_desc".tr(),
                        closeButton: "close".tr());

                    setState(() {
                      _selectedFollowee = null;
                    });
                  },
                  child: SvgPicture.asset(
                    "assets/images/iconInfo.svg",
                    colorFilter: ui.ColorFilter.mode(color, BlendMode.srcIn),
                  ),
                )
        ],
      ),
    );
  }
}
