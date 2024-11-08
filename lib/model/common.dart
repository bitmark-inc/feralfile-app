enum CloudFlareVariant {
  xs,
  s,
  m,
  l,
  xl,
  xxl;

  String get value {
    switch (this) {
      case CloudFlareVariant.xs:
        return 'xs';
      case CloudFlareVariant.s:
        return 's';
      case CloudFlareVariant.m:
        return 'm';
      case CloudFlareVariant.l:
        return 'l';
      case CloudFlareVariant.xl:
        return 'xl';
      case CloudFlareVariant.xxl:
        return 'xxl';
    }
  }
}
