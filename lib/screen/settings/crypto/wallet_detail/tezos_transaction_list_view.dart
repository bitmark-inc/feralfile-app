//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/gateway/tzkt_api.dart';
import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_row_view.dart';
import 'package:flutter/material.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

class TezosTXListView extends StatefulWidget {
  final Future<String> address;
  const TezosTXListView({Key? key, required this.address}) : super(key: key);

  @override
  _TezosTXListViewState createState() => _TezosTXListViewState();
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
    final address = await widget.address;

    try {
      final newItems = await injector<TZKTApi>().getOperations(
        address,
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
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(builder: (context, snapshot) {
      return CustomScrollView(
        slivers: [
          PagedSliverList.separated(
              pagingController: _pagingController,
              builderDelegate: PagedChildBuilderDelegate<TZKTOperation>(
                itemBuilder: (context, item, index) {
                  return TezosTXRowView(
                      tx: item, currentAddress: snapshot.data);
                },
              ),
              separatorBuilder: (context, index) {
                return Divider();
              })
        ],
      );
    });
  }
}
