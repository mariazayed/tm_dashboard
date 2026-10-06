import 'auth_cubit.dart';

const loginPath = '/login';
const investPath = '/invest';

/// Router redirect rule. Only the investing tracker is protected; the
/// existing trade-journal screens stay open as before.
String? authRedirect(AuthStatus status, Uri location) {
  final signedIn = status == AuthStatus.authenticated;
  final path = location.path;
  final isInvest = path == investPath || path.startsWith('$investPath/');

  if (isInvest && !signedIn) {
    final from = location.toString();
    return Uri(path: loginPath, queryParameters: {'from': from}).toString();
  }
  if (path == loginPath && signedIn) {
    final from = location.queryParameters['from'];
    return (from != null && from.startsWith(investPath)) ? from : investPath;
  }
  return null;
}
