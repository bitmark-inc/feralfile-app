import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/util/exhibition_ext.dart';
import 'package:flutter/material.dart';

class ListArtworkView extends StatefulWidget {
  final List<Artwork> artworks;

  const ListArtworkView({required this.artworks, super.key});

  @override
  State<ListArtworkView> createState() => _ListArtworkViewState();
}

class _ListArtworkViewState extends State<ListArtworkView> {
  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: widget.artworks.length,
      itemBuilder: (context, index) {
        final artwork = widget.artworks[index];
        return ListTile(
          title: Text(artwork.name),
          subtitle: Text(artwork.id),
          leading: Image.network(artwork.series!.exhibition?.title ?? ""),
        );
      },
    );
  }

  Widget _artworkItem(BuildContext context, Artwork artwork) {
    return Column(
      children: [
        Image.network(artwork.thumbnailURL),
        Expanded(
            child: Text(
          artwork.series!.artist?.alias ?? '',
          overflow: TextOverflow.ellipsis,
        )),
      ],
    );
  }
}
