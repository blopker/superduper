// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'saved_bike.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_SavedBike _$$_SavedBikeFromJson(Map<String, dynamic> json) => _$_SavedBike(
      id: json['id'] as String,
      selected: json['selected'] as bool? ?? false,
      name: json['name'] as String?,
    );

Map<String, dynamic> _$$_SavedBikeToJson(_$_SavedBike instance) =>
    <String, dynamic>{
      'id': instance.id,
      'selected': instance.selected,
      'name': instance.name,
    };

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// ignore_for_file: avoid_private_typedef_functions, non_constant_identifier_names, subtype_of_sealed_class, invalid_use_of_internal_member, unused_element, constant_identifier_names, unnecessary_raw_strings, library_private_types_in_public_api

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

String _$SavedBikeListHash() => r'08c5c6512cfe5c590645f354754472d55fd0baf2';

/// See also [SavedBikeList].
final savedBikeListProvider =
    AutoDisposeNotifierProvider<SavedBikeList, List<SavedBike>>(
  SavedBikeList.new,
  name: r'savedBikeListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$SavedBikeListHash,
);
typedef SavedBikeListRef = AutoDisposeNotifierProviderRef<List<SavedBike>>;

abstract class _$SavedBikeList extends AutoDisposeNotifier<List<SavedBike>> {
  @override
  List<SavedBike> build();
}
