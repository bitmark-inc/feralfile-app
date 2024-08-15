import 'package:autonomy_flutter/model/ff_user.dart';
import 'package:autonomy_flutter/util/feralfile_artist_ext.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ListUserView extends StatefulWidget {
  final List<FFUser> users;
  final Function(FFUser) onArtistSelected;

  const ListUserView(
      {required this.users, required this.onArtistSelected, super.key});

  @override
  State<ListUserView> createState() => _ListUserViewState();
}

class _ListUserViewState extends State<ListUserView> {
  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 102.0 / 129,
            crossAxisSpacing: 24,
            mainAxisSpacing: 30,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final user = widget.users[index];
              return GestureDetector(
                onTap: () {
                  widget.onArtistSelected(user);
                },
                child: Container(
                  color: Colors.transparent,
                  child: _artistItem(context, user),
                ),
              );
            },
            childCount: widget.users.length,
          )),
    );
  }

  Widget _artistAvatar(BuildContext context, FFUser user) {
    final avatarUrl = user.avatarUrl;
    return avatarUrl != null
        ? Image.network(
            avatarUrl,
            fit: BoxFit.fitWidth,
          )
        : SvgPicture.asset(
            'assets/images/default_avatat.svg',
            fit: BoxFit.fitWidth,
          );
  }

  Widget _artistItem(BuildContext context, FFUser user) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _artistAvatar(context, user)),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayAlias,
                  style: theme.textTheme.ppMori400White12,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            )),
          ],
        ),
      ],
    );
  }
}
