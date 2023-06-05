import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_bloc.dart';
import 'package:autonomy_flutter/screen/interactive_postcard/postcard_detail_state.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nft_collection/models/asset_token.dart';

class ConfirmingPostcardPayload {
  final AssetToken assetToken;

  ConfirmingPostcardPayload(this.assetToken);
}

class ConfirmingPostcardPage extends StatefulWidget {
  final ConfirmingPostcardPayload payload;

  const ConfirmingPostcardPage({super.key, required this.payload});

  @override
  State<ConfirmingPostcardPage> createState() => _ConfirmingPostcardState();
}

class _ConfirmingPostcardState extends State<ConfirmingPostcardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: getBackAppBar(context, onBack: () {}),
        body: BlocConsumer<PostcardDetailBloc, PostcardDetailState>(
          listener: (context, state) {},
          builder: (context, state) {
            return Container();
          },
        ));
  }
}
