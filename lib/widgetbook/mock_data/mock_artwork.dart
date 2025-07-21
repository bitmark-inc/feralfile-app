import 'package:autonomy_flutter/model/ff_artwork.dart';
import 'package:autonomy_flutter/widgetbook/mock_data/data/artwork.dart';

class MockArtwork {
  static Artwork bend = Artwork.fromJson(bendArtwork);
  static Artwork metasoto = Artwork.fromJson(metasotoArtwork);
  static Artwork colorsOfNoise = Artwork.fromJson(colorsOfNoiseArtwork);
  static Artwork post2 = Artwork.fromJson(post2Artwork);
  static Artwork uneasyDream = Artwork.fromJson(uneasyDreamArtwork);
  static Artwork smokeHands = Artwork.fromJson(smokeHandsArtwork);
  static Artwork ninePlus11 = Artwork.fromJson(ninePlus11Artwork);
  static Artwork superbloom = Artwork.fromJson(superbloomArtwork);
  static Artwork unsupervisedMachineHallucinations =
      Artwork.fromJson(unsupervisedMachineHallucinationsArtwork);
  static Artwork alleluiaAlleluia = Artwork.fromJson(alleluiaAlleluiaArtwork);
  static Artwork polymorphism82 = Artwork.fromJson(polymorphism82Artwork);
  static Artwork fLight = Artwork.fromJson(fLightArtwork);
  static Artwork unsupervisedDataUniverseMoma =
      Artwork.fromJson(unsupervisedDataUniverseMomaArtwork);
  static Artwork entity = Artwork.fromJson(entityArtwork);
  static Artwork transparentGrit = Artwork.fromJson(transparentGritArtwork);
  static Artwork payphone = Artwork.fromJson(payphoneArtwork);

  static List<Artwork> all = [
    metasoto,
    colorsOfNoise,
    post2,
    uneasyDream,
    smokeHands,
    ninePlus11,
    superbloom,
    unsupervisedMachineHallucinations,
    alleluiaAlleluia,
    polymorphism82,
    fLight,
    unsupervisedDataUniverseMoma,
    entity,
    transparentGrit,
    payphone
  ];
}
