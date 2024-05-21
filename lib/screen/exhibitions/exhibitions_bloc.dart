import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/common/injector.dart';
import 'package:autonomy_flutter/model/ff_exhibition.dart';
import 'package:autonomy_flutter/screen/exhibitions/exhibitions_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';
import 'package:autonomy_flutter/service/iap_service.dart';

class ExhibitionBloc extends AuBloc<ExhibitionsEvent, ExhibitionsState> {
  final FeralFileService _feralFileService;

  ExhibitionBloc(this._feralFileService) : super(ExhibitionsState()) {
    on<GetAllExhibitionsEvent>((event, emit) async {
      final result = await Future.wait([
        injector.get<IAPService>().isSubscribed(),
        _feralFileService.getFeaturedExhibition(),
        _feralFileService.getAllExhibitions()
      ]);
      final isSubscribed = result[0] as bool;
      final featuredExhibition = result[1] as ExhibitionDetail;
      final proExhibitions = result[2] as List<ExhibitionDetail>
        ..removeWhere((element) =>
            element.exhibition.id == featuredExhibition.exhibition.id);

      emit(state.copyWith(
        freeExhibitions: [featuredExhibition],
        proExhibitions: proExhibitions,
        isSubscribed: isSubscribed,
      ));
    });
  }
}
