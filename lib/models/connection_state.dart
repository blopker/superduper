/// Represents the possible connection states for a bike.
///
/// Used to track and manage bike connection lifecycle.
enum BikeConnectionState {
  /// The bike is not connected.
  disconnected,
  
  /// The bike is connected and communication is possible.
  connected,
  
  /// The bike is in the process of establishing a connection.
  connecting,
  
  /// The bike is in the process of disconnecting.
  disconnecting
}