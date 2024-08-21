import 'package:cached_network_image/cached_network_image.dart';
import 'package:cached_network_image_platform_interface/cached_network_image_platform_interface.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class FFCacheNetworkImage extends StatelessWidget {
  const FFCacheNetworkImage({
    required this.imageUrl,
    super.key,
    this.httpHeaders,
    this.imageBuilder,
    this.placeholder,
    this.progressIndicatorBuilder,
    this.errorWidget,
    this.fadeOutDuration = const Duration(milliseconds: 1000),
    this.fadeOutCurve = Curves.easeOut,
    this.fadeInDuration = const Duration(milliseconds: 500),
    this.fadeInCurve = Curves.easeIn,
    this.width,
    this.height,
    this.fit,
    this.alignment = Alignment.center,
    this.repeat = ImageRepeat.noRepeat,
    this.matchTextDirection = false,
    this.cacheManager,
    this.useOldImageOnUrlChange = false,
    this.color,
    this.filterQuality = FilterQuality.low,
    this.colorBlendMode,
    this.placeholderFadeInDuration,
    this.memCacheWidth,
    this.memCacheHeight,
    this.cacheKey,
    this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.errorListener,
    this.imageRenderMethodForWeb = ImageRenderMethodForWeb.HtmlImage,
  });

  final String imageUrl;
  final Map<String, String>? httpHeaders;
  final ImageWidgetBuilder? imageBuilder;
  final PlaceholderWidgetBuilder? placeholder;
  final ProgressIndicatorBuilder? progressIndicatorBuilder;
  final LoadingErrorWidgetBuilder? errorWidget;
  final Duration fadeOutDuration;
  final Curve fadeOutCurve;
  final Duration fadeInDuration;
  final Curve fadeInCurve;
  final double? width;
  final double? height;
  final BoxFit? fit;
  final Alignment alignment;
  final ImageRepeat repeat;
  final bool matchTextDirection;
  final BaseCacheManager? cacheManager;
  final bool useOldImageOnUrlChange;
  final Color? color;
  final FilterQuality filterQuality;
  final BlendMode? colorBlendMode;
  final Duration? placeholderFadeInDuration;
  final int? memCacheWidth;
  final int? memCacheHeight;
  final String? cacheKey;
  final int? maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final ErrorListener? errorListener;
  final ImageRenderMethodForWeb imageRenderMethodForWeb;

  @override
  Widget build(BuildContext context) {
    const ratio = 3;
    return CachedNetworkImage(
      imageUrl: imageUrl,
      httpHeaders: httpHeaders,
      imageBuilder: imageBuilder,
      placeholder: placeholder,
      progressIndicatorBuilder: progressIndicatorBuilder,
      errorWidget: errorWidget,
      fadeOutDuration: fadeOutDuration,
      fadeOutCurve: fadeOutCurve,
      fadeInDuration: fadeInDuration,
      fadeInCurve: fadeInCurve,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      matchTextDirection: matchTextDirection,
      cacheManager: cacheManager,
      useOldImageOnUrlChange: useOldImageOnUrlChange,
      color: color,
      filterQuality: filterQuality,
      colorBlendMode: colorBlendMode,
      placeholderFadeInDuration: placeholderFadeInDuration,
      memCacheWidth: memCacheWidth == null ? null : memCacheWidth! * ratio,
      memCacheHeight: memCacheHeight == null ? null : memCacheHeight! * ratio,
      cacheKey: cacheKey,
      maxWidthDiskCache:
          maxWidthDiskCache == null ? null : maxWidthDiskCache! * ratio,
      maxHeightDiskCache:
          maxHeightDiskCache == null ? null : maxHeightDiskCache! * ratio,
      errorListener: errorListener,
      imageRenderMethodForWeb: imageRenderMethodForWeb,
    );
  }
}
