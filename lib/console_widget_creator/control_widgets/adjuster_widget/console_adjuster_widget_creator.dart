import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../broadcaster_provider.dart';
import '../../typed_console_widget_creator.dart';
import 'console_adjuster_widget.dart';
import 'console_adjuster_widget_property.dart';

/// Creates the adjuster that adjusts a value with a slider and increments/
/// decremental buttons.
final consoleAdjusterWidgetCreator = TypedConsoleWidgetCreator(
  ConsoleAdjusterWidgetProperty.fromUntyped,
  name: "Adjuster",
  description: "Adjusts a value with a slider and increment/decrement buttons.",
  series: "Control Widgets",
  propertyCreator: ConsoleAdjusterWidgetProperty.create,
  builder: (context, property) => Consumer(
    builder: (context, ref, _) => ConsoleAdjusterWidget(
      property: property,
      broadcaster: ref.watch(broadcasterProvider),
    ),
  ),
  previewBuilder: (context, property) => ConsoleAdjusterWidget(
    property: property,
  ),
  sampleProperty: ConsoleAdjusterWidgetProperty(initialValue: 64),
);
