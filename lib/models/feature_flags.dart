/// Which product areas the backend has switched on. Mirrors `GET /api/v1/features`.
///
/// Trading is off unless the server says otherwise: the app is investing-first,
/// so any missing, malformed or unreachable answer must fail closed.
class FeatureFlags {
  const FeatureFlags({this.trading = false, this.investing = true});

  /// Safe fallback used before the server has answered and whenever it cannot.
  static const FeatureFlags investingOnly = FeatureFlags();

  final bool trading;
  final bool investing;

  factory FeatureFlags.fromJson(Map<String, dynamic> json) => FeatureFlags(
    trading: json['trading'] == true,
    investing: json['investing'] != false,
  );

  @override
  bool operator ==(Object other) =>
      other is FeatureFlags &&
      other.trading == trading &&
      other.investing == investing;

  @override
  int get hashCode => Object.hash(trading, investing);
}
