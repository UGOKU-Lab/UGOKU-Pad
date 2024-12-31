import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_toggle_switch_widget.dart';
import 'console_toggle_switch_widget_property.dart';

/// The creator of a toggle switch.
final consoleToggleSwitchWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleToggleSwitchWidgetProperty.fromUntyped,
  name: "Toggle Switch",
  description: "Switches values each time you tap.",
  series: "Control Widgets",
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleToggleSwitchWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleToggleSwitchWidget(
    property: property,
  ),
  propertyCreator: ConsoleToggleSwitchWidgetProperty.edit,
);
