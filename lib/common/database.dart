import 'package:autonomy_flutter/model/canvas_device_info.dart';
import 'package:autonomy_flutter/model/draft_customer_support.dart';
import 'package:autonomy_flutter/model/identity.dart';
import 'package:autonomy_flutter/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

const objectboxDBFile = 'com.bitmark.feralfile.db';

class ObjectBox {
  /// The Store of this app.
  static late Store store;

  // Add static box getters
  static late Box<IndexerIdentity> _identityBox;

  static Box<IndexerIdentity> get identityBox => _identityBox;

  static late Box<DraftCustomerSupport> _draftCustomerSupportBox;

  static Box<DraftCustomerSupport> get draftCustomerSupport =>
      _draftCustomerSupportBox;

  static late Box<FFBluetoothDevice> _bluetoothPairedDevicesBox;

  static Box<FFBluetoothDevice> get bluetoothPairedDevicesBox =>
      _bluetoothPairedDevicesBox;

  ObjectBox._create(Store storeInstance) {
    store = storeInstance;
    _identityBox = Box<IndexerIdentity>(store);
    _draftCustomerSupportBox = Box<DraftCustomerSupport>(store);
    _bluetoothPairedDevicesBox = Box<FFBluetoothDevice>(store);
  }

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store =
        await openStore(directory: p.join(docsDir.path, objectboxDBFile));
    return ObjectBox._create(store);
  }
}
