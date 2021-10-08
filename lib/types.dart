typedef Json = Map<String, dynamic>;

/// See [ApiCall._parseFunction].
typedef ResponseParseFunction<T> = T Function(Map<String, dynamic> json);
