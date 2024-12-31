import 'package:flutter/material.dart';
import 'package:ugoku_console/bluetooth/constants.dart';

/// Creates a frame that show the state of the activation.
///
/// This provides a visual feedback for console widgets.
class ConsoleWidgetCard extends StatelessWidget {
  final bool activate;
  final Widget child;
  final String? color;

  const ConsoleWidgetCard({
    super.key,
    this.activate = false,
    required this.child,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 0 /*100*/),
      margin: EdgeInsets.all(activate ? 0 : 5),
      padding: EdgeInsets.all(activate ? 5 : 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.all(Radius.circular(activate ? 17 : 13)),
        color: activate
            ? (color != null ? hexToColor(color) : hexToColor(defaultColorHex))
            : Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey // Darker shadow for dark mode
                : Colors.black12, // Lighter shadow for light mode
            spreadRadius: 0,
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.grey
                : Colors.black12,
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Container(
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(13)),
        ),
        clipBehavior: Clip.antiAlias,
        child: child,
      ),
    );
  }
}

