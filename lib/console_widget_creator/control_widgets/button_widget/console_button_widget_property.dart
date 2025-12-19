import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../../util/form/double_field.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';
import 'package:ugoku_console/util/AppLocale.dart';

/// Parameter of the console widget.
class ConsoleButtonWidgetProperty extends TypedConsoleWidgetProperty {
  final String? channel;
  final String? color;
  final String buttonText;
  final double initialValue;
  final double tappedValue;

  /// Creates the parameter.
  ConsoleButtonWidgetProperty(
      {
        this.channel,
        String? color,
        String? buttonText,
        double? initialValue,
        double? tappedValue
      })
      : buttonText = buttonText ?? "Button",
        initialValue = initialValue ?? 0,
        color = color ?? defaultColorHex,
        tappedValue = tappedValue ?? 1;

  /// Creates the parameter from an [prop].
  ConsoleButtonWidgetProperty.fromUntyped(ConsoleWidgetProperty prop)
      : channel = selectAttributeAs(prop, "channel", null),
        color = selectAttributeAs(prop, "color", defaultColorHex),
        buttonText = selectAttributeAs(prop, "buttonText", "Button"),
        initialValue = selectAttributeAs(prop, "initialValue", 0),
        tappedValue = selectAttributeAs(prop, "tappedValue", 1);

  /// Creates the property of itself.
  @override
  ConsoleWidgetProperty toUntyped() {
    return {
      "channel": channel,
      "color": color,
      "buttonText": buttonText,
      "initialValue": initialValue,
      "tappedValue": tappedValue,
    };
  }

  @override
  String? validate(BuildContext context) {
    if ((initialValue) == (tappedValue)) {
      return AppLocale.validator_values_must_differ.getString(context);
    }

    return null;
  }

  static Future<ConsoleButtonWidgetProperty?> edit(BuildContext context,
      {ConsoleButtonWidgetProperty? oldProperty}) {
    final propCompleter = Completer<ConsoleButtonWidgetProperty?>();
    final initial = oldProperty ?? ConsoleButtonWidgetProperty();

    // Attributes of the property for editing.
    String? newChannel = initial.channel;
    String? newColor = initial.color;
    String newButtonText = initial.buttonText;
    double newInitialValue = initial.initialValue;
    double newTappedValue = initial.tappedValue;

    if (newColor != null && newColor != defaultColorHex) {
      lastColor = newColor;
    }

    // Show a form to edit above parameters.
    Navigator.of(context)
        .push(
      MaterialPageRoute(
        builder: (context) => CommonFormPage(
          title: AppLocale.property_edit.getString(context),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            const SizedBox(height: 12),
            Text(AppLocale.output_channel.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              ChannelSelector(
                  initialValue: newChannel,
                  onChanged: (value) => newChannel = value),
            const SizedBox(height: 12),
            Text(AppLocale.button_section.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              TextFormField(
                  initialValue: newButtonText,
              decoration: InputDecoration(
                labelText: AppLocale.button_text.getString(context)),
                  onChanged: (value) => newButtonText = value),
            const SizedBox(height: 12),
            Text(AppLocale.output_value.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              DoubleInputField(
              context: context,
              labelText: AppLocale.initial_value.getString(context),
                  initValue: newInitialValue,
                  nullable: false,
                  onValueChange: (value) => newInitialValue = value!,
                  valueValidator: (value) => null),
              DoubleInputField(
              context: context,
              labelText: AppLocale.tapped_value.getString(context),
                  initValue: newTappedValue,
                  nullable: false,
                  onValueChange: (value) => newTappedValue = value!,
                  valueValidator: (value) {
                    if (value! == newInitialValue) {
                return AppLocale.validator_values_must_differ;
                    }
                    return null;
                  }),
            const SizedBox(height: 12),
            Text(AppLocale.color.getString(context),
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

        propCompleter.complete(ConsoleButtonWidgetProperty(
          channel: newChannel,
          color: newColor,
          buttonText: newButtonText,
          initialValue: newInitialValue.toDouble(),
          tappedValue: newTappedValue.toDouble(),
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
