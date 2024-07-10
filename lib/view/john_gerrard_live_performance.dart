import 'dart:async';

import 'package:autonomy_flutter/main.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/util/series_ext.dart';
import 'package:autonomy_flutter/view/artwork_common_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_rendering/nft_rendering.dart';

class JohnGerrardLivePerformanceWidget extends StatefulWidget {
  final Exhibition exhibition;

  const JohnGerrardLivePerformanceWidget({required this.exhibition, super.key});

  @override
  State<JohnGerrardLivePerformanceWidget> createState() =>
      _JohnGerrardLivePerformanceWidgetState();
}

class _JohnGerrardLivePerformanceWidgetState
    extends State<JohnGerrardLivePerformanceWidget>
    with WidgetsBindingObserver, RouteAware {
  INFTRenderingWidget? _renderingWidget;

  @override
  void initState() {
    WidgetsBinding.instance.addObserver(this);
    super.initState();
  }

  @override
  void dispose() {
    _renderingWidget?.dispose();
    routeObserver.unsubscribe(this);
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    routeObserver.subscribe(this, ModalRoute.of(context)!);
    super.didChangeDependencies();
  }

  @override
  void didPopNext() {
    _renderingWidget?.didPopNext();
    super.didPopNext();
  }

  @override
  void didPushNext() {
    unawaited(_renderingWidget?.clearPrevious());
    super.didPushNext();
  }

  @override
  void didChangeMetrics() {
    super.didChangeMetrics();
    _updateWebviewSize();
  }

  void _updateWebviewSize() {
    if (_renderingWidget != null &&
        _renderingWidget is WebviewNFTRenderingWidget) {
      // ignore: cast_nullable_to_non_nullable
      (_renderingWidget as WebviewNFTRenderingWidget).updateWebviewSize();
    }
  }

  @override
  Widget build(BuildContext context) {
    final previewUrl = widget.exhibition.series!.first.galleryURL;
    final thumbnailUrl = widget.exhibition.series!.first.thumbnailURI;
    return BlocProvider(
      create: (_) => RetryCubit(),
      child: BlocBuilder<RetryCubit, int>(
        builder: (context, attempt) {
          if (attempt > 0) {
            _renderingWidget?.dispose();
            _renderingWidget = null;
          }
          _renderingWidget ??= buildFeralfileRenderingWidget(
            context,
            attempt: attempt > 0 ? attempt : null,
            mimeType: widget.exhibition.series!.first.medium,
            previewURL: previewUrl,
            thumbnailURL: thumbnailUrl ?? '',
            isScrollable: false,
          );
          return Center(
            child: _renderingWidget?.build(context) ?? const SizedBox(),
          );
        },
      ),
    );
  }
}
