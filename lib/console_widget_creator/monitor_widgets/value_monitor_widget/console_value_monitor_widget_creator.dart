import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ugoku_console/util/AppLocale.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_value_monitor_widget.dart';
import 'console_value_monitor_widget_property.dart';

/// Creates the adjuster that adjusts a value with a slider and increments/
/// decremental buttons.
final consoleValueMonitorWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleValueMonitorProperty.fromUntyped,
  name: "Value Monitor",
  localizedNameKey: AppLocale.widget_name_value_monitor,
  description: "Displays a value.",
  localizedDescriptionKey: AppLocale.widget_desc_value_monitor,
  series: "Monitor Widgets",
  localizedSeriesKey: AppLocale.widget_series_monitor,
  propertyCreator: ConsoleValueMonitorProperty.create,
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleValueMonitorWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleValueMonitorWidget(
    property: property,
    initialValue: 0,
  ),
  sampleBuilder: (context) => ConsoleValueMonitorWidget(
    property: ConsoleValueMonitorProperty(),
    initialValue: 64,
  ),
);
