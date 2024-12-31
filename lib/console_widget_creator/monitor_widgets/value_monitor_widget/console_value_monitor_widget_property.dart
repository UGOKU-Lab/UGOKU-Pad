import 'dart:async';

import 'package:flutter/material.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../../util/form/integer_field.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';

/// The property of the console widget.
class ConsoleValueMonitorProperty implements TypedConsoleWidgetProperty {
  /// The identifier of the channel to broadcast the control value.
  final String? channel;

  final String? color;

  final int displayFractionDigits;

  /// Creates a property.
  ConsoleValueMonitorProperty({
    this.channel,
    String? color,
    this.displayFractionDigits = 0,
  }) : color = color ?? defaultColorHex;

  /// Creates a property from the untyped [property].
  ConsoleValueMonitorProperty.fromUntyped(ConsoleWidgetProperty property)
      : channel = selectAttributeAs(property, "channel", null),
        color = selectAttributeAs(property, "color", defaultColorHex),
        displayFractionDigits =
        selectAttributeAs(property, "displayFractionDigits", 0);

  @override
  ConsoleWidgetProperty toUntyped() => {
    "channel": channel,
    "color": color,
    "displayFractionDigits": displayFractionDigits,
  };

  @override
  String? validate() {
    if (displayFractionDigits < 0 || displayFractionDigits > 20) {
      return "Display precision must be in the range 0-20.";
    }

    return null;
  }

  /// Edits interactively to create new property.
  static Future<ConsoleValueMonitorProperty?> create(
      BuildContext context, {
        ConsoleValueMonitorProperty? oldProperty,
      }) {
    final propCompleter = Completer<ConsoleValueMonitorProperty?>();
    final initial = oldProperty ?? ConsoleValueMonitorProperty();

    // Attributes of the property for editing.
    String? newChannel = initial.channel;
    String? newColor = initial.color;
    int newDisplayPrecision = initial.displayFractionDigits;

    if (newColor != null && newColor != defaultColorHex) {
      lastColor = newColor;
    }

    // Show a form to edit above attributes.
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CommonFormPage(
          title: "Property Edit",
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(""),
              Text("Input Channel",
                  style: Theme.of(context).textTheme.headlineMedium),
              ChannelSelector(
                  initialValue: newChannel,
                  onChanged: (value) => newChannel = value),
              const Text(""),
              Text("Display",
                  style: Theme.of(context).textTheme.headlineMedium),
              IntInputField(
                labelText: "Fraction digits",
                initValue: newDisplayPrecision,
                // Max and min are limited by [double.toStringAsFixed].
                minValue: 0,
                maxValue: 20,
                nullable: false,
                onValueChange: (value) => newDisplayPrecision = value!,
              ),
              const Text(""),
              Text("Color",
                  style: Theme.of(context).textTheme.headlineMedium),
              ColorSelector(
                  initialValue: lastColor,
                  onChanged: (value) => newColor = value
              )
            ],
          ),
        ),
      ),
    )
        .then((ok) {
      if (ok) {

        if (isAddingConsole) {
          lastColor = newColor ?? defaultColorHex;
        } else {
          lastColor = defaultColorHex;
        }

        propCompleter.complete(ConsoleValueMonitorProperty(
          channel: newChannel,
          color: newColor,
          displayFractionDigits: newDisplayPrecision,
        ));
      } else {
        propCompleter.complete(oldProperty);
      }
    });

    Future.delayed(Duration(milliseconds: 100), () {

      if (newColor == defaultColorHex) {
        newColor = lastColor;
      }

    });

    return propCompleter.future;
  }
}
