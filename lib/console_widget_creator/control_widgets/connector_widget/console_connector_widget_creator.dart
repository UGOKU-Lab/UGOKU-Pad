import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ugoku_console/util/AppLocale.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_connector_widget.dart';
import 'console_connector_widget_property.dart';

/// The creator of a joystick.
final consoleConnectorWidgetCreator =
TypedConsoleWidgetCreator<ConsoleConnectorWidgetProperty>(
  ConsoleConnectorWidgetProperty.fromUntyped,
  name: "Connector",
  localizedNameKey: AppLocale.widget_name_connector,
  description: "Passes values from source to destination channel.",
  localizedDescriptionKey: AppLocale.widget_desc_connector,
  series: "Control Widgets",
  localizedSeriesKey: AppLocale.widget_series_control,
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
