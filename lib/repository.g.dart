// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(adapterState)
const adapterStateProvider = AdapterStateProvider._();

final class AdapterStateProvider
    extends
        $FunctionalProvider<
          AsyncValue<BluetoothAdapterState>,
          BluetoothAdapterState,
          Stream<BluetoothAdapterState>
        >
    with
        $FutureModifier<BluetoothAdapterState>,
        $StreamProvider<BluetoothAdapterState> {
  const AdapterStateProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'adapterStateProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$adapterStateHash();

  @$internal
  @override
  $StreamProviderElement<BluetoothAdapterState> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<BluetoothAdapterState> create(Ref ref) {
    return adapterState(ref);
  }
}

String _$adapterStateHash() => r'b2664eace33ac0f397ed4d82636ba521673d9099';

@ProviderFor(isScanningStatus)
const isScanningStatusProvider = IsScanningStatusProvider._();

final class IsScanningStatusProvider
    extends $FunctionalProvider<AsyncValue<bool>, bool, Stream<bool>>
    with $FutureModifier<bool>, $StreamProvider<bool> {
  const IsScanningStatusProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'isScanningStatusProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$isScanningStatusHash();

  @$internal
  @override
  $StreamProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $StreamProviderElement(pointer);

  @override
  Stream<bool> create(Ref ref) {
    return isScanningStatus(ref);
  }
}

String _$isScanningStatusHash() => r'dfe37cf6ae13ad7180be16e508b6b6ae1eca4283';

@ProviderFor(scanResults)
const scanResultsProvider = ScanResultsProvider._();

final class ScanResultsProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<ScanResult>>,
          List<ScanResult>,
          Stream<List<ScanResult>>
        >
    with $FutureModifier<List<ScanResult>>, $StreamProvider<List<ScanResult>> {
  const ScanResultsProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'scanResultsProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$scanResultsHash();

  @$internal
  @override
  $StreamProviderElement<List<ScanResult>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<ScanResult>> create(Ref ref) {
    return scanResults(ref);
  }
}

String _$scanResultsHash() => r'bf071ca0d8662268581c447c2de7b7f4fc56a685';

@ProviderFor(connectedDevices)
const connectedDevicesProvider = ConnectedDevicesProvider._();

final class ConnectedDevicesProvider
    extends
        $FunctionalProvider<
          AsyncValue<List<BluetoothDevice>>,
          List<BluetoothDevice>,
          Stream<List<BluetoothDevice>>
        >
    with
        $FutureModifier<List<BluetoothDevice>>,
        $StreamProvider<List<BluetoothDevice>> {
  const ConnectedDevicesProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'connectedDevicesProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$connectedDevicesHash();

  @$internal
  @override
  $StreamProviderElement<List<BluetoothDevice>> $createElement(
    $ProviderPointer pointer,
  ) => $StreamProviderElement(pointer);

  @override
  Stream<List<BluetoothDevice>> create(Ref ref) {
    return connectedDevices(ref);
  }
}

String _$connectedDevicesHash() => r'bad504c4de82eb01a975bc4812de5b49623a4720';

@ProviderFor(ConnectionHandler)
const connectionHandlerProvider = ConnectionHandlerFamily._();

final class ConnectionHandlerProvider
    extends $NotifierProvider<ConnectionHandler, SDBluetoothConnectionState> {
  const ConnectionHandlerProvider._({
    required ConnectionHandlerFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'connectionHandlerProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$connectionHandlerHash();

  @override
  String toString() {
    return r'connectionHandlerProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  ConnectionHandler create() => ConnectionHandler();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SDBluetoothConnectionState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SDBluetoothConnectionState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ConnectionHandlerProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$connectionHandlerHash() => r'261e9cc056c03278f7c5f4d9d72d6604e55d9449';

final class ConnectionHandlerFamily extends $Family
    with
        $ClassFamilyOverride<
          ConnectionHandler,
          SDBluetoothConnectionState,
          SDBluetoothConnectionState,
          SDBluetoothConnectionState,
          String
        > {
  const ConnectionHandlerFamily._()
    : super(
        retry: null,
        name: r'connectionHandlerProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  ConnectionHandlerProvider call(String deviceId) =>
      ConnectionHandlerProvider._(argument: deviceId, from: this);

  @override
  String toString() => r'connectionHandlerProvider';
}

abstract class _$ConnectionHandler
    extends $Notifier<SDBluetoothConnectionState> {
  late final _$args = ref.$arg as String;
  String get deviceId => _$args;

  SDBluetoothConnectionState build(String deviceId);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref =
        this.ref
            as $Ref<SDBluetoothConnectionState, SDBluetoothConnectionState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<
                SDBluetoothConnectionState,
                SDBluetoothConnectionState
              >,
              SDBluetoothConnectionState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(bluetoothRepository)
const bluetoothRepositoryProvider = BluetoothRepositoryProvider._();

final class BluetoothRepositoryProvider
    extends
        $FunctionalProvider<
          BluetoothRepository,
          BluetoothRepository,
          BluetoothRepository
        >
    with $Provider<BluetoothRepository> {
  const BluetoothRepositoryProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bluetoothRepositoryProvider',
        isAutoDispose: true,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bluetoothRepositoryHash();

  @$internal
  @override
  $ProviderElement<BluetoothRepository> $createElement(
    $ProviderPointer pointer,
  ) => $ProviderElement(pointer);

  @override
  BluetoothRepository create(Ref ref) {
    return bluetoothRepository(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BluetoothRepository value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BluetoothRepository>(value),
    );
  }
}

String _$bluetoothRepositoryHash() =>
    r'f232e7f108085d98f2d484a8aa17addf2a62b39f';
