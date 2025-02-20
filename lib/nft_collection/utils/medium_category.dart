class MediumCategory {
  static const image = 'image';
  static const video = 'video';
  static const model = 'model';
  static const webView = 'webview';
  static const other = 'other';

  static List<String> mineTypes(String category) {
    switch (category) {
      case MediumCategory.image:
        return [
          'image/avif',
          'image/bmp',
          'image/jpeg',
          'image/jpg',
          'image/png',
          'image/tiff',
          'image/svg+xml',
          'image/gif',
        ];
      case MediumCategory.video:
        return [
          'video/x-msvideo',
          'video/3gpp',
          'video/mp4',
          'video/mpeg',
          'video/ogg',
          'video/3gpp2',
          'video/quicktime',
          'application/x-mpegURL',
          'video/x-flv',
          'video/MP2T',
          'video/webm',
          'application/octet-stream',
        ];
      case MediumCategory.model:
        return ['model/gltf-binary'];
      case MediumCategory.webView:
        return [
          'text/html',
          'text/plain',
          'application/pdf',
          'application/x-directory',
        ];
    }
    return [];
  }
}
