import 'package:flutter/material.dart';

class LongPressEmergencyButton extends StatefulWidget {
  final VoidCallback onTriggered;

  const LongPressEmergencyButton({
    super.key,
    required this.onTriggered,
  });

  @override
  State<LongPressEmergencyButton> createState() =>
      _LongPressEmergencyButtonState();
}

class _LongPressEmergencyButtonState
    extends State<LongPressEmergencyButton> {
  bool _triggered = false;

  void _handleLongPress() {
    if (_triggered) return;

    setState(() => _triggered = true);
    widget.onTriggered();

    // reset after a short delay to avoid double fire
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _triggered = false);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: _handleLongPress,
      child: FloatingActionButton(
        backgroundColor: _triggered ? Colors.grey : Colors.red,
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hold button to trigger emergency'),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: const Icon(Icons.warning),
      ),
    );
  }
}
