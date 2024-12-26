// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adapterStateHash() => r'b2664eace33ac0f397ed4d82636ba521673d9099';

/// See also [adapterState].
@ProviderFor(adapterState)
final adapterStateProvider =
    AutoDisposeStreamProvider<BluetoothAdapterState>.internal(
  adapterState,
  name: r'adapterStateProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$adapterStateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdapterStateRef = AutoDisposeStreamProviderRef<BluetoothAdapterState>;
String _$isScanningStatusHash() => r'dfe37cf6ae13ad7180be16e508b6b6ae1eca4283';

/// See also [isScanningStatus].
@ProviderFor(isScanningStatus)
final isScanningStatusProvider = AutoDisposeStreamProvider<bool>.internal(
  isScanningStatus,
  name: r'isScanningStatusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$isScanningStatusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef IsScanningStatusRef = AutoDisposeStreamProviderRef<bool>;
String _$scanResultsHash() => r'bf071ca0d8662268581c447c2de7b7f4fc56a685';

/// See also [scanResults].
@ProviderFor(scanResults)
final scanResultsProvider =
    AutoDisposeStreamProvider<List<ScanResult>>.internal(
  scanResults,
  name: r'scanResultsProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$scanResultsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ScanResultsRef = AutoDisposeStreamProviderRef<List<ScanResult>>;
String _$connectedDevicesHash() => r'bad504c4de82eb01a975bc4812de5b49623a4720';

/// See also [connectedDevices].
@ProviderFor(connectedDevices)
final connectedDevicesProvider =
    AutoDisposeStreamProvider<List<BluetoothDevice>>.internal(
  connectedDevices,
  name: r'connectedDevicesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$connectedDevicesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConnectedDevicesRef
    = AutoDisposeStreamProviderRef<List<BluetoothDevice>>;
String _$bluetoothRepositoryHash() =>
    r'f232e7f108085d98f2d484a8aa17addf2a62b39f';

/// See also [bluetoothRepository].
@ProviderFor(bluetoothRepository)
final bluetoothRepositoryProvider =
    AutoDisposeProvider<BluetoothRepository>.internal(
  bluetoothRepository,
  name: r'bluetoothRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$bluetoothRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BluetoothRepositoryRef = AutoDisposeProviderRef<BluetoothRepository>;
String _$connectionHandlerHash() => r'5c9ecf453a05b1149aa179c0f06b91ab6d8bdc19';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

abstract class _$ConnectionHandler
    extends BuildlessAutoDisposeNotifier<SDBluetoothConnectionState> {
  late final String deviceId;

  SDBluetoothConnectionState build(
    String deviceId,
  );
}

/// See also [ConnectionHandler].
@ProviderFor(ConnectionHandler)
const connectionHandlerProvider = ConnectionHandlerFamily();

/// See also [ConnectionHandler].
class ConnectionHandlerFamily extends Family<SDBluetoothConnectionState> {
  /// See also [ConnectionHandler].
  const ConnectionHandlerFamily();

  /// See also [ConnectionHandler].
  ConnectionHandlerProvider call(
    String deviceId,
  ) {
    return ConnectionHandlerProvider(
      deviceId,
    );
  }

  @override
  ConnectionHandlerProvider getProviderOverride(
    covariant ConnectionHandlerProvider provider,
  ) {
    return call(
      provider.deviceId,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'connectionHandlerProvider';
}

/// See also [ConnectionHandler].
class ConnectionHandlerProvider extends AutoDisposeNotifierProviderImpl<
    ConnectionHandler, SDBluetoothConnectionState> {
  /// See also [ConnectionHandler].
  ConnectionHandlerProvider(
    String deviceId,
  ) : this._internal(
          () => ConnectionHandler()..deviceId = deviceId,
          from: connectionHandlerProvider,
          name: r'connectionHandlerProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$connectionHandlerHash,
          dependencies: ConnectionHandlerFamily._dependencies,
          allTransitiveDependencies:
              ConnectionHandlerFamily._allTransitiveDependencies,
          deviceId: deviceId,
        );

  ConnectionHandlerProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.deviceId,
  }) : super.internal();

  final String deviceId;

  @override
  SDBluetoothConnectionState runNotifierBuild(
    covariant ConnectionHandler notifier,
  ) {
    return notifier.build(
      deviceId,
    );
  }

  @override
  Override overrideWith(ConnectionHandler Function() create) {
    return ProviderOverride(
      origin: this,
      override: ConnectionHandlerProvider._internal(
        () => create()..deviceId = deviceId,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        deviceId: deviceId,
      ),
    );
  }

  @override
  AutoDisposeNotifierProviderElement<ConnectionHandler,
      SDBluetoothConnectionState> createElement() {
    return _ConnectionHandlerProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionHandlerProvider && other.deviceId == deviceId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, deviceId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConnectionHandlerRef
    on AutoDisposeNotifierProviderRef<SDBluetoothConnectionState> {
  /// The parameter `deviceId` of this provider.
  String get deviceId;
}

class _ConnectionHandlerProviderElement
    extends AutoDisposeNotifierProviderElement<ConnectionHandler,
        SDBluetoothConnectionState> with ConnectionHandlerRef {
  _ConnectionHandlerProviderElement(super.provider);

  @override
  String get deviceId => (origin as ConnectionHandlerProvider).deviceId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
