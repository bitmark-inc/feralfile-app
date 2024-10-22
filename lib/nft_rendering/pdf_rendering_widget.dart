import 'dart:async';
import 'dart:io';

import 'package:autonomy_flutter/nft_rendering/nft_error_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_loading_widget.dart';
import 'package:autonomy_flutter/nft_rendering/nft_rendering_widget.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

class PDFNFTRenderingWidget extends NFTRenderingWidget {
  final String previewURL;
  final Widget errorWidget;
  final Widget loadingWidget;
  final Widget noPreviewUrlWidget; // Added parameter for noPreviewUrlWidget

  const PDFNFTRenderingWidget({
    required this.previewURL,
    this.errorWidget = const NFTErrorWidget(),
    this.loadingWidget = const LoadingWidget(),
    this.noPreviewUrlWidget = const NoPreviewUrlWidget(),
    super.key,
  });

  @override
  State<PDFNFTRenderingWidget> createState() => _PDFNFTRenderingWidgetState();
}

class _PDFNFTRenderingWidgetState extends State<PDFNFTRenderingWidget> {
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  final ValueNotifier<bool> _isReady = ValueNotifier(false);
  final ValueNotifier<dynamic> _error = ValueNotifier<dynamic>(null);
  late Future<File> _pdfFileFuture;

  @override
  void initState() {
    super.initState();
    // ignore: discarded_futures
    _pdfFileFuture = _createFileOfPdfUrl();
  }

  @override
  Widget build(BuildContext context) => widget.previewURL.isEmpty
      ? widget.noPreviewUrlWidget // Show error widget if URL is empty
      : _widgetBuilder();

  Widget _widgetBuilder() => Stack(
        children: [
          FutureBuilder<File>(
            future: _pdfFileFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                return _buildPDFView(snapshot.data!);
              } else {
                return const SizedBox();
              }
            },
          ),
          _buildErrorWidget(),
          _buildReadyWidget(),
        ],
      );

  Widget _buildPDFView(File file) => PDFView(
        key: Key(widget.previewURL),
        filePath: file.path,
        gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
          Factory<VerticalDragGestureRecognizer>(
            () => VerticalDragGestureRecognizer(),
          ),
        },
        pageFling: false,
        onRender: (_) {
          _isReady.value = true;
        },
        onError: (error) {
          _error.value = error;
        },
        onPageError: (page, error) {
          _error.value = error;
        },
        onViewCreated: (PDFViewController pdfViewController) {
          _controller.complete(pdfViewController);
        },
        onLinkHandler: (String? uri) {},
        onPageChanged: (int? page, int? total) {},
      );

  Widget _buildErrorWidget() => ValueListenableBuilder<dynamic>(
        valueListenable: _error,
        builder: (context, error, child) => Visibility(
          visible: error != null,
          child: Container(
            color: Colors.black,
            child: widget.errorWidget,
          ),
        ),
      );

  Widget _buildReadyWidget() => ValueListenableBuilder<bool>(
        valueListenable: _isReady,
        builder: (context, isReady, child) => Visibility(
          visible: !isReady,
          child: Container(
            color: Colors.black,
            child: widget.loadingWidget,
          ),
        ),
      );

  Future<File> _createFileOfPdfUrl() async {
    final Completer<File> completer = Completer<File>();
    try {
      final url = widget.previewURL;
      final filename = url.substring(url.lastIndexOf('/') + 1);
      final response = await http.get(Uri.parse(url));
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/$filename');

      await file.writeAsBytes(response.bodyBytes, flush: true);
      completer.complete(file);
    } catch (e) {
      _error.value = e.toString();
      completer.completeError(e);
    }

    return completer.future;
  }
}
