import 'package:url_launcher/url_launcher.dart';

// Kept as an interface so navigation can be tested without launching another app.
abstract interface class ExternalLinkLauncher {
  Future<bool> open(Uri uri);
}

final class SystemExternalLinkLauncher implements ExternalLinkLauncher {
  const new();

  @override
  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
