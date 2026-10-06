# tm_dashboard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.


## Frontend data cache

All API-backed pages use `ApiClient.shared` through their existing services,
including paginated searches and planner views. Local-only screens (risk
calculations and saved trading hours) do not make backend requests.

- GET and explicit read-only search requests share a session-memory cache.
  Keys include method, full URL/query, headers, and search body (including
  page, sorting, and filters). Identical in-flight reads share one request.
- Data expires after 30 seconds; static lookup data expires after 30 minutes.
  Expiration is checked on the next read, without background polling.
- LRU eviction bounds retained response bodies to 8 MiB and 128 entries.
  Oversized responses are delivered without caching. Nothing is persisted
  to disk, and cache hits are parsed into fresh mutable domain models except
  shared static lookup data.
- Successful writes invalidate all resources, including dependent summaries.
  Failed writes preserve cached reads. Failed/malformed read responses and
  search error envelopes are not cached. Pre-invalidation requests cannot
  repopulate the cache or capture new readers.
- Existing refresh controls clear the cache before loading and pull-to-refresh
  waits for the load to finish. Cached data is not used as an offline fallback.
- New services should use `ApiClient.shared.get/search/post/put/patch/delete`.
  Only read-only searches may use `search`; writes must use mutation methods.
  Call `clear()` when adding account switching or changing API environments.
- A reusable HTTP client reduces connection setup; page model parsing runs
  concurrently while preserving result order. Existing pagination stays intact.

Cache regression tests:

```sh
flutter test test/api_client_test.dart test/service_cache_test.dart
```

## Invest tracker (auth)

The **Invest** menu entry opens a personal investing tracker (plan: $300/month into VT). It is the
only protected part of the app; the trade-journal screens remain open as before.

- Sign in with the single-user password configured on `tm-server` (see its
  `docs/INVESTMENT_TRACKER.md`). The bearer token is kept in `shared_preferences` and re-checked
  with `GET /api/v1/auth/me` on startup.
- `ApiClient` attaches `Authorization: Bearer <token>` automatically once signed in.
- Routes under `/invest` redirect to `/login` when signed out (`lib/screens/auth/auth_guard.dart`).
- **Contributions** (`/invest/contributions`): add, edit and delete monthly buys. Shares and price
  fill each other in from the amount. The Invest home page shows this month's status (done, due in
  N days, overdue), the streak and a chip per month.
- **CSV:** *Copy CSV* puts the export on the clipboard; *Import CSV* takes pasted text. Import is
  all-or-nothing and lists every bad row; re-importing the same data skips duplicates.
- **Performance:** the Invest home page shows invested, value, gain and average cost, and says
  which day the price is from (it warns when it is out of date). *Refresh prices* asks the server
  to fetch new closes; if the price source is down you keep seeing the last saved prices.
- **Dashboard:** the Invest home page is a single column (capped at 900px wide) with summary
  tiles (invested, value, gain, average cost, shares, month streak), an *Invested vs value* line
  chart with a 3M / 1Y / All toggle, the consistency card, and a projection panel.
  - The chart draws value (solid blue) against invested (dashed grey), starts at zero, and has a
    tooltip plus a *Show data table* view with the same numbers. It needs two days of data.
  - The projection starts from your current value, adds the monthly amount you type, and shows 5%,
    7% and 9% a year over 1-40 years (effective annual rate, compounded monthly). They are
    illustrations, not predictions.
- Note: `shared_preferences` is not encrypted storage; switch to `flutter_secure_storage` before
  distributing builds to other devices.
