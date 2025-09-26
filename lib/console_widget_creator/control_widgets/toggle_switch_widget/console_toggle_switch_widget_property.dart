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
class ConsoleToggleSwitchWidgetProperty extends TypedConsoleWidgetProperty {
  final String? channel;
  final String? color;
  final double initialValue;
  final double reversedValue;

  /// Creates the parameter.
  ConsoleToggleSwitchWidgetProperty(
      {this.channel, String? color, double? initialValue, double? reversedValue})
      : initialValue = initialValue ?? 0,
        color = color ?? defaultColorHex,
        reversedValue = reversedValue ?? 1;

  /// Creates the parameter from an [prop].
  ConsoleToggleSwitchWidgetProperty.fromUntyped(ConsoleWidgetProperty prop)
      : channel = selectAttributeAs(prop, "channel", null),
        color = selectAttributeAs(prop, "color", defaultColorHex),
        initialValue = selectAttributeAs(prop, "initialValue", 0),
        reversedValue = selectAttributeAs(prop, "reversedValue", 1);

  /// Creates the property of itself.
  @override
  ConsoleWidgetProperty toUntyped() {
    return {
      "channel": channel,
      "color": color,
      "initialValue": initialValue,
      "reversedValue": reversedValue,
    };
  }

  @override
  String? validate() {
    if ((initialValue) == (reversedValue)) {
      return "Reversed value must not equal initial value.";
    }

    return null;
  }

  static Future<ConsoleToggleSwitchWidgetProperty?> edit(BuildContext context,
      {ConsoleToggleSwitchWidgetProperty? oldProperty}) {
    final propCompleter = Completer<ConsoleToggleSwitchWidgetProperty?>();
    final initial = oldProperty ?? ConsoleToggleSwitchWidgetProperty();

    // Attributes of the property for editing.
    String? newChannel = initial.channel;
    String? newColor = initial.color;
    double newInitialValue = initial.initialValue;
    double newReversedValue = initial.reversedValue;

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
                  labelText: "Initial Value",
                  initValue: newInitialValue,
                  nullable: false,
                  onValueChange: (value) => newInitialValue = value!,
                  valueValidator: (value) => null),
              DoubleInputField(
                  labelText: "Reversed Value",
                  initValue: newReversedValue,
                  nullable: false,
                  onValueChange: (value) => newReversedValue = value!,
                  valueValidator: (value) {
                    if (value! == newInitialValue) {
                      return "Reversed value must not equal initial.";
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
      if (ok) {

        if (isAddingConsole) {
          lastColor = newColor ?? defaultColorHex;
        } else {
          lastColor = defaultColorHex;
        }

        propCompleter.complete(ConsoleToggleSwitchWidgetProperty(
          channel: newChannel,
          color: newColor,
          initialValue: newInitialValue.toDouble(),
          reversedValue: newReversedValue.toDouble(),
        ));
      } else {
        propCompleter.complete(oldProperty);
      }
    });

    Future.delayed(const Duration(milliseconds: 100), () {

      if (newColor == defaultColorHex) {
        newColor = lastColor;
      }

    });

    return propCompleter.future;
  }
}
