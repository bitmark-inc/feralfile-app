//
//  SPDX-License-Identifier: BSD-2-Clause-Patent
//  Copyright © 2022 Bitmark. All rights reserved.
//  Use of this source code is governed by the BSD-2-Clause Plus Patent License
//  that can be found in the LICENSE file.
//

import 'package:autonomy_flutter/model/tzkt_operation.dart';
import 'package:autonomy_flutter/screen/settings/crypto/wallet_detail/tezos_transaction_row_view.dart';
import 'package:autonomy_flutter/util/error_handler.dart';
import 'package:autonomy_flutter/view/responsive.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:infinite_scroll_pagination/infinite_scroll_pagination.dart';

import '../../../bloc/tzkt_transaction/tzkt_transaction_bloc.dart';
import '../../../bloc/tzkt_transaction/tzkt_transaction_state.dart';

class TezosTXListView extends StatefulWidget {
  final String address;
  final ScrollController? controller;

  const TezosTXListView({Key? key, required this.address, this.controller})
      : super(key: key);

  @override
  State<TezosTXListView> createState() => _TezosTXListViewState();
}

class _TezosTXListViewState extends State<TezosTXListView> {
  static const _pageSize = 40;
  late final TZKTTransactionBloc tzktBloc;

  final PagingController<int, TZKTTransactionInterface> _pagingController =
      PagingController(firstPageKey: 0, invisibleItemsThreshold: 10);

  @override
  void initState() {
    tzktBloc = context.read<TZKTTransactionBloc>();
    _pagingController.addPageRequestListener(
      (pageKey) {
        tzktBloc.add(
          GetPageNewItems(
              address: widget.address,
              initiator: widget.address,
              pageSize: _pageSize,
              pageKey: pageKey),
        );
      },
    );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return widget.address.isEmpty
        ? const SizedBox()
        : BlocConsumer<TZKTTransactionBloc, TZKTTransactionState>(
            listener: (context, state) {
              try {
                bool isLastPage = state.isLastPage ?? false;
                final newItems = state.newItems;
                if (isLastPage) {
                  _pagingController.appendLastPage(newItems);
                } else {
                  final nextPageKey = state.newItems.last.getID();
                  _pagingController.appendPage(state.newItems, nextPageKey);
                }
              } catch (error) {
                _pagingController.error = error;
                showErrorDialog(
                  context,
                  "😵",
                  "unable_load_tzkt".tr(),
                  "try_again".tr(),
                  () {
                    tzktBloc.add(GetPageNewItems(
                        address: widget.address,
                        initiator: widget.address,
                        pageSize: _pageSize,
                        pageKey: _pagingController.nextPageKey ??
                            _pagingController.firstPageKey));
                  },
                );
              }
            },
            builder: (context, state) {
              return Padding(
                padding: const EdgeInsets.only(),
                child: CustomScrollView(
                  controller: widget.controller ?? ScrollController(),
                  slivers: [
                    PagedSliverList.separated(
                      pagingController: _pagingController,
                      builderDelegate:
                          PagedChildBuilderDelegate<TZKTTransactionInterface>(
                        animateTransitions: true,
                        newPageErrorIndicatorBuilder: (context) {
                          return Container(
                            padding: ResponsiveLayout.pageEdgeInsets,
                            child: Text("unable_load_tzkt".tr(),
                                style: theme.textTheme.bodyText1),
                          );
                        },
                        noItemsFoundIndicatorBuilder: (context) {
                          return Container(
                            padding: ResponsiveLayout.pageEdgeInsets,
                            child: Text("transaction_appear_hear".tr(),
                                style: theme.textTheme.bodyText1),
                          );
                        },
                        itemBuilder: (context, item, index) {
                          return Padding(
                            padding: ResponsiveLayout.pageEdgeInsets,
                            child: TezosTXRowView(
                                tx: item, currentAddress: widget.address),
                          );
                        },
                      ),
                      separatorBuilder: (context, index) {
                        return const Divider();
                      },
                    ),
                  ],
                ),
              );
            },
          );
  }
}
