import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

class RecoveryPhrasePage extends StatelessWidget {
  final List<String> words;

  const RecoveryPhrasePage({Key? key, required this.words}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemsEachRow = words.length ~/ 2;

    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () {
          Navigator.of(context).pop();
        },
      ),
      body: Container(
        margin:
            EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Your recovery phrase",
                      style: appTextTheme.headline1,
                    ),
                    addTitleSpace(),
                    RichText(
                      text: TextSpan(
                        style: appTextTheme.bodyText1,
                        children: <TextSpan>[
                          TextSpan(
                            text:
                                'We’ve safely and securely backed up your recovery phrase to your',
                          ),
                          TextSpan(
                              text: ' iCloud Keychain',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                          TextSpan(
                            text:
                                '. You may also back it up to use it in another BIP-39 standard wallet:',
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 40),
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: Colors.black)),
                      // color: Colors.green,
                      alignment: Alignment.center,
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildRow(0, itemsEachRow),
                          _buildRow(itemsEachRow, itemsEachRow)
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(int offset, int itemsEachRow) {
    return Column(
      children: List.generate(itemsEachRow, (index) {
        final word = words[index + offset];
        return Container(
          width: 140,
          child: Column(children: [
            Row(children: [
              Container(
                  width: 28,
                  alignment: Alignment.centerRight,
                  child: Text("${index + offset + 1}. ",
                      style: appTextTheme.headline4)),
              Text(word, style: appTextTheme.headline4),
            ]),
            SizedBox(height: 4),
          ]),
        );
      }),
    );
  }
}
