//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/app_router.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_row_view.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class TezosTXListView extends StatefulWidget {
  final String address;

  const TezosTXListView({Key? key, required this.address}) : super(key: key);

  @override
  State<TezosTXListView> createState() => _TezosTXListViewState();
}

class _TezosTXListViewState extends State<TezosTXListView> {
  static const _pageSize = 40;

  final PagingController<int, TZKTOperation> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 10);

  @override
  void initState() {
    _pagingController.addPageRequestListener((pageKey) {
      _fetchPage(pageKey);
    });
    super.initState();
  }

  Future<void> _fetchPage(int pageKey) async {
    final address = widget.address;

    if (address.isEmpty) return;

    try {
      final newItems = await injector<TZKTApi>().getOperations(
        address,
        type: "transaction,origination,reveal",
        limit: _pageSize,
        lastId: pageKey > 0 ? pageKey : null,
        initiator: address,
      );

      final isLastPage = newItems.length < _pageSize;
      if (isLastPage) {
        _pagingController.appendLastPage(newItems);
      } else {
        final nextPageKey = newItems.last.id;
        _pagingController.appendPage(newItems, nextPageKey);
      }
    } catch (error) {
      _pagingController.error = error;
      showErrorDialog(
          context,
          "😵",
          "Currently unable to load transaction data from tzkt.io .",
          "TRY AGAIN", () {
        _fetchPage(pageKey);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return widget.address.isEmpty
        ? const SizedBox()
        : CustomScrollView(
            slivers: [
              PagedSliverList.separated(
                  pagingController: _pagingController,
                  builderDelegate: PagedChildBuilderDelegate<TZKTOperation>(
                    animateTransitions: true,
                    newPageErrorIndicatorBuilder: (context) {
                      return Container(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text(
                            "Currently unable to load transaction data from tzkt.io.",
                            style: theme.textTheme.bodyText1),
                      );
                    },
                    noItemsFoundIndicatorBuilder: (context) {
                      return Container(
                        padding: const EdgeInsets.only(top: 30),
                        child: Text("Your transactions will appear here.",
                            style: theme.textTheme.bodyText1),
                      );
                    },
                    itemBuilder: (context, item, index) {
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        child: TezosTXRowView(
                            tx: item, currentAddress: widget.address),
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRouter.tezosTXDetailPage,
                          arguments: {
                            "current_address": widget.address,
                            "tx": item,
                          },
                        ),
                      );
                    },
                  ),
                  separatorBuilder: (context, index) {
                    return const Divider();
                  })
            ],
          );
  }
}
