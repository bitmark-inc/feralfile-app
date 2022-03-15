extension BigEndian on int {
  List<int> uint32BE() {
    return [
      (this >> 24) & 0xff,
      (this >> 16) & 0xff,
      (this >> 8) & 0xff,
      this & 0xff
    ];
  }

  List<int> uint32LE() {
    return [
      this & 0xff,
      (this >> 8) & 0xff,
      (this >> 16) & 0xff,
      (this >> 24) & 0xff
    ];
  }

  List<int> varint() {
    if (this < 0xfd) {
      return [this & 0xff];
    } else if (this <= 0xffff) {
      return [0xfd, this & 0xff, (this >> 8) & 0xff];
    } else {
      return [0xfe] + this.uint32LE();
    }
  }
}
