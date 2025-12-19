import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:ugoku_console/util/AppLocale.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_button_widget.dart';
import 'console_button_widget_property.dart';

/// The creator of a toggle switch.
final consoleButtonWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleButtonWidgetProperty.fromUntyped,
  name: "Button",
  localizedNameKey: AppLocale.widget_name_button,
  description: "Performs an action when tapped.",
  localizedDescriptionKey: AppLocale.widget_desc_button,
  series: "Control Widgets",
  localizedSeriesKey: AppLocale.widget_series_control,
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleButtonWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleButtonWidget(
    property: property,
  ),
  propertyCreator: ConsoleButtonWidgetProperty.edit,
);
