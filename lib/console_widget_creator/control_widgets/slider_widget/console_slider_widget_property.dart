import 'dart:async';

import 'package:flutter/material.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../../util/form/double_field.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';

/// Parameter of the console widget.
class ConsoleSliderWidgetProperty extends TypedConsoleWidgetProperty {
  /// The identifier of the channel to broadcast the output value.
  final String? channel;

  final String? color;

  /// The min value of the output.
  final double minValue;

  /// The max value of the output.
  final double maxValue;

  /// The initial value of the output.
  final double initialValue;

  /// The width of the value range.
  double get valueWidth => maxValue - minValue;

  /// Creates the parameter.
  ConsoleSliderWidgetProperty({
    this.channel,
    String? color,
    this.minValue = 0,
    this.maxValue = 255,
    double? initialValue,
  }) : initialValue = initialValue ?? minValue,
        color = color ?? defaultColorHex;

  /// Creates the parameter from an [prop].
  factory ConsoleSliderWidgetProperty.fromUntyped(ConsoleWidgetProperty prop) {
    return ConsoleSliderWidgetProperty(
      channel: selectAttributeAs(prop, "channel", null),
      color: selectAttributeAs(prop, "color", defaultColorHex),
      minValue: selectAttributeAs(prop, "minValue", 0),
      maxValue: selectAttributeAs(prop, "maxValue", 255),
      initialValue: selectAttributeAs(prop, "initialValue", null),
    );
  }

  /// Creates the property of itself.
  @override
  ConsoleWidgetProperty toUntyped() {
    return {
      "channel": channel,
      "color": color,
      "minValue": minValue,
      "maxValue": maxValue,
      "initialValue": initialValue,
    };
  }

  @override
  String? validate() {
    if (maxValue <= minValue) {
      return "Max value must be greater than min value.";
    }
    if (initialValue < minValue || maxValue < initialValue) {
      return "Initial value must be between min and max.";
    }

    return null;
  }

  static Future<ConsoleSliderWidgetProperty?> edit(BuildContext context,
      {ConsoleSliderWidgetProperty? oldProperty}) {
    final propCompleter = Completer<ConsoleSliderWidgetProperty?>();
    final initial = oldProperty ?? ConsoleSliderWidgetProperty();

    // Attributes of the parameter for editing.
    String? newChannel = initial.channel;
    String? newColor = initial.color;
    double newMinValue = initial.minValue;
    double newMaxValue = initial.maxValue;
    double? newInitialValue =
    initial.initialValue == newMinValue ? null : initial.initialValue;

    if (newColor != null && newColor != defaultColorHex) {
      lastColor = newColor;
    }

    // Show a form to edit above parameters.
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CommonFormPage(
          title: "Property Edit",
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(""),
              Text("Output Channel",
                  style: Theme.of(context).textTheme.headlineMedium),
              ChannelSelector(
                  initialValue: newChannel,
                  onChanged: (value) => newChannel = value),
              const Text(""),
              Text("Output Value",
                  style: Theme.of(context).textTheme.headlineMedium),
              DoubleInputField(
                  labelText: "Min Value",
                  initValue: newMinValue,
                  nullable: false,
                  onValueChange: (value) => newMinValue = value!,
                  valueValidator: (value) {
                    if (value! >= newMaxValue) {
                      return "Min value must be less than max.";
                    }
                    return null;
                  }),
              DoubleInputField(
                  labelText: "Max Value",
                  initValue: newMaxValue,
                  nullable: false,
                  onValueChange: (value) => newMaxValue = value!,
                  valueValidator: (value) {
                    if (value! <= newMinValue) {
                      return "Max value must be greater than min.";
                    }
                    return null;
                  }),
              DoubleInputField(
                  labelText: "Initial Value",
                  initValue: newInitialValue,
                  onValueChange: (value) => newInitialValue = value,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }

                    if (value < newMinValue || value > newMaxValue) {
                      return "Initial value must be between min and max.";
                    }
                    return null;
                  }),
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
      // Return the edited property with the validation.
      if (ok) {

        if (isAddingConsole) {
          lastColor = newColor ?? defaultColorHex;
        } else {
          lastColor = defaultColorHex;
        }

        propCompleter.complete(ConsoleSliderWidgetProperty(
          channel: newChannel,
          color: newColor,
          minValue: newMinValue,
          maxValue: newMaxValue,
          initialValue: newInitialValue,
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
