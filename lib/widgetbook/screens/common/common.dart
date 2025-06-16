// WidgetbookUseCase seriesView() {
//   return WidgetbookUseCase(
//     name: 'Series View',
//     builder: (context) => SeriesView(
//       series: MockFFSeriesData.listSeries,
//       userCollections: const [],
//       exploreBar: const SizedBox(),
//       header: const SizedBox.shrink(),
//     ),
//   );
// }

// WidgetbookUseCase for ProgressBar
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_page.dart';
import 'package:autonomy_flutter/screen/dailies_work/dailies_work_state.dart';
import 'package:autonomy_flutter/screen/detail/artwork_detail_page.dart';
import 'package:autonomy_flutter/screen/detail/preview_detail/preview_detail_widget.dart';
import 'package:autonomy_flutter/view/daily_progress_bar.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/mock_asset_token.dart';
import 'package:widgetbook/widgetbook.dart';

WidgetbookUseCase progressBar() {
  return WidgetbookUseCase(
      name: 'Progress Bar',
      builder: (context) {
        final progress = context.knobs.double
            .slider(label: 'Progress', initialValue: 0.5, min: 0.0, max: 1.0);
        return ProgressBar(progress: progress);
      });
}

// DailyProgressBar
WidgetbookUseCase dailyProgressBar() {
  return WidgetbookUseCase(
    name: 'Daily Progress Bar',
    builder: (context) {
      final remainingDuration = context.knobs.duration(
          label: 'Remaining Duration', initialValue: Duration(hours: 1));
      final totalDuration = context.knobs
          .duration(label: 'Total Duration', initialValue: Duration(hours: 2));
      final time = context.knobs.dateTime(
        label: 'Time',
        initialValue: DateTime.now(),
        start: DateTime.now().subtract(Duration(hours: 2)),
        end: DateTime.now().add(Duration(hours: 2)),
      );
      return DailyProgressBar(
        remainingDuration: remainingDuration,
        totalDuration: totalDuration,
      );
    },
  );
}

// ArtworkPreviewWidget
WidgetbookUseCase artworkPreviewWidget() {
  return WidgetbookUseCase(
    name: 'Artwork Preview Widget',
    builder: (context) {
      // This is a placeholder for the actual ArtworkIdentity
      final title = context.knobs.list(label: 'Asset Token', options: [
        ...MockAssetToken.all.map((token) => token.title),
      ]);
      final assetToken = MockAssetToken.all.firstWhere(
        (token) => token.title == title,
        orElse: () => MockAssetToken.all.first,
      );
      final identity = ArtworkIdentity(
        assetToken.id,
        assetToken.owner,
      );
      return ArtworkPreviewWidget(
        identity: identity,
        onLoaded: ({webViewController, time}) async {
          // Mock loading logic
          print('Artwork loaded with time: $time');
        },
        onDispose: ({time}) async {
          // Mock dispose logic
          print('Artwork disposed with time: $time');
        },
      );
    },
  );
}

//DailyDetails
WidgetbookUseCase dailyDetails() {
  return WidgetbookUseCase(
    name: 'Daily Details',
    builder: (context) {
      final assetToken = MockAssetToken.all.first;
      final identity = ArtworkIdentity(
        assetToken.id,
        assetToken.owner,
      );
      final state = DailiesWorkState(
        assetTokens: [assetToken],
        currentDailyToken: null,
        currentArtist: null, // Mock artist data
        currentExhibition: null, // Mock exhibition data
      );
      return DailyDetails(
        state: state,
      );
    },
  );
}
