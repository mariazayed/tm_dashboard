import 'package:intl/intl.dart';

/// Money is carried as integer cents everywhere; these helpers convert at the
/// edges so no floating point ever touches an amount.
class Money {
  Money._();

  /// "300", "300.5", "$1,200.00" -> cents. Returns null when the text is not a
  /// valid amount or has more than two decimal places.
  static int? parseCents(String text) {
    final cleaned = text.trim().replaceAll(r'$', '').replaceAll(',', '');
    final match = RegExp(r'^(\d+)(?:\.(\d{1,2}))?$').firstMatch(cleaned);
    if (match == null) return null;
    final whole = int.parse(match.group(1)!);
    final fraction = (match.group(2) ?? '').padRight(2, '0');
    return whole * 100 + int.parse(fraction);
  }

  /// 30000 -> "300.00" (no symbol), for filling text fields.
  static String plain(int cents) => (cents / 100).toStringAsFixed(2);

  /// 123456 -> "$1,234.56" for the given ISO currency code.
  static String format(int cents, String currency) =>
      NumberFormat.simpleCurrency(name: currency).format(cents / 100);
}

/// Linked arithmetic for the add-contribution form.
class ContributionMath {
  ContributionMath._();

  static double? sharesFor(int amountCents, double price) =>
      price > 0 ? (amountCents / 100) / price : null;

  static double? priceFor(int amountCents, double shares) =>
      shares > 0 ? (amountCents / 100) / shares : null;
}
