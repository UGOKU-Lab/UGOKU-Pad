import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_connector_widget.dart';
import 'console_connector_widget_property.dart';

/// The creator of a joystick.
final consoleConnectorWidgetCreator =
TypedConsoleWidgetCreator<ConsoleConnectorWidgetProperty>(
  ConsoleConnectorWidgetProperty.fromUntyped,
  name: "Connector",
  description: "Passes values from source to destination channel.",
  series: "Control Widgets",
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleConnectorWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleConnectorWidget(
    property: property,
  ),
  propertyCreator: ConsoleConnectorWidgetProperty.edit,
);
