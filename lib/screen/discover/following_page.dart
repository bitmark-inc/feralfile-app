import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/entity/followee.dart';
import 'package:autonomy_flutter/database/entity/identity.dart';
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

class _FollowingPageState extends State<FollowingPage> {
  final TextEditingController _controller = TextEditingController();
  GlobalKey _followingListKey = GlobalKey();
  bool _validAddress = false;
  String? _address;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    context.read<FollowingBloc>().add(GetFolloweeEvent());
    _syncFolloweeDatabase();
  }

  Future<void> _syncFolloweeDatabase() async {
    final isUpdate = await injector<FolloweeService>().syncFromServer();
    isUpdate ? _updateFolloweeList() : null;
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
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getBackAppBar(context,
          onBack: () => Navigator.pop(context),
          isWhite: false,
          title: "addresses".tr()),
      backgroundColor: theme.primaryColor,
      body: SingleChildScrollView(
          padding: ResponsiveLayout.pageHorizontalEdgeInsets,
          child: Column(
            children: [
              addTitleSpace(),
              _addAddress(context),
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
                      injector<FolloweeService>()
                          .addArtistManual(_address!)
                          .then((value) {
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
        Text(
          "add_following_desc".tr(),
          style: theme.textTheme.ppMori400Grey12
              .copyWith(color: AppColor.auQuickSilver),
        ),
      ],
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
    final color = hasName && followee != _selectedFollowee
        ? AppColor.white
        : AppColor.auQuickSilver;
    final name = hasName ? identity : followee.address.maskOnly(5);
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Text(name,
              style: theme.textTheme.ppMori400White14.copyWith(color: color)),
          const Spacer(),
          RemoveButton(
            onTap: () async {
              if (followee.type == MANUAL_ADDED_ARTIST || true) {
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
              }
            },
            color: color,
          )
        ],
      ),
    );
  }
}
