// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'db.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SettingsModel _$SettingsModelFromJson(Map<String, dynamic> json) =>
    _SettingsModel(currentBike: json['currentBike'] as String?);

Map<String, dynamic> _$SettingsModelToJson(_SettingsModel instance) =>
    <String, dynamic>{'currentBike': instance.currentBike};

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(BikesDB)
const bikesDBProvider = BikesDBProvider._();

final class BikesDBProvider
    extends $NotifierProvider<BikesDB, List<BikeState>> {
  const BikesDBProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'bikesDBProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$bikesDBHash();

  @$internal
  @override
  BikesDB create() => BikesDB();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(List<BikeState> value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<List<BikeState>>(value),
    );
  }
}

String _$bikesDBHash() => r'68d0f459b163bb1f35c5e2ae819318d5f26c786d';

abstract class _$BikesDB extends $Notifier<List<BikeState>> {
  List<BikeState> build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<List<BikeState>, List<BikeState>>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<List<BikeState>, List<BikeState>>,
              List<BikeState>,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}

@ProviderFor(SettingsDB)
const settingsDBProvider = SettingsDBProvider._();

final class SettingsDBProvider
    extends $NotifierProvider<SettingsDB, SettingsModel> {
  const SettingsDBProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'settingsDBProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$settingsDBHash();

  @$internal
  @override
  SettingsDB create() => SettingsDB();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(SettingsModel value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<SettingsModel>(value),
    );
  }
}

String _$settingsDBHash() => r'edad9433dc33333134820de0bd0ed8d2c60b67d2';

abstract class _$SettingsDB extends $Notifier<SettingsModel> {
  SettingsModel build();
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build();
    final ref = this.ref as $Ref<SettingsModel, SettingsModel>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<SettingsModel, SettingsModel>,
              SettingsModel,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
