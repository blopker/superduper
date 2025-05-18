import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:superduper/screens/bike_edit_sheet.dart';
import 'package:superduper/services/bike_repository.dart';
import 'package:superduper/services/bluetooth_service.dart';
import 'package:superduper/utils/logger.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// A debug screen with various tools and information for development.
class DebugScreen extends ConsumerStatefulWidget {
  const DebugScreen({super.key});

  @override
  ConsumerState<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends ConsumerState<DebugScreen> with WidgetsBindingObserver {
  String _appVersion = 'Loading...';
  String _buildNumber = '';
  final List<String> _logs = [];

  @override
  void initState() {
    super.initState();
    _loadAppInfo();
    _setupLogCapture();
    
    // Simulate some log entries for demonstration
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _logs.add('[INFO] Loaded bike settings');
          _logs.add('[INFO] Bluetooth service initialized');
        });
      }
    });
  }

  Future<void> _loadAppInfo() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
        _buildNumber = packageInfo.buildNumber;
      });
    } catch (e) {
      setState(() {
        _appVersion = 'Error loading version';
      });
    }
  }

  void _setupLogCapture() {
    // Since we can't directly subscribe to logger events,
    // we'll just add an initial log entry
    log.i(SDLogger.UI, 'Debug screen initialized');
    
    // Add the initial log to our display list
    setState(() {
      _logs.add('[INFO] Debug screen initialized');
    });
    
    // We could implement a more robust log capture mechanism here
    // by extending the logger functionality, but for now this is sufficient
  }

  // Function to generate a random MAC address
  String _generateRandomMac() {
    final random = Random();
    final parts = List.generate(6, (_) => random.nextInt(256));
    return parts
        .map((part) => part.toRadixString(16).padLeft(2, '0'))
        .join(':');
  }

  @override
  void dispose() {
    // Clean up any resources
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bikes = ref.watch(bikesProvider).valueOrNull ?? [];
    final isScanning = ref.watch(isScanningStatusProvider).valueOrNull ?? false;
    final repository = ref.watch(bikeRepositoryProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Debug Console'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() {
                _logs.clear();
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // App Info Section
              _buildSectionHeader('App Information'),
              _buildInfoCard([
                'Version: $_appVersion (Build $_buildNumber)',
                'Platform: ${defaultTargetPlatform.name}',
                'Debug Mode: ${kDebugMode ? 'Yes' : 'No'}',
              ]),

              const SizedBox(height: 24),

              // Bikes Section
              _buildSectionHeader('Bikes (${bikes.length})'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final bike in bikes)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${bike.name} (${bike.id.substring(0, 8)})',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, size: 20),
                              color: Colors.blue,
                              onPressed: () {
                                BikeEditBottomSheet.show(context, bike)
                                    .then((updatedBike) {
                                  if (updatedBike != null) {
                                    ref
                                        .read(bikeRepositoryProvider)
                                        .updateBike(updatedBike);
                                  }
                                });
                              },
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, size: 20),
                              color: Colors.red,
                              onPressed: () {
                                repository.deleteBike(bike.id);
                              },
                            ),
                          ],
                        ),
                      ),
                    if (bikes.isEmpty)
                      const Text(
                        'No bikes found',
                        style: TextStyle(color: Colors.grey),
                      ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () {
                        final mac = _generateRandomMac();
                        final randomId =
                            'debug_${DateTime.now().millisecondsSinceEpoch}';
                        repository.addBike(randomId, mac);
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Add Test Bike'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.withOpacity(0.2),
                        foregroundColor: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Bluetooth Section
              _buildSectionHeader('Bluetooth'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Status: ${isScanning ? 'Scanning...' : 'Idle'}',
                            style: TextStyle(
                              color: isScanning ? Colors.orange : Colors.white,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () {
                            if (isScanning) {
                              ref.read(bluetoothServiceProvider).stopScan();
                            } else {
                              ref.read(bluetoothServiceProvider).startScan();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isScanning
                                ? Colors.red.withOpacity(0.2)
                                : Colors.blue.withOpacity(0.2),
                            foregroundColor:
                                isScanning ? Colors.red : Colors.blue,
                          ),
                          child: Text(isScanning ? 'Stop Scan' : 'Start Scan'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              repository.connectToActiveBikes();
                            },
                            icon: const Icon(Icons.bluetooth_connected),
                            label: const Text('Connect All Active'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green.withOpacity(0.2),
                              foregroundColor: Colors.green,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              repository.disconnectAllBikes();
                            },
                            icon: const Icon(Icons.bluetooth_disabled),
                            label: const Text('Disconnect All'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red.withOpacity(0.2),
                              foregroundColor: Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Log Section
              _buildSectionHeader('Logs (${_logs.length})'),
              Container(
                height: 300,
                width: double.infinity,
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[800]!),
                ),
                child: ListView.builder(
                  itemCount: _logs.length,
                  reverse: true,
                  itemBuilder: (context, index) {
                    final logEntry = _logs[_logs.length - 1 - index];
                    Color textColor = Colors.grey;
                    if (logEntry.contains('[WARNING]') || logEntry.contains('[W]')) {
                      textColor = Colors.orange;
                    } else if (logEntry.contains('[ERROR]') || logEntry.contains('[E]')) {
                      textColor = Colors.red;
                    } else if (logEntry.contains('[INFO]') || logEntry.contains('[I]')) {
                      textColor = Colors.green;
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4.0),
                      child: Text(
                        logEntry,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<String> items) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: items
            .map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4.0),
                  child: Text(
                    item,
                    style: const TextStyle(color: Colors.white),
                  ),
                ))
            .toList(),
      ),
    );
  }
}
