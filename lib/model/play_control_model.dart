class PlayControlModel {
  int timer;
  bool isShuffle;

  PlayControlModel({
    this.timer = 0,
    this.isShuffle = false,
  });

  PlayControlModel onChangeTime() {
    if (timer < 20) {
      return copyWith(timer: timer == 0 ? 10 : timer + 5);
    } else {
      return copyWith(timer: 0);
    }
  }

  PlayControlModel copyWith({
    int? timer,
    bool? isShuffle,
  }) =>
      PlayControlModel(
        timer: timer ?? this.timer,
        isShuffle: isShuffle ?? this.isShuffle,
      );

  Map<String, dynamic> toJson() => <String, dynamic>{
        'timer': timer,
        'isShuffle': isShuffle,
      };

  factory PlayControlModel.fromJson(Map<String, dynamic> map) =>
      PlayControlModel(
        timer: map['timer'] as int,
        isShuffle: map['isShuffle'] as bool,
      );

  @override
  bool operator ==(covariant PlayControlModel other) {
    if (identical(this, other)) {
      return true;
    }

    return other.timer == timer && other.isShuffle == isShuffle;
  }

  @override
  int get hashCode => timer.hashCode ^ isShuffle.hashCode;
}
