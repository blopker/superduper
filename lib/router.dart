import 'package:flutter/material.dart';
import 'package:superduper/main.dart';
import 'package:superduper/screens/bike_detail_screen.dart';
import 'package:superduper/screens/bike_list_screen.dart';
import 'package:superduper/screens/debug_screen.dart';

/// Router class for the SuperDuper app.
///
/// This handles navigation between the different screens in the app.
class AppRouter {
  static const String home = '/';
  static const String bikeList = '/bikes';
  static const String bikeDetail = '/bike';
  static const String debug = '/debug';

  /// Get the named routes for the app.
  static Map<String, WidgetBuilder> getRoutes() {
    return {
      home: (_) => const HomePage(),
      bikeList: (_) => const BikeListScreen(),
      debug: (_) => const DebugScreen(),
    };
  }

  /// Generate routes for screens that need parameters.
  static Route<dynamic>? generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case bikeDetail:
        final args = settings.arguments as BikeDetailArgs;
        return MaterialPageRoute(
          builder: (_) => BikeDetailScreen(bikeId: args.bikeId),
        );
      default:
        return null;
    }
  }

  /// Navigate to the bike detail screen.
  static void navigateToBikeDetail(BuildContext context, String bikeId) {
    Navigator.of(context).pushNamed(
      bikeDetail,
      arguments: BikeDetailArgs(bikeId: bikeId),
    );
  }

  /// Navigate to the bike list screen.
  static void navigateToBikeList(BuildContext context) {
    Navigator.of(context).pushNamed(bikeList);
  }

  /// Navigate to the home screen.
  static void navigateToHome(BuildContext context) {
    Navigator.of(context).pushNamedAndRemoveUntil(home, (route) => false);
  }
  
  /// Navigate to the debug screen.
  static void navigateToDebug(BuildContext context) {
    Navigator.of(context).pushNamed(debug);
  }
}

/// Arguments for the bike detail screen.
class BikeDetailArgs {
  final String bikeId;

  BikeDetailArgs({required this.bikeId});
}