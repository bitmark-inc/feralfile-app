extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }

  String mask(int number) {
    return "[${this.substring(0, number)}...${this.substring(this.length - number, this.length)}]";
  }

  String maskIfNeeded() {
    if (this.contains(' ')) return this;
    return (this.length >= 36) ? this.mask(4) : this;
  }

  String? toIdentityOrMask(Map<String, String>? identityMap) {
    if (this.isEmpty) return null;
    final identity = identityMap?[this];
    return (identity != null && identity.isNotEmpty)
        ? identity
        : this.maskIfNeeded();
  }
}
