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

## Invest tracker

The **Invest** menu entry opens a personal investing tracker (plan: $300/month into VT).

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
- **Journal** (`/invest/journal`): a timeline of quick notes, monthly check-ins and decisions.
  - *Quick note* opens a short form: type, optional mood 1-5, a markdown note with preview, and tags.
  - Tags autocomplete from the ones you already use; Enter or a comma adds one (`a, b` adds two).
    They are stored lower-case with no leading `#`, so `#Emotion` and `emotion` are the same tag.
  - *Monthly check-in* opens the same form pre-filled by the server with this month's contribution
    status, your streak and four prompts, linked to this month's buy and tagged `check-in`.
  - The timeline can be filtered by type and tag and searched by text (a case-insensitive substring
    match, with a short pause after typing), and loads 30 entries at a time.
- **Learning** (`/invest/learning`): three tabs.
  - *Reading list*: books, videos, articles and podcasts, grouped In progress / To do / Done. Tap one
    to open its link (http or https only). The menu changes status, edits or deletes.
  - *Notes*: markdown notes with an optional source and tags, searchable by title or text and
    filterable by source and tag. The card icon on a note makes a flashcard linked to it.
  - *Review*: today's flashcards. Read the question, tap *Show answer*, then grade yourself Again,
    Hard, Good or Easy; the server schedules the next review with SM-2 and the screen says when it
    comes back. *Manage all cards* lists, edits and deletes cards.
- **Rules and settings:**
  - The *My rules* card sits at the top of the Invest page (open by default). *Edit rules* opens a
    list where you add, edit (tap), delete and drag to reorder; up to 20 rules.
  - *Settings* edits the plan: monthly amount, currency, ticker, buy day (1-28), start date and
    timezone, plus buy-day email reminders (an address, and how many days later to nudge again).
    *Send a test email* checks the channel; the page warns if the server has no email settings.
  - Reminders arrive by email only. There is no push channel.
- **Your data:** *Settings > Copy all my data* puts the server's full JSON export on the clipboard
  (it says how many KB). It never touches disk on the device, and it holds your notes, so paste it
  into a file you keep safe. The server also takes nightly JSON backups and has a `pg_dump` script; see
  `docs/INVESTMENT_TRACKER.md` on the server.
- **Ask your journal** (`/invest/ask`, the *Ask your journal* button on the Invest page): a read-only chat
  over your own rules, journal entries and learning notes. The answer cites the entries it used as chips
  (tap one to read the excerpt the assistant saw, with a button to open the Journal or Learning screen).
  *Use journal* and *Use notes* switch those sources off for a question, and *See what will be sent* shows
  the exact prompt (standing instructions included) before you send. It never changes your data, does not
  give financial advice (an answer that tries to is replaced), and shows how many of today's AI calls are
  used. It needs the server to have AI switched on (`ai.enabled`, see `docs/INVESTMENT_TRACKER.md`); until
  then the screen says why and nothing is sent. *Cancel* only stops waiting: the server may still finish the
  call, which still counts toward the day's limit.
- **Recent consistency** (on the Rules page): the last 30 days checked against your own rules by plain code on the
  server, so it works with AI off. It flags a deviation without an earlier decision or with too short a wait, a plan
  change with no journal entry in the week before, and a missed month with no note. Tag an entry `decision` when you
  decide to deviate and `deviation` when you act. The wait is *Settings > Your rules* (hours; 0 turns that check off).
  Findings are prompts to look, not verdicts, and nothing is stored or marked.
- **AI status:** *Settings > AI assistant* says whether the server could call a model (the key lives only
  on the server and is never shown) and has *See what an AI would be shown*: the exact standing context,
  with switches to leave out your journal and learning notes and a counter against the 12,000-character
  limit.
- **Install as an app:** the web build is installable (Chrome/Edge: *Install*; Safari: *Add to Home
  Screen*). `web/manifest.json` is checked by a test (name, start URL, standalone display, 192/512 and
  maskable icons that exist and match their declared sizes, theme colour). The icons are still
  Flutter's defaults; swap the four PNGs in `web/icons/` for your own, keeping the sizes. Flutter's
  service worker caches the app shell, so the page opens offline, but every screen needs the server for
  its data, so there is no offline data mode.
- **Tests:** `test/invest_flow_test.dart` drives the real screens against an in-memory stand-in for the
  server (add a buy, see the dashboard change, delete it, a rejected buy). The server repo has the
  full-stack counterpart, `InvestEndToEndTest`, which runs the same story over HTTP against PostgreSQL.
- Note: `shared_preferences` is not encrypted storage; switch to `flutter_secure_storage` before
  distributing builds to other devices.
