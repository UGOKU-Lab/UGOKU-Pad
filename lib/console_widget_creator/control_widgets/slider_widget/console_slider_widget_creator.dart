import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ugoku_console/bluetooth/constants.dart';

import 'package:ugoku_console/util/AppLocale.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_slider_widget.dart';
import 'console_slider_widget_property.dart';

/// The creator of volume slider.
final consoleSliderWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleSliderWidgetProperty.fromUntyped,
  name: "Slider",
  localizedNameKey: AppLocale.widget_name_slider,
  description: "Controls a value by vertical swipes.",
  localizedDescriptionKey: AppLocale.widget_desc_slider,
  series: "Control Widgets",
  localizedSeriesKey: AppLocale.widget_series_control,
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleSliderWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  propertyCreator: ConsoleSliderWidgetProperty.edit,
  previewBuilder: (context, property) => ConsoleSliderWidget(
    property: property,
  ),
  sampleProperty:
  ConsoleSliderWidgetProperty(color: defaultColorHex, minValue: 0, maxValue: 255, initialValue: 64),
);
