import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/constants.dart';
import 'package:autonomy_flutter/util/geolocation.dart';
import 'package:autonomy_flutter/util/postcard_extension.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/postcard_explain.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:nft_collection/models/asset_token.dart';
import 'package:flutter_swiper_view/flutter_swiper_view.dart';

import 'design_stamp.dart';

class PostcardExplain extends StatefulWidget {
  static const String tag = 'postcard_explain_screen';
  final PostcardExplainPayload payload;

  const PostcardExplain({Key? key, required this.payload}) : super(key: key);

  @override
  State<PostcardExplain> createState() => _PostcardExplainState();
}

class _PostcardExplainState extends State<PostcardExplain> {
  bool isGetLocation = true;

  @override
  void initState() {
    super.initState();
    injector<ConfigurationService>().setAutoShowPostcard(false);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: AppColor.primaryBlack,
      appBar: getBackAppBar(
        context,
        title: "how_it_works".tr(),
        onBack: () {
          Navigator.of(context).pop();
        },
        isWhite: false,
      ),
      body: Padding(
        padding: ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
        child: Swiper(
          itemBuilder: (context, index) {
            return Text(index.toString());
          },
          itemCount: 5,
          pagination: const SwiperPagination(
              builder: DotSwiperPaginationBuilder(
                  color: AppColor.auLightGrey,
                  activeColor: MomaPallet.lightYellow)),
          control: const SwiperControl(),
          loop: false,
        ),
      ),
    );
  }
}

class PostcardExplainPayload {
  final AssetToken asset;

  PostcardExplainPayload(this.asset);
}
