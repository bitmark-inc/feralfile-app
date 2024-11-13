import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_series.dart';
import 'package:autonomy_flutter/screen/alumni_details/alumni_details_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/util/feralfile_alumni_ext.dart';
import 'package:nft_collection/models/user_collection.dart';
import 'package:nft_collection/services/indexer_service.dart';

class AlumniDetailsEvent {}

class AlumniDetailsFetchAlumniEvent extends AlumniDetailsEvent {
  final String alumniID;

  AlumniDetailsFetchAlumniEvent({required this.alumniID});
}

class AlumniDetailsBloc extends AuBloc<AlumniDetailsEvent, AlumniDetailsState> {
  final FeralFileService _feralFileService = injector<FeralFileService>();

  AlumniDetailsBloc() : super(AlumniDetailsState()) {
    on<AlumniDetailsFetchAlumniEvent>((event, emit) async {
      final alumni = await _feralFileService.getAlumniDetail(event.alumniID);
      final artworks = await _feralFileService.exploreArtworks(
        artistIds: alumni.allRelatedAccountIDs,
      );

      final indexerCollections =
          await getIndexerUserCollections(alumni.allRelatedAddresses);
      final userCollections =
          await mergeCollectionAndSeries(indexerCollections, artworks.result);
      final exhibitions = await _feralFileService.getAllExhibitions(
        relatedAlumniAccountIDs: alumni.allRelatedAccountIDs,
      );
      final post = await _feralFileService.getPosts(
        relatedAlumniAccountIDs: alumni.allRelatedAccountIDs,
      );
      emit(AlumniDetailsState(
        alumni: alumni,
        series: artworks.result,
        exhibitions: exhibitions,
        posts: post,
        userCollections: indexerCollections,
      ));
    });
  }
}

Future<List<FFSeries>> getFeralfileSeries(List<String> artistIds) async {
  final feralFileService = injector<FeralFileService>();
  final series = await feralFileService.exploreArtworks(artistIds: artistIds);
  return series.result;
}

Future<List<UserCollection>> getIndexerUserCollections(
    List<String> artistIds) async {
  final indexerService = injector<IndexerService>();
  final List<UserCollection> collections = [];
  for (var artistId in artistIds) {
    final collection = await indexerService.getUserCollections(artistId);
    collections.addAll(collection);
  }
  return collections;
}

Future<List<ArtistCollection>> mergeCollectionAndSeries(
    List<UserCollection> collections, List<FFSeries> series) async {
  final List<ArtistCollection> result = [];
  for (var collection in collections) {
    final isDuplicated = false;
    if (!isDuplicated) {
      result.add(collection);
    }
  }
  return result;
}
