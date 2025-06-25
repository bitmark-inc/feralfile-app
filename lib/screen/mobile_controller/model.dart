class FFDirectory {
  FFDirectory(
    this.name, {
    this.description,
    this.url,
  });

  final String name;
  final String? description;
  final String? url;
}

// extension
extension DirectoryListExtension on FFDirectory {
  bool get isFeralFile {
    return name == 'Feral File';
  }
}

class Artworkplaylist {}

class ArtworkPlaylistItem {}

class ArtworkProvenance {}
