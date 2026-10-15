import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../constants/api_constants.dart';
import '../models/feature_flags.dart';
import 'api_client.dart';

/// App-wide access to the feature flags. Read them through [Features] only,
/// never by calling the endpoint directly, so there is one place to gate on.
class Features {
  Features._();

  static final ValueNotifier<FeatureFlags> notifier = ValueNotifier(
    FeatureFlags.investingOnly,
  );

  static FeatureFlags get current => notifier.value;

  static bool get tradingEnabled => current.trading;

  /// Fetches the flags once and publishes them. Never throws: on any failure
  /// the app stays on [FeatureFlags.investingOnly].
  static Future<FeatureFlags> load({ApiClient? client}) async {
    final flags = await FeatureService.fetch(client: client);
    notifier.value = flags;
    return flags;
  }

  @visibleForTesting
  static void reset([FeatureFlags flags = FeatureFlags.investingOnly]) {
    notifier.value = flags;
  }
}

class FeatureService {
  static Future<FeatureFlags> fetch({ApiClient? client}) async {
    try {
      final response = await (client ?? ApiClient.shared)
          .get(Uri.parse(ApiConstants.featuresURL))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode != 200) return FeatureFlags.investingOnly;
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) return FeatureFlags.investingOnly;
      return FeatureFlags.fromJson(body);
    } catch (_) {
      return FeatureFlags.investingOnly;
    }
  }
}
