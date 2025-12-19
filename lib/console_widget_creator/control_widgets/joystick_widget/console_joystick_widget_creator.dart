import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ugoku_console/util/AppLocale.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_joystick_widget.dart';
import 'console_joystick_widget_property.dart';

/// The creator of a joystick.
final consoleJoystickWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleJoystickWidgetProperty.fromUntyped,
  name: "Joystick",
  localizedNameKey: AppLocale.widget_name_joystick,
  description: "Controls 2D values like a joystick.",
  localizedDescriptionKey: AppLocale.widget_desc_joystick,
  series: "Control Widgets",
  localizedSeriesKey: AppLocale.widget_series_control,
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
