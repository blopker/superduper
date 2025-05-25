import 'package:flutter/material.dart';

enum BikeConnectionState {
  connected,
  disconnected,
  connecting,
}

class ConnectionStatusChip extends StatelessWidget {
  const ConnectionStatusChip({
    super.key,
    required this.connectionState,
    this.onTap,
  });

  final BikeConnectionState connectionState;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    String text;
    IconData icon;
    Color textColor;
    Color bgColor;
    bool disabled = true;

    switch (connectionState) {
      case BikeConnectionState.connected:
        text = 'Connected';
        icon = Icons.bluetooth_connected;
        textColor = Colors.green;
        bgColor = Colors.green.withAlpha(38); // 0.15 opacity
        disabled = true;
        break;
      case BikeConnectionState.disconnected:
        text = onTap != null ? 'Connect' : 'Disconnected';
        icon = onTap != null ? Icons.bluetooth : Icons.bluetooth_disabled;
        textColor = onTap != null ? const Color(0xff4A80F0) : Colors.grey;
        bgColor = onTap != null 
            ? const Color(0xff4A80F0).withAlpha(38) 
            : Colors.grey.withAlpha(38);
        disabled = onTap == null;
        break;
      case BikeConnectionState.connecting:
        text = 'Connecting...';
        icon = Icons.sync;
        textColor = Colors.grey;
        bgColor = Colors.grey.withAlpha(51); // 0.2 opacity
        disabled = true;
        break;
    }

    Widget child = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: textColor),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.bodySmall!.copyWith(
                  color: textColor,
                  fontWeight: FontWeight.w500,
                ),
          ),
        ],
      ),
    );

    if (!disabled && onTap != null) {
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: child,
      );
    }

    return child;
  }
}