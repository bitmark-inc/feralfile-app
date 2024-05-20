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
      final isSubscribed = await injector.get<IAPService>().isSubscribed();
      final List<ExhibitionDetail> exhibitionDetails = [];
      if (isSubscribed) {
        final allExhibitions = await _feralFileService.getAllExhibitions();
        exhibitionDetails.addAll(allExhibitions);
      } else {
        final featuredExhibition =
            await _feralFileService.getFeaturedExhibition();
        exhibitionDetails.add(featuredExhibition);
      }
      emit(state.copyWith(exhibitions: exhibitionDetails));
    });
  }
}
