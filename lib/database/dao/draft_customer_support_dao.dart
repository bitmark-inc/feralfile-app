import 'package:autonomy_flutter/database/entity/draft_customer_support.dart';
import 'package:floor/floor.dart';

@dao
abstract class DraftCustomerSupportDao {
  @Query('SELECT * FROM DraftCustomerSupport ORDER BY createdAt LIMIT :limit')
  Future<List<DraftCustomerSupport>> fetchDrafts(int limit);

  @Query(
      'SELECT * FROM DraftCustomerSupport WHERE issueID = :issueID ORDER BY createdAt DESC')
  Future<List<DraftCustomerSupport>> getDrafts(String issueID);

  @Query('SELECT * FROM DraftCustomerSupport ORDER BY createdAt DESC')
  Future<List<DraftCustomerSupport>> getAllDrafts();

  @Query(
      'UPDATE DraftCustomerSupport SET issueID = :newIssueID WHERE issueID = :oldIssueID')
  Future<void> updateIssueID(String oldIssueID, String newIssueID);

  @Insert(onConflict: OnConflictStrategy.replace)
  Future<void> insertDraft(DraftCustomerSupport draft);

  @delete
  Future<void> deleteDraft(DraftCustomerSupport draft);

  @Query('DELETE FROM DraftCustomerSupport')
  Future<void> removeAll();
}
