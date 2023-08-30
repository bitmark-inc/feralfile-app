import 'package:autonomy_flutter/database/entity/followee.dart';
import 'package:floor/floor.dart';

@dao
abstract class FolloweeDao {
  @Query('SELECT * FROM Followee order by createdAt DESC')
  Future<List<Followee>> findAllFollowees();

  @Query('SELECT * FROM Followee WHERE address IN (:addresses)')
  Future<List<Followee>> findFolloweeByAddress(List<String> addresses);

  @Insert(onConflict: OnConflictStrategy.ignore)
  Future<void> insertFollowees(List<Followee> followees);

  @update
  Future<void> updateFollowees(List<Followee> followees);

  @delete
  Future<void> deleteFollowees(List<Followee> followees);

  @Query('DELETE FROM Followee')
  Future<void> removeAll();
}
