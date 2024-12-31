import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_joystick_widget.dart';
import 'console_joystick_widget_property.dart';

/// The creator of a joystick.
final consoleJoystickWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleJoystickWidgetProperty.fromUntyped,
  name: "Joystick",
  description: "Controls 2D values like a joystick.",
  series: "Control Widgets",
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleJoystickWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleJoystickWidget(
    property: property,
  ),
  propertyCreator: ConsoleJoystickWidgetProperty.edit,
);
