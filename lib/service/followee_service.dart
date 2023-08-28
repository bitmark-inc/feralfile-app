import 'package:autonomy_flutter/database/app_database.dart';
import 'package:autonomy_flutter/database/dao/followee_dao.dart';
import 'package:autonomy_flutter/database/entity/followee.dart';
import 'package:autonomy_flutter/gateway/feed_api.dart';
import 'package:autonomy_flutter/model/feed.dart';
import 'package:autonomy_flutter/util/log.dart';
import 'package:collection/collection.dart';

class FolloweeService {
  final AppDatabase _appDatabase;
  final FeedApi _feedApi;

  FolloweeDao get _followeeDao => _appDatabase.followeeDao;

  // constructor
  FolloweeService(this._appDatabase, this._feedApi);

  Future<List<Followee>> getFollowees() async {
    final followees = await _followeeDao.findAllFollowees();
    final invalidAddresses = followees
        .where((element) =>
            element.address.length < 36 ||
            invalidAddress.contains(element.address))
        .toList();
    _followeeDao.deleteFollowees(invalidAddresses);
    _feedApi.deleteFollows(
        {"addresses": invalidAddresses.map((e) => e.address).toList()});
    return followees.where((element) => element.isFollowed).toList();
  }

  Future<List<Followee>> getFromAddresses(List<String> addresses) async {
    return await _followeeDao.findFolloweeByAddress(addresses);
  }

  Future<void> addArtistsCollection(List<String> artists) async {
    log.info("[FolloweeService] addArtistsCollection $artists");
    final existedFollowees = await _followeeDao.findFolloweeByAddress(artists);

    final addArtist = artists
        .where((element) =>
            existedFollowees.none((followee) => followee.address == element))
        .toList();
    await _insertFollowees(addArtist, COLLECTION_ARTIST);
    await _feedApi.postFollows({
      "addresses": addArtist,
    });

    final updateFollowee = existedFollowees
        .map((e) => e.copyWith(type: e.type | COLLECTION_ARTIST))
        .toList();
    await _followeeDao.updateFollowees(updateFollowee);
  }

  Future<void> deleteArtistsCollection(List<String> artists) async {
    log.info("[FolloweeService] deleteArtistsCollection $artists");
    final followees = await _followeeDao.findFolloweeByAddress(artists);

    final deletedFollowees = followees
        .where((element) => element.type == COLLECTION_ARTIST)
        .toList();
    await _followeeDao.deleteFollowees(deletedFollowees);
    final deleteAddresses = deletedFollowees.map((e) => e.address).toList();
    log.info("[FolloweeService] delete $deleteAddresses");
    await _feedApi.deleteFollows({
      "addresses": deleteAddresses,
    });

    final updateFollowees = followees
        .where((element) => element.type != COLLECTION_ARTIST)
        .toList();
    final updateAddresses = updateFollowees.map((e) => e.address).toList();
    log.info("[FolloweeService] update $updateAddresses");
    final newFollowees = updateFollowees
        .map((e) => e.copyWith(type: MANUAL_ADDED_ARTIST))
        .toList();
    _followeeDao.updateFollowees(newFollowees);
  }

  Future<Followee> addArtistManual(String artist) async {
    log.info("[FolloweeService] addArtistManual $artist");
    final existedFollowees = await _followeeDao.findFolloweeByAddress([artist]);

    if (existedFollowees.isEmpty) {
      final followees = await _insertFollowees([artist], MANUAL_ADDED_ARTIST);
      await _feedApi.postFollows({
        "addresses": [artist],
      });
      return followees.first;
    } else {
      final followee = existedFollowees.first;
      if (followee.type == MANUAL_ADDED_ARTIST) {
        return followee;
      } else {
        final newFollowee =
            followee.copyWith(type: MANUAL_ADDED_ARTIST, isFollowed: true);
        await _followeeDao.updateFollowees([newFollowee]);
        return newFollowee;
      }
    }
  }

  Future<void> removeArtistManual(Followee followee) async {
    log.info("[FolloweeService] removeArtistManual ${followee.address}");
    if (followee.type == MANUAL_ADDED_ARTIST) {
      await _followeeDao.deleteFollowees([followee]);
      await _feedApi.deleteFollows({
        "addresses": [followee.address],
      });
    }
  }

  Future<void> unfollowArtistManual(Followee followee) async {
    log.info("[FolloweeService] unfollowArtistManual ${followee.address}");
    final newFollowee = followee.copyWith(isFollowed: false);
    await _followeeDao.updateFollowees([newFollowee]);
    await _feedApi.deleteFollows({
      "addresses": [followee.address],
    });
  }

  Future<bool> syncFromServer() async {
    List<String> remoteFollowings = [];
    final localFollowee = await _followeeDao.findAllFollowees();

    var loop = true;
    FeedNext? next;
    while (loop) {
      final followingData =
          await _feedApi.getFollows(100, next?.serial, next?.timestamp);
      remoteFollowings.addAll(followingData.followings.map((e) => e.address));
      loop = followingData.followings.length >= 100;
      next = followingData.next;
    }

    log.info("[FolloweeService] syncFromServer remote $remoteFollowings");
    final addArtists = remoteFollowings
        .where((element) =>
            localFollowee.none((followee) => followee.address == element))
        .toList();
    log.info("[FolloweeService] syncFromServer addArtists $addArtists");
    _insertFollowees(addArtists, MANUAL_ADDED_ARTIST);

    final updateFollowees = localFollowee
        .where((element) =>
            element.isFollowed == false &&
            remoteFollowings.contains(element.address))
        .toList();
    log.info(
        "[FolloweeService] syncFromServer updateFollowees ${updateFollowees.map((e) => e.address).toList()}");
    final listUpdateFollowees =
        updateFollowees.map((e) => e.copyWith(isFollowed: true)).toList();
    await _followeeDao.updateFollowees(listUpdateFollowees);
    return addArtists.isNotEmpty || updateFollowees.isNotEmpty;
  }

  Future<List<Followee>> _insertFollowees(
      List<String> artists, int type) async {
    final now = DateTime.now();
    List<Followee> followees = artists
        .map((artist) => Followee(
            address: artist,
            type: type,
            isFollowed: true,
            createdAt: now,
            name: ""))
        .toList();
    log.info("[FolloweeService] insert $artists");
    await _followeeDao.insertFollowees(followees);
    return followees;
  }
}

const List<String> invalidAddress = [
  "0x0000000000000000000000000000000000000000",
];
