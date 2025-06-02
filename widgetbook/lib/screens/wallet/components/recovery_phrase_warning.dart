import 'package:autonomy_flutter/view/recovery_phrase_warning.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_workspace/mock/mock_channel_service.dart';

class RecoveryPhraseWarningComponent extends WidgetbookComponent {
  RecoveryPhraseWarningComponent()
      : super(
          name: 'RecoveryPhraseWarning',
          useCases: [
            WidgetbookUseCase(
              name: 'With Mnemonic',
              builder: (context) => FutureBuilder(
                future: MockChannelService().exportMnemonicForAllPersonaUUIDs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const RecoveryPhraseWarning();
                },
              ),
            ),
            WidgetbookUseCase(
              name: 'Empty Mnemonic',
              builder: (context) => FutureBuilder(
                future: MockChannelService().exportMnemonicForAllPersonaUUIDs(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return const RecoveryPhraseWarning();
                },
              ),
            ),
          ],
        );
}
