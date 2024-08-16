import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:flutter/material.dart';

class ListArtworkView extends StatefulWidget {
  final List<Artwork> artworks;

  const ListArtworkView({required this.artworks, super.key});

  @override
  State<ListArtworkView> createState() => _ListArtworkViewState();
}

class _ListArtworkViewState extends State<ListArtworkView> {
  @override
  Widget build(BuildContext context) => ListView.builder(
        itemCount: widget.artworks.length,
        itemBuilder: (context, index) {
          final artwork = widget.artworks[index];
          return ListTile(
            title: Text(artwork.name),
            subtitle: Text(artwork.id),
            leading: Image.network(artwork.series!.exhibition?.title ?? ''),
          );
        },
      );
}
