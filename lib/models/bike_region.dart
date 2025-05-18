import 'package:freezed_annotation/freezed_annotation.dart';

/// Represents different regions with different bike regulations
enum BikeRegion {
  // R,RX
  @JsonValue(200)
  us('US'),
  // S2
  @JsonValue(201)
  eu('EU');

  const BikeRegion(this.value);
  final String value;
}