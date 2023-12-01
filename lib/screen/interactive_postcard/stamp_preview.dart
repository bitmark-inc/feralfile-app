import 'dart:async';

import 'package:after_layout/after_layout.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/postcard_metadata.dart';
import 'package:autonomy_flutter/model/prompt.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_page.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_view_widget.dart';
import 'package:autonomy_flutter/service/configuration_service.dart';
import 'package:autonomy_flutter/service/navigation_service.dart';
import 'package:autonomy_flutter/service/postcard_service.dart';
import 'package:autonomy_flutter/service/remote_config_service.dart';
import 'package:autonomy_flutter/util/asset_token_ext.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:autonomy_flutter/util/moma_style_color.dart';
import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/util/ui_helper.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:autonomy_flutter/view/postcard_button.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:autonomy_theme/autonomy_theme.dart';
import 'package:autonomy_theme/extensions/theme_extension/moma_sans.dart';
import 'package:dio/dio.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

class StampPreview extends StatefulWidget {
  static const String tag = 'stamp_preview';
  final StampPreviewPayload payload;
  static const double cellSize = 20;

  const StampPreview({required this.payload, super.key});

  @override
  State<StampPreview> createState() => _StampPreviewState();
}

class _StampPreviewState extends State<StampPreview> with AfterLayoutMixin {
  Uint8List? postcardData;
  Uint8List? stampedPostcardData;
  int index = 0;
  late bool confirming;
  late bool isSending;
  Timer? timer;
  Timer? confirmingTimer;
  final _configurationService = injector<ConfigurationService>();
  final _postcardService = injector<PostcardService>();
  final _navigationService = injector<NavigationService>();

  @override
  void initState() {
    log.info('[POSTCARD][StampPreview] payload: ${widget.payload}');
    confirming = false;
    isSending = false;
    unawaited(_configurationService.setAutoShowPostcard(false));
    super.initState();
  }

  @override
  void afterFirstLayout(BuildContext context) {
    setState(() {
      confirming = true;
    });
    unawaited(_postcardService
        .finalizeStamp(widget.payload.asset, widget.payload.imagePath,
            widget.payload.metadataPath, widget.payload.location)
        .then((final bool isStampSuccess) {
      _setTimer();
      if (mounted) {
        if (!isStampSuccess) {
          UIHelper.showPostcardStampFailed(context);
        }
        setState(() {
          confirming = false;
        });
      }
    }));
  }

  @override
  void dispose() {
    timer?.cancel();
    confirmingTimer?.cancel();
    super.dispose();
  }

  void _refreshPostcard() {
    log.info('Refresh postcard');
    context.read<PostcardDetailBloc>().add(PostcardDetailGetInfoEvent(
          ArtworkIdentity(widget.payload.asset.id, widget.payload.asset.owner),
          useIndexer: true,
        ));
  }

  void _setTimer() {
    timer?.cancel();
    const duration = Duration(seconds: 10);
    timer = Timer.periodic(duration, (timer) {
      if (mounted) {
        _refreshPostcard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const backgroundColor = AppColor.chatPrimaryColor;
    return WillPopScope(
      onWillPop: () async => !confirming,
      child: Scaffold(
        backgroundColor: backgroundColor,
        appBar: getCloseAppBar(
          context,
          title: widget.payload.asset.title ?? '',
          titleStyle: theme.textTheme.moMASans700Black16.copyWith(
            fontSize: 18,
          ),
          isTitleCenter: false,
          onClose: confirming
              ? null
              : () {
                  _navigationService.popUntilHomeOrSettings();
                  if (!mounted) {
                    return;
                  }
                  unawaited(Navigator.of(context).pushNamed(
                    AppRouter.claimedPostcardDetailsPage,
                    arguments: PostcardDetailPagePayload(
                        [widget.payload.asset.identity], 0),
                  ));
                  unawaited(_configurationService.setAutoShowPostcard(true));
                },
          withBottomDivider: false,
          disableIcon: closeIcon(color: AppColor.disabledColor),
          statusBarColor: backgroundColor,
        ),
        body: BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
          listener: (context, state) {
            if (!(state.assetToken?.isStamping ?? true)) {
              timer?.cancel();
            }
          },
          builder: (context, state) {
            final assetToken = widget.payload.asset;
            final imagePath = widget.payload.imagePath;
            final metadataPath = widget.payload.metadataPath;
            return Padding(
              padding:
                  ResponsiveLayout.pageHorizontalEdgeInsetsWithSubmitButton,
              child: Column(
                children: [
                  const SizedBox(
                    height: 170,
                  ),
                  PostcardRatio(
                    assetToken: assetToken,
                    imagePath: imagePath,
                    jsonPath: metadataPath,
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  _postcardAction(context, state),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _postcardAction(BuildContext context, PostcardDetailState state) {
    final theme = Theme.of(context);
    final showCondition = confirming ||
        (injector<RemoteConfigService>().getBool(
                ConfigGroup.postcardAction, ConfigKey.waitConfirmedToSend) &&
            (state.assetToken?.isStamping ?? false));
    if (showCondition) {
      return PostcardButton(
        enabled: !showCondition,
        text: 'confirming_on_blockchain'.tr(),
        isProcessing: showCondition,
        fontSize: 18,
      );
    }
    final assetToken = widget.payload.asset;
    if (!assetToken.isFinal) {
      return Column(
        children: [
          Builder(
              builder: (final context) => PostcardAsyncButton(
                    text: 'send_postcard'.tr(),
                    fontSize: 18,
                    color: MoMAColors.moMA8,
                    onTap: () async {
                      bool isStampSuccess = true;
                      if (assetToken.isProcessingStamp) {
                        setState(() {
                          confirming = true;
                        });
                        isStampSuccess = await _postcardService.finalizeStamp(
                          assetToken,
                          widget.payload.imagePath,
                          widget.payload.metadataPath,
                          widget.payload.location,
                        );
                        if (mounted) {
                          if (!isStampSuccess) {
                            await UIHelper.showPostcardStampFailed(context);
                          }
                          setState(() {
                            confirming = false;
                          });
                        }
                      }
                      if (!mounted || !isStampSuccess) {
                        return;
                      }
                      // ignore: use_build_context_synchronously
                      final box = context.findRenderObject() as RenderBox?;
                      await assetToken.sharePostcard(
                        onSuccess: () async {
                          if (mounted) {
                            setState(() {
                              isSending = assetToken.isSending;
                            });
                          }
                        },
                        onFailed: (e) {
                          if (e is DioException) {
                            if (mounted) {
                              UIHelper.showSharePostcardFailed(context, e);
                            }
                          }
                        },
                        sharePositionOrigin: box == null
                            ? null
                            : box.localToGlobal(Offset.zero) & box.size,
                      );
                    },
                  )),
          const SizedBox(
            height: 20,
          ),
          Text(
            'send_the_postcard_to_someone'.tr(),
            style: theme.textTheme.ppMori400Black12,
          ),
        ],
      );
    }
    return const SizedBox();
  }
}

class StampPreviewPayload {
  final AssetToken asset;
  final String imagePath;
  final String metadataPath;
  final Location location;

  // constructor
  StampPreviewPayload({
    required this.asset,
    required this.imagePath,
    required this.metadataPath,
    required this.location,
  });
}

class StampingPostcard {
  final String indexId;
  final String address;
  final DateTime timestamp;
  final String imagePath;
  final String metadataPath;
  final int counter;

  // constructor
  StampingPostcard({
    required this.indexId,
    required this.address,
    required this.imagePath,
    required this.metadataPath,
    required this.counter,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  //constructor

  static StampingPostcard fromJson(Map<String, dynamic> json) =>
      StampingPostcard(
        indexId: json['indexId'],
        address: json['address'],
        timestamp: DateTime.parse(json['timestamp']),
        imagePath: json['imagePath'],
        metadataPath: json['metadataPath'],
        counter: json['counter'],
      );

  Map<String, dynamic> toJson() => {
        'indexId': indexId,
        'address': address,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
        'metadataPath': metadataPath,
        'counter': counter,
      };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StampingPostcard &&
          runtimeType == other.runtimeType &&
          indexId == other.indexId &&
          address == other.address &&
          counter == other.counter;

  @override
  int get hashCode => indexId.hashCode ^ address.hashCode ^ counter.hashCode;
}

class ProcessingStampPostcard extends StampingPostcard {
  Location location;
  Prompt? prompt;

  ProcessingStampPostcard({
    required super.indexId,
    required super.address,
    required super.imagePath,
    required super.metadataPath,
    required super.counter,
    required DateTime super.timestamp,
    required this.location,
    this.prompt,
  });

  static ProcessingStampPostcard fromJson(Map<String, dynamic> json) =>
      ProcessingStampPostcard(
        indexId: json['indexId'],
        address: json['address'],
        timestamp: DateTime.parse(json['timestamp']),
        imagePath: json['imagePath'],
        metadataPath: json['metadataPath'],
        counter: json['counter'],
        location: Location.fromJson(json['location']),
        prompt: json['prompt'] == null ? null : Prompt.fromJson(json['prompt']),
      );

  @override
  Map<String, dynamic> toJson() => {
        'indexId': indexId,
        'address': address,
        'timestamp': timestamp.toIso8601String(),
        'imagePath': imagePath,
        'metadataPath': metadataPath,
        'counter': counter,
        'location': location.toJson(),
        'prompt': prompt?.toJson(),
      };
}
