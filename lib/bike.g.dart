// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bike.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(Bike)
const bikeProvider = BikeFamily._();

final class BikeProvider extends $NotifierProvider<Bike, BikeState> {
  const BikeProvider._({
    required BikeFamily super.from,
    required String super.argument,
  }) : super(
         retry: null,
         name: r'bikeProvider',
         isAutoDispose: true,
         dependencies: null,
         $allTransitiveDependencies: null,
       );

  @override
  String debugGetCreateSourceHash() => _$bikeHash();

  @override
  String toString() {
    return r'bikeProvider'
        ''
        '($argument)';
  }

  @$internal
  @override
  Bike create() => Bike();

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(BikeState value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<BikeState>(value),
    );
  }

  @override
  bool operator ==(Object other) {
    return other is BikeProvider && other.argument == argument;
  }

  @override
  int get hashCode {
    return argument.hashCode;
  }
}

String _$bikeHash() => r'66df00f1c2391df26bc6f2fb51655bd9f4d49fd8';

final class BikeFamily extends $Family
    with $ClassFamilyOverride<Bike, BikeState, BikeState, BikeState, String> {
  const BikeFamily._()
    : super(
        retry: null,
        name: r'bikeProvider',
        dependencies: null,
        $allTransitiveDependencies: null,
        isAutoDispose: true,
      );

  BikeProvider call(String id) => BikeProvider._(argument: id, from: this);

  @override
  String toString() => r'bikeProvider';
}

abstract class _$Bike extends $Notifier<BikeState> {
  late final _$args = ref.$arg as String;
  String get id => _$args;

  BikeState build(String id);
  @$mustCallSuper
  @override
  void runBuild() {
    final created = build(_$args);
    final ref = this.ref as $Ref<BikeState, BikeState>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<BikeState, BikeState>,
              BikeState,
              Object?,
              Object?
            >;
    element.handleValue(ref, created);
  }
}
