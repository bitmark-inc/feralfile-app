import 'dart:async';

import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/screen/artist_details/artist_details_page.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:autonomy_flutter/util/url_hepler.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:url_launcher/url_launcher.dart';

class UserAvatar extends StatelessWidget {
  final String? url;

  const UserAvatar({
    required this.url,
    super.key,
  });

  Widget _avatar(BuildContext context) {
    final avatarUrl = url;
    return avatarUrl != null
        ? Image.network(
            avatarUrl,
            fit: BoxFit.fill,
          )
        : AspectRatio(
            aspectRatio: 1,
            child: SvgPicture.asset('assets/images/default_avatat.svg'),
          );
  }

  @override
  Widget build(BuildContext context) => _avatar(context);
}

class UserProfile extends StatelessWidget {
  final FFUser user;
  final bool isShowUserRole;

  const UserProfile({
    required this.user,
    super.key,
    this.isShowUserRole = true,
  });

  String _userRole(FFUser user) {
    if (user.isArtist == true && user.isCurator == true) {
      return 'artist_curator'.tr();
    } else if (user.isArtist == true) {
      return 'artist'.tr();
    } else if (user.isCurator == true) {
      return 'curator'.tr();
    }
    return '';
  }

  Widget _userProfile(BuildContext context, FFUser user) {
    final theme = Theme.of(context);
    final subTitleStyle = theme.textTheme.ppMori400White12
        .copyWith(color: AppColor.auQuickSilver);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: UserAvatar(url: user.avatarUrl),
            ),
          ],
        ),
        const SizedBox(
          height: 8,
        ),
        if (isShowUserRole) ...[
          Text(
            _userRole(user),
            style: subTitleStyle,
          ),
        ],
        const SizedBox(
          height: 64,
        ),
        Text(
          user.displayAlias,
          style: theme.textTheme.ppMori700White24.copyWith(fontSize: 36),
        ),
        const SizedBox(
          height: 24,
        ),
        if (user is FFUserDetails && user.location != null) ...[
          Text(
            user.location!,
            style: subTitleStyle.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(
            height: 24,
          ),
        ],
        if (user is FFUserDetails &&
            user.website != null &&
            user.website!.isNotEmpty) ...[
          _artistUrl(context, user.website!),
          const SizedBox(
            height: 12,
          ),
        ],
        if (user.instagramUrl != null && user.instagramUrl!.isNotEmpty) ...[
          _artistUrl(context, user.instagramUrl!, title: 'Instagram'),
          const SizedBox(
            height: 12,
          ),
        ],

        if (user.twitterUrl != null && user.twitterUrl!.isNotEmpty) ...[
          _artistUrl(context, user.twitterUrl!, title: 'Twitter'),
          const SizedBox(
            height: 12,
          ),
        ],
        const SizedBox(
          height: 32,
        ),
        if (user.bio != null) ...[
          ReadMoreText(
            text: user.bio!,
            style: theme.textTheme.ppMori400White14,
          ),
          const SizedBox(
            height: 16,
          ),
        ],
        // Add more widgets here
      ],
    );
  }

  @override
  Widget build(BuildContext context) => _userProfile(context, user);

  Widget _artistUrl(BuildContext context, String url, {String? title}) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: () {
        unawaited(launchUrl(Uri.parse(url)));
      },
      child: Row(
        children: [
          Text(
            title ?? UrlHepler.shortenUrl(url),
            style: theme.textTheme.ppMori400White12
                .copyWith(color: AppColor.auQuickSilver),
          ),
          const SizedBox(
            width: 8,
          ),
          SvgPicture.asset(
            'assets/images/arrow_45.svg',
            width: 12,
            height: 12,
            colorFilter:
                const ColorFilter.mode(AppColor.auQuickSilver, BlendMode.srcIn),
          ),
        ],
      ),
    );
  }
}
