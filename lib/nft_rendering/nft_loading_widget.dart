import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Default of loading state widget
class NFTLoadingWidget extends StatelessWidget {
  const NFTLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: CupertinoActivityIndicator(color: Colors.blueAccent, radius: 16),
      );
}
