import 'package:autonomy_flutter/screen/mobile_controller/screens/index/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

class LoadMoreIndicator extends StatelessWidget {
  const LoadMoreIndicator({
    required this.isLoadingMore,
    super.key,
  });

  final bool isLoadingMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      alignment: Alignment.center,
      child: isLoadingMore
          ? const SizedBox(
              height: 20,
              width: 20,
              child: LoadingIndicator(),
            )
          : const SizedBox.shrink(),
    );
  }
}
