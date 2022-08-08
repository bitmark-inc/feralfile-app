//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/util/style.dart';
import 'package:autonomy_flutter/view/back_appbar.dart';
import 'package:flutter/material.dart';

class UnsafeWebWalletPage extends StatelessWidget {
  const UnsafeWebWalletPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: getBackAppBar(
        context,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: Container(
        margin: pageEdgeInsets,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Browser-Extension Wallets: A Threat to Your NFTs and Cryptocurrency",
                style: appTextTheme.headline1,
              ),
              addTitleSpace(),
              _contentWidget,
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget get _contentWidget {
    return RichText(
      text: TextSpan(
        style: appTextTheme.bodyText1,
        children: const <TextSpan>[
          TextSpan(
            text:
                'NFT and cryptocurrency “web wallets” built as browser extensions have become very popular in the last several years. MetaMask has had tremendous success, while others such as Kukai and Temple are also gaining steam. Their success is very understandable: traditionally, one of the biggest obstacles to the adoption of crypto-assets was the lack of usability. Browser-extension wallets overcame that by making it quick and easy to transact NFTs and cryptocurrency. Unfortunately, they also made it dangerous.\n\nHere are some of the top reasons that we think browser extensions are threats to your digital assets:\n\n',
          ),
          TextSpan(
              text:
                  'Browser Extensions Focus on Usability at the Expense of Security.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' The general focus of browser extensions runs at cross purposes with security. They’re all about usability, and that tends to go beyond just their browser integration to their overall architecture, UX, and design. For example, many browser extensions encourage the entry of your seeds into the extension, making all NFTs, cryptocurrencies, or other assets that might depend on that seed vulnerable. (Entering a hierarchical key or even better a public key would provide much better security but tends to be outside the architecture of most browser extensions.)\n\n',
          ),
          TextSpan(
              text: 'Browser Extensions Encourage Privilege Creep.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Similarly, little attention is given by most users to the bundle of privileges requested by a browser extension, especially since they tend to be all-or-nothing requests. This creates an ecosystem where extensions have more access than they should, which can accentuate security flaws or problems of poor sandboxing. Privilege grants can also continue during wallet use, tricking users into giving away access to their keys, as has been the case in several',
          ),
          TextSpan(
              text: ' MetaMask airdrop scams.\n\n',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )),
          TextSpan(
              text: 'Browser Extensions Are Poorly Sandboxed.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Poor sandboxing is unfortunately integral to the design of browser extensions because they’re built around the need to access the DOM and other browser features. This ultimately damages their sandboxing, making the security of every browser extension dependent upon the authenticity and security of every other browser extension. Maybe a browser extension does a great job of protecting keys, but something as simple as a UX fake might break that security and offer access.\n\n',
          ),
          TextSpan(
              text:
                  'Browser Extensions Expose You to JavaScript Vulnerabilities.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Security flaws tend to appear in browser extensions because most are built in JavaScript, which exposes them to fundamental security problems in the JavaScript architecture. The most notable of these is Cross-Site Scripting, where injection attacks can result in the unintended execution of malicious code. This is a very common vulnerability that is being constantly tested by attackers and can result in modification of the DOM, theft of session cookies, and even access to webcams, microphones, files, or geo-data.\n\n',
          ),
          TextSpan(
              text: 'Browser Extensions Are Only as Safe as the Browser.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' However, JavaScript doesn’t offer the only potential security flaw for browser extensions: you also have to worry about the security of the browser, which is a big and complex program. This massively increases the potential attack surface of any wallet extension.\n\n',
          ),
          TextSpan(
              text: 'Browser Extensions Can Collect Data.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Security flaws and poor sandboxing can also expose a browser extension to data loss. The modern web is, unfortunately, built around the model of data collection. Inserting sensitive information such as cryptocurrency accounts and valuations into that maelstrom of information gathering could be disastrous to your privacy.\n\n',
          ),
          TextSpan(
              text: 'Browser Extensions Have Limited Security.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Even aside from the other problems, browser extensions just aren’t built to support the level of security required for valuable assets. The gold standard for managing cryptocurrency secrets such as seeds and private keys is encrypting them and storing them in a Secure Vault on a hardware device; these Vaults ensure that secrets are only accessible to the app that stored them and do computations using their own CPU. With a browser extension, you have few or none of those advantages, as the extension most likely doesn’t have access to the OS at that level. Even if a browser extension is linked to a hardware wallet that does have that level of security, it’s constraining the hardware security with all of the aforementioned limitations of browser extensions.\n\n',
          ),
          TextSpan(
              text: 'Browser Extensions Can Be Malicious.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Though there are considerable vulnerabilities that could arise from poorly written browser extensions, those problems are multiplied tenfold by the fact that browser extensions could be maliciously released to personally take advantage of the user or to take advantage of the cracks in the whole browser-extension model. This is not theoretical. As recently as 2020, Google had to remove ',
          ),
          TextSpan(
              text: '49 browser extensions',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                decoration: TextDecoration.underline,
              )),
          TextSpan(text: ' that were stealing cryptocurrency!\n\n'),
          TextSpan(
              text: 'Browser Extensions Can BeCOME Malicious.',
              style: TextStyle(fontWeight: FontWeight.bold)),
          TextSpan(
            text:
                ' Though users might feel safe if they are using a well-known browser extension such as MetaMask, that safety can be fleeting. If a developer’s account were hijacked, then a safe wallet could turn into a malicious wallet with no warning due to the light or nonexistent testing regimen required by browser-extension updates.\n\n',
          ),
          TextSpan(
            text:
                'In general, apps tend to address these problems much better than browser extensions, offering a stronger security model that is linked to hardware guarantees. In a walled garden such as the Apple App Store, there are also considerably better protections for publication. Unless you are dealing with trivial values of digital assets, an app thus becomes a critical tool for protecting your investment.',
          ),
        ],
      ),
    );
  }
}
