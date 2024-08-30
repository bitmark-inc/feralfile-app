class UrlHepler {
  // remove http:// or https:// and www. from url and also / from end of url
  static String shortenUrl(String url) {
    url = url.trim();
    if (url.startsWith('http://')) {
      url = url.substring(7);
    } else if (url.startsWith('https://')) {
      url = url.substring(8);
    }
    if (url.startsWith('www.')) {
      url = url.substring(4);
    }
    if (url.endsWith('/')) {
      url = url.substring(0, url.length - 1);
    }
    return url;
  }
}
