import 'package:autonomy_flutter/gateway/merchandise_api.dart';
import 'package:autonomy_flutter/model/merchandise_order.dart';

abstract class MerchandiseService {
  Future<MerchandiseOrder> getOrder(String id);
}

class MerchandiseServiceImpl implements MerchandiseService {
  final MerchandiseApi _merchandiseApi;

  MerchandiseServiceImpl(this._merchandiseApi);

  @override
  Future<MerchandiseOrder> getOrder(String id) async {
    final response = await _merchandiseApi.getOrder(id);
    return response.order;
  }
}
