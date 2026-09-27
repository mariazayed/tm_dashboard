import 'dart:convert';

import 'api_client.dart';
import 'package:tm_dashboard/models/capital_model.dart';
import 'package:tm_dashboard/models/trade_model.dart';

import '../constants/api_constants.dart';
import '../enums/capital_reason_enum.dart';
import '../models/paginated_response.dart';

class CapitalService {
  static Future<void> create(List<dynamic> data) async {
    final response = await ApiClient.shared.post(
      Uri.parse(ApiConstants.capitalURL),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(data),
    );

    if (response.statusCode != 201 && response.statusCode != 200) {
      throw Exception('Failed to create capitals');
    }
  }

  static Future<List<CapitalModel>> getAll() async {
    final response = await ApiClient.shared.get(Uri.parse(ApiConstants.capitalURL));

    if (response.statusCode != 200) {
      throw Exception('Failed to fetch capitals');
    }

    final List data = jsonDecode(response.body);
    return data.map((e) => CapitalModel.fromJson(e)).toList();
  }

  /// Paginated fetch backing the Deposits & Withdraws screen and the
  /// Dashboard's capital lists -- a Capital row is booked for every
  /// deposit/withdraw AND every trade's PROFIT/LOSS, so this grows with
  /// trade volume too. Pass [reasons] (e.g. [DEPOSIT, WITHDRAW]) to filter
  /// server-side instead of paging through every PROFIT/LOSS row to find
  /// the handful of actual deposits/withdrawals.
  static Future<PaginatedResponse<CapitalModel>> searchPage({
    required int page,
    int size = 30,
    String sortBy = 'dateTime',
    String direction = 'DESC',
    List<CapitalReasonEnum>? reasons,
  }) {
    return fetchSearchPage<CapitalModel>(
      '${ApiConstants.capitalURL}/search',
      (json) => CapitalModel.fromJson(json),
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
      extra: reasons == null
          ? null
          : {'reasons': reasons.map((r) => r.value).toList()},
    );
  }

  /// Drop-in replacement for [getAll] that fetches the full, unfiltered
  /// capital history (every deposit/withdraw AND every trade's PROFIT/LOSS
  /// row), but a page at a time under the hood via
  /// [searchPage]/[fetchAllPages] instead of one unbounded GET. Used by the
  /// Dashboard, which needs the complete history to compute stats/equity
  /// curves -- this is the same list whose unbounded growth (a row per
  /// trade, continuously auto-imported via MT5) drove the original memory
  /// investigation, so it's paginated at the transport level even though
  /// the full result is still assembled client-side.
  static Future<List<CapitalModel>> getAllPaged() {
    return fetchAllPages<CapitalModel>(
      '${ApiConstants.capitalURL}/search',
      (json) => CapitalModel.fromJson(json),
      sortBy: 'dateTime',
      direction: 'DESC',
    );
  }

  /// Fetches every deposit/withdraw row, paged under the hood via
  /// [searchPage]/[fetchAllPages] instead of one unbounded GET, and instead
  /// of getAll()'s old cost of pulling every PROFIT/LOSS row too. Used by
  /// the Deposits & Withdraws screen, which needs the complete filtered set
  /// at once so its totals are always exact (never a partial sum while more
  /// pages are still loading).
  static Future<List<CapitalModel>> getDepositsAndWithdrawsPaged() {
    return fetchAllPages<CapitalModel>(
      '${ApiConstants.capitalURL}/search',
      (json) => CapitalModel.fromJson(json),
      sortBy: 'dateTime',
      direction: 'DESC',
      extra: {
        'reasons': [
          CapitalReasonEnum.DEPOSIT.value,
          CapitalReasonEnum.WITHDRAW.value,
        ],
      },
    );
  }
}
