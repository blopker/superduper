// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'migration.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$migrationUtilHash() => r'e9f1c7792e08929b5c1507b76f75d476ab3a1a7b';

/// Provider for the migration utility.
///
/// Copied from [migrationUtil].
@ProviderFor(migrationUtil)
final migrationUtilProvider = AutoDisposeProvider<MigrationUtil>.internal(
  migrationUtil,
  name: r'migrationUtilProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$migrationUtilHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef MigrationUtilRef = AutoDisposeProviderRef<MigrationUtil>;
String _$runMigrationHash() => r'd1d190667d8f44458ea9ab8ef469ea2fd99664ca';

/// Provider that runs the migration if needed.
///
/// Copied from [runMigration].
@ProviderFor(runMigration)
final runMigrationProvider = FutureProvider<void>.internal(
  runMigration,
  name: r'runMigrationProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$runMigrationHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RunMigrationRef = FutureProviderRef<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
