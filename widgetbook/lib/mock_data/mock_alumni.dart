import 'package:autonomy_flutter/model/ff_alumni.dart';
import 'package:widgetbook_workspace/mock_data/data/artist_alumni.dart';

class MockAlumniData {
  static AlumniAccount get driessensVerstappen =>
      AlumniAccount.fromJson(driessensVerstappenAlumni);

  static AlumniAccount get yusukeShonoAndAlexEstorick =>
      AlumniAccount.fromJson(yusukeShonoAndAlexEstorickAlumni);

  static AlumniAccount get satoshiAizawa =>
      AlumniAccount.fromJson(satoshiAizawaAlumni);

  static AlumniAccount get saekoEhara =>
      AlumniAccount.fromJson(saekoEharaAlumni);

  // mole3Alumni
  static AlumniAccount get mole3 => AlumniAccount.fromJson(mole3Alumni);

  // misakiNakanoAlumni
  static AlumniAccount get misakiNakano =>
      AlumniAccount.fromJson(misakiNakanoAlumni);

  // okazzAlumni
  static AlumniAccount get okazz => AlumniAccount.fromJson(okazzAlumni);

  // senbakuAlumni
  static AlumniAccount get senbaku => AlumniAccount.fromJson(senbakuAlumni);

  // shunsukeTakawoAlumni
  static AlumniAccount get shunsukeTakawo =>
      AlumniAccount.fromJson(shunsukeTakawoAlumni);

  // kaoruTanakaAlumni
  static AlumniAccount get kaoruTanaka =>
      AlumniAccount.fromJson(kaoruTanakaAlumni);

  // kazuhiroTanimotoAlumni
  static AlumniAccount get kazuhiroTanimoto =>
      AlumniAccount.fromJson(kazuhiroTanimotoAlumni);

  // ykxotkxAlumni
  static AlumniAccount get ykxotkx => AlumniAccount.fromJson(ykxotkxAlumni);

  static List<AlumniAccount> get listAll => [
        driessensVerstappen,
        yusukeShonoAndAlexEstorick,
        satoshiAizawa,
        saekoEhara,
        mole3,
        misakiNakano,
        okazz,
        senbaku,
        shunsukeTakawo,
        kaoruTanaka,
        kazuhiroTanimoto,
        ykxotkx,
      ];

  static List<AlumniAccount> getListArtist() {
    return listAll.where((alumni) => alumni.isArtist ?? false).toList();
  }

  static List<AlumniAccount> getListCurator() {
    return listAll.where((alumni) => alumni.isCurator ?? false).toList();
  }
}
