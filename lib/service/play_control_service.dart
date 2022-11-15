class PlayControlService {
  int timer;
  bool isShuffle;
  bool isLoop;
  PlayControlService({
    required this.timer,
    required this.isShuffle,
    required this.isLoop,
  });

  PlayControlService onChangeTime() {
    if (timer < 20) {
      return copyWith(timer: timer == 0 ? 10 : timer + 5);
    } else {
      return copyWith(timer: 0);
    }
  }

  PlayControlService copyWith({
    int? timer,
    bool? isShuffle,
    bool? isLoop,
  }) {
    return PlayControlService(
      timer: timer ?? this.timer,
      isShuffle: isShuffle ?? this.isShuffle,
      isLoop: isLoop ?? this.isLoop,
    );
  }
}
