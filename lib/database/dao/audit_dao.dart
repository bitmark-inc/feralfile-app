import 'package:autonomy_flutter/database/entity/audit.dart';
import 'package:floor/floor.dart';

@dao
abstract class AuditDao {
  @Query('SELECT * FROM Audit')
  Future<List<Audit>> getAudits();

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertAudit(Audit audit);

  @Query(
      'SELECT * FROM Audit WHERE category = (:category) AND action = (:action)')
  Future<List<Audit>> getAuditsBy(String category, String action);

  @Query('DELETE FROM Audit')
  Future<void> removeAll();
}
