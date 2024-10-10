import 'dart:async';

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/play_list_model.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/playlist_service.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/feralfile_cache_network_image.dart';
import 'package:autonomy_flutter/view/primary_button.dart';
import 'package:feralfile_app_theme/feral_file_app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class PlaylistActivationPagePayload {
  final PlayListModel playlist;

  PlaylistActivationPagePayload({required this.playlist});
}

class PlaylistActivationPage extends StatefulWidget {
  final PlaylistActivationPagePayload payload;

  const PlaylistActivationPage({required this.payload, super.key});

  @override
  State<PlaylistActivationPage> createState() => _PlaylistActivationPageState();
}

class _PlaylistActivationPageState extends State<PlaylistActivationPage> {
  @override
  Widget build(BuildContext context) {
    final playlist = widget.payload.playlist;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: getDarkEmptyAppBar(),
      backgroundColor: AppColor.primaryBlack,
      body: SingleChildScrollView(
        child: Column(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: FFCacheNetworkImage(imageUrl: playlist.thumbnailURL ?? ''),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          playlist.getName(),
                          style: theme.textTheme.ppMori400White14,
                        ),
                        Text(
                            '${playlist.tokenIDs.length} artworks from Feral File Collection',
                            style: theme.textTheme.ppMori400White14),
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 16,
                  ),
                  SvgPicture.asset(
                    'assets/images/penrose_moma.svg',
                    height: 28,
                    colorFilter:
                        const ColorFilter.mode(AppColor.white, BlendMode.srcIn),
                  ),
                ],
              ),
            ),
            addOnlyDivider(color: AppColor.auGreyBackground),
            const SizedBox(
              height: 16,
            ),
            _content(context, playlist),
          ],
        ),
      ),
    );
  }

  Widget _content(BuildContext context, PlayListModel playlist) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              style: theme.textTheme.ppMori400White14,
              children: [
                TextSpan(
                    text:
                        'You have received a playlist activation request from '),
                TextSpan(
                  text: 'SupperBridge.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const SizedBox(
            height: 24,
          ),
          PrimaryAsyncButton(
            text: 'Accept Gift',
            onTap: () async {
              final playlistService = injector<PlaylistService>();
              final alreadyClaimPlaylist =
                  await playlistService.getPlaylistById(playlist.id);

              // if usser already claim the playlist, show already claim playlist
              if (alreadyClaimPlaylist != null) {
                injector<NavigationService>().goBack();
                unawaited(injector<NavigationService>()
                    .showALreadyClaimPlaylist(playlist: alreadyClaimPlaylist));
                return;
              }

              await playlistService.addPlaylists([playlist]);
              injector<NavigationService>().goBack();
              injector<NavigationService>().openPlaylist(playlist: playlist);
            },
          ),
          const SizedBox(
            height: 24,
          ),
          Text(
            'Accept this playlist to add it to your collection. Experience artworks on mobile or TV with the app.',
            style: theme.textTheme.ppMori400White14,
          ),
          const SizedBox(
            height: 24,
          ),
          RichText(
            text: TextSpan(
              style: theme.textTheme.ppMori400Grey14,
              children: [
                TextSpan(text: 'By accepting, you agree to the '),
                TextSpan(
                  text: 'Artist + Collector Rights',
                  style: TextStyle(decoration: TextDecoration.underline),
                ),
                TextSpan(text: '.'),
              ],
            ),
          ),
          const SizedBox(
            height: 16,
          ),
          PrimaryAsyncButton(
            text: 'Decline',
            onTap: () {
              injector<NavigationService>().goBack();
            },
          ),
          const SizedBox(
            height: 16,
          ),
        ],
      ),
    );
  }
}
