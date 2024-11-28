import 'package:autonomy_flutter/model/draft_customer_support.dart';
import 'package:autonomy_flutter/model/identity.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:autonomy_flutter/objectbox.g.dart';

const objectboxDBFile = 'com.bitmark.feralfile.db';

class ObjectBox {
  /// The Store of this app.
  late final Store store;

  // Add lazy box getters
  late final Box<Identity> _identityBox = Box<Identity>(store);
  Box<Identity> get identityBox => _identityBox;

  late final Box<DraftCustomerSupport> _draftCustomerSupportBox =
      Box<DraftCustomerSupport>(store);
  Box<DraftCustomerSupport> get draftCustomerSupport =>
      _draftCustomerSupportBox;

  ObjectBox._create(this.store) {}

  static Future<ObjectBox> create() async {
    final docsDir = await getApplicationDocumentsDirectory();
    final store =
        await openStore(directory: p.join(docsDir.path, objectboxDBFile));
    return ObjectBox._create(store);
  }
}
