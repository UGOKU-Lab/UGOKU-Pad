import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../../util/form/integer_field.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';
import 'package:ugoku_console/util/AppLocale.dart';

/// Parameter of the console widget.
class ConsoleToggleSwitchWidgetProperty extends TypedConsoleWidgetProperty {
  final String? channel;
  final String? color;
  final String labelText;
  final double initialValue;
  final double reversedValue;

  /// Creates the parameter.
  ConsoleToggleSwitchWidgetProperty(
      {this.channel,
      String? color,
      String? labelText,
      double? initialValue,
      double? reversedValue})
      : labelText = labelText ?? "",
        initialValue = initialValue ?? 0,
        color = color ?? defaultColorHex,
        reversedValue = reversedValue ?? 1;

  /// Creates the parameter from an [prop].
  ConsoleToggleSwitchWidgetProperty.fromUntyped(ConsoleWidgetProperty prop)
      : channel = selectAttributeAs(prop, "channel", null),
        color = selectAttributeAs(prop, "color", defaultColorHex),
        labelText = selectAttributeAs(prop, "labelText", ""),
        initialValue = selectAttributeAs(prop, "initialValue", 0),
        reversedValue = selectAttributeAs(prop, "reversedValue", 1);

  /// Creates the property of itself.
  @override
  ConsoleWidgetProperty toUntyped() {
    return {
      "channel": channel,
      "color": color,
      "labelText": labelText,
      "initialValue": initialValue,
      "reversedValue": reversedValue,
    };
  }

  @override
  String? validate(BuildContext context) {
    if ((initialValue) == (reversedValue)) {
      return AppLocale.validator_values_must_differ.getString(context);
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
    String newLabelText = initial.labelText;
    int newInitialValue = initial.initialValue.toInt();
    int newReversedValue = initial.reversedValue.toInt();

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
              Text(AppLocale.output_value.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              IntInputField(
                  context: context,
                  labelText: AppLocale.initial_value.getString(context),
                  initValue: newInitialValue,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newInitialValue = value!,
                  valueValidator: (value) => null),
              IntInputField(
                  context: context,
                  labelText: AppLocale.reversed_value.getString(context),
                  initValue: newReversedValue,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newReversedValue = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value == newInitialValue) {
                      return AppLocale.validator_values_must_differ
                          .getString(context);
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              Text(AppLocale.display_section.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              TextFormField(
                  initialValue: newLabelText,
                  decoration: InputDecoration(
                      labelText: AppLocale.title_field.getString(context)),
                  onChanged: (value) => newLabelText = value),
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

        propCompleter.complete(ConsoleToggleSwitchWidgetProperty(
          channel: newChannel,
          color: newColor,
          labelText: newLabelText,
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
