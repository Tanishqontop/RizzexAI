/// Returns true when [url] is a non-empty http(s) URL suitable for network images.
bool isValidNetworkImageUrl(String? url) {
  if (url == null) return false;
  final trimmed = url.trim();
  if (trimmed.isEmpty) return false;
  return trimmed.startsWith('http://') || trimmed.startsWith('https://');
}

/// First usable image URL from [candidates], or null.
String? firstValidImageUrl(Iterable<String?> candidates) {
  for (final candidate in candidates) {
    if (isValidNetworkImageUrl(candidate)) {
      return candidate!.trim();
    }
  }
  return null;
}

/// Filters a photo list to valid, non-empty network URLs.
List<String> validImageUrls(Iterable<String>? urls) {
  if (urls == null) return [];
  return urls
      .map((url) => url.trim())
      .where(isValidNetworkImageUrl)
      .toList();
}
