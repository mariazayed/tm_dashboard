import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Client-side mirror of the backend's `SearchResponse<T>` wrapper (see
/// `trademind.tm_server.base.SearchResponse` in tm-server) returned by every
/// `POST .../search` endpoint. Used by every list screen's paginated fetch
/// (`*Service.searchPage()`) so trades/capitals/goals/etc. are loaded a page
/// at a time instead of a single `getAll()` pulling the entire, ever-growing
/// table into memory on every screen visit.
class PaginatedResponse<T> {
  final List<T> data;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final bool last;

  const PaginatedResponse({
    required this.data,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.last,
  });
}

/// Parses a `SearchResponse<T>`-shaped JSON body into a [PaginatedResponse].
/// A top-level async function (not a factory constructor) because a few
/// models -- notably `Trade.fromJson` -- are themselves `Future<T>` (they
/// await a nested `Strategy.fromJson`), so [fromJsonT] is allowed to return
/// either `T` or `Future<T>`.
Future<PaginatedResponse<T>> parsePaginatedResponse<T>(
  Map<String, dynamic> json,
  FutureOr<T> Function(Map<String, dynamic>) fromJsonT,
) async {
  if (json['status'] != 'success') {
    throw Exception(json['errorMessage'] ?? 'Search request failed');
  }

  final List raw = json['data'] ?? [];
  final items = <T>[];
  for (final e in raw) {
    items.add(await fromJsonT(e as Map<String, dynamic>));
  }

  return PaginatedResponse<T>(
    data: items,
    page: (json['page'] ?? 0) as int,
    size: (json['size'] ?? items.length) as int,
    totalElements: (json['totalElements'] ?? items.length) as int,
    totalPages: (json['totalPages'] ?? 1) as int,
    last: (json['last'] ?? true) as bool,
  );
}

/// POSTs a page request to a `.../search` endpoint and parses the result.
/// Shared by every `*Service.searchPage()` so each service only has to name
/// its own search URL and model's `fromJson`. [sortBy] must be a real field
/// on the backend entity (it maps straight to a JPA `Sort.by(...)`); each
/// caller picks one that gives the newest/most relevant items first.
Future<PaginatedResponse<T>> fetchSearchPage<T>(
  String searchUrl,
  FutureOr<T> Function(Map<String, dynamic>) fromJsonT, {
  required int page,
  int size = 20,
  String sortBy = 'id',
  String direction = 'DESC',
  // Extra filter fields a particular *SearchRequest DTO exposes beyond
  // page/size/sortBy/direction -- e.g. Capital's `reasons` list, so the
  // Deposits & Withdraws screen can filter server-side instead of paging
  // through every PROFIT/LOSS row booked per trade to find them.
  Map<String, dynamic>? extra,
}) async {
  final response = await http.post(
    Uri.parse(searchUrl),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      'page': page,
      'size': size,
      'sortBy': sortBy,
      'direction': direction,
      if (extra != null) ...extra,
    }),
  );

  if (response.statusCode != 200) {
    throw Exception('Failed to fetch page $page from $searchUrl');
  }

  return parsePaginatedResponse<T>(jsonDecode(response.body), fromJsonT);
}

/// Fetches every page from a `.../search` endpoint and concatenates them,
/// for the smaller/bounded list screens (goals, reminder notes, strict
/// rules, strategies, assets, deposits & withdraws) where the full list is
/// still wanted at once (a delete/create action refreshes it, totals need
/// to be exact, etc.) but the *transport* shouldn't be one unbounded
/// request -- this replaces a plain `Service.getAll()` with real paging
/// underneath, page by page, same as the infinite-scroll screens use, just
/// driven to completion instead of by scroll position.
Future<List<T>> fetchAllPages<T>(
  String searchUrl,
  FutureOr<T> Function(Map<String, dynamic>) fromJsonT, {
  int size = 50,
  String sortBy = 'id',
  String direction = 'DESC',
  Map<String, dynamic>? extra,
}) async {
  final items = <T>[];
  var page = 0;
  var hasMore = true;
  while (hasMore) {
    final result = await fetchSearchPage<T>(
      searchUrl,
      fromJsonT,
      page: page,
      size: size,
      sortBy: sortBy,
      direction: direction,
      extra: extra,
    );
    items.addAll(result.data);
    hasMore = !result.last;
    page++;
  }
  return items;
}
