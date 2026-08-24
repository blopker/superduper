import 'package:url_launcher/url_launcher.dart';

// Kept as an interface so navigation can be tested without launching another app.
// ignore: one_member_abstracts
abstract interface class ExternalLinkLauncher {
  Future<bool> open(Uri uri);
}

final class SystemExternalLinkLauncher implements ExternalLinkLauncher {
  const SystemExternalLinkLauncher();

  @override
  Future<bool> open(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
