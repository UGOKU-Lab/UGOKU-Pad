import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ugoku_console/util/AppLocale.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_line_chart_widget.dart';
import 'console_line_chart_widget_property.dart';

/// Creates the adjuster that adjusts a value with a slider and increments/
/// decremental buttons.
final consoleLineChartWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleLineChartWidgetProperty.fromUntyped,
  name: "Line Chart",
  localizedNameKey: AppLocale.widget_name_line_chart,
  description: "Displays a line chart.",
  localizedDescriptionKey: AppLocale.widget_desc_line_chart,
  series: "Monitor Widgets",
  localizedSeriesKey: AppLocale.widget_series_monitor,
  propertyCreator: ConsoleLineChartWidgetProperty.create,
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleLineChartWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleLineChartWidget(
    property: property,
    initialValues: List.filled(property.samples, 0.5),
    start: false,
  ),
  sampleBuilder: (context) => ConsoleLineChartWidget(
    property: ConsoleLineChartWidgetProperty(),
    initialValues: const [0.4, 0.6, 0.5, 0.6],
    start: false,
  ),
);
