// create exhibition_detail bloc

import 'package:autonomy_flutter/au_bloc.dart';
import 'package:autonomy_flutter/screen/exhibition_details/exhibition_detail_state.dart';
import 'package:autonomy_flutter/service/feralfile_service.dart';

class ExhibitionDetailBloc
    extends AuBloc<ExhibitionDetailEvent, ExhibitionDetailState> {
  final FeralFileService _feralFileService;

  ExhibitionDetailBloc(this._feralFileService)
      : super(ExhibitionDetailState()) {}
}
