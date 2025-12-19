import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../../util/form/double_field.dart';
import '../../../util/form/integer_field.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';
import 'package:ugoku_console/util/AppLocale.dart';

/// The property of the console widget.
@immutable
class ConsoleAdjusterWidgetProperty implements TypedConsoleWidgetProperty {
  // The identifier of the channel to broadcast the output value.
  final String? channel;

  final String? color;

  /// The min value of the output.
  final double minValue;

  /// The max value of the output.
  final double maxValue;

  /// The initial value of the output.
  final double initialValue;

  /// The number of the divisions between [maxValue] and [minValue].
  final int divisions;

  /// The number of fraction digits to be displayed.
  final int displayFractionDigits;

  /// Creates a property.
  ConsoleAdjusterWidgetProperty({
    this.channel,
    String? color,
    double? initialValue,
    this.minValue = 0,
    this.maxValue = 255,
    int? divisions,
    this.displayFractionDigits = 0,
  })  : initialValue = initialValue ?? minValue,
        color = color ?? defaultColorHex,
        divisions = divisions ?? (maxValue - minValue).floor();

  /// Creates a property from the untyped [property].
  factory ConsoleAdjusterWidgetProperty.fromUntyped(
      ConsoleWidgetProperty property) {
    return ConsoleAdjusterWidgetProperty(
        channel: selectAttributeAs(property, "channel", null),
        color: selectAttributeAs(property, "color", defaultColorHex),
        initialValue: selectAttributeAs(property, "initialValue", null),
        minValue: selectAttributeAs(property, "minValue", 0),
        maxValue: selectAttributeAs(property, "maxValue", 255),
        divisions: selectAttributeAs(property, "divisions", null),
        displayFractionDigits:
        selectAttributeAs(property, "displayFractionDigits", 0));
  }

  @override
  ConsoleWidgetProperty toUntyped() => {
    "channel": channel,
    "color": color,
    "initialValue": initialValue,
    "minValue": minValue,
    "maxValue": maxValue,
    "divisions": divisions,
    "displayFractionDigits": displayFractionDigits,
  };

  @override
  String? validate(BuildContext context) {
    if (maxValue <= minValue) {
      return AppLocale.validator_min_less_than_max.getString(context);
    }
    if (initialValue < minValue || maxValue < initialValue) {
      return AppLocale.validator_between.getString(context);
    }
    if (divisions < 1) {
      return AppLocale.validator_divisions_natural.getString(context);
    }
    if (displayFractionDigits < 0 || displayFractionDigits > 20) {
      return AppLocale.validator_fraction_digits_range.getString(context);
    }

    return null;
  }

  /// Edits interactively to create new property.
  static Future<ConsoleAdjusterWidgetProperty?> create(
      BuildContext context, {
        ConsoleAdjusterWidgetProperty? oldProperty,
      }) {
    final propCompleter = Completer<ConsoleAdjusterWidgetProperty?>();
    final initial = oldProperty ?? ConsoleAdjusterWidgetProperty();

    // Attributes of the property for editing.
    String? newChannel = initial.channel;
    String? newColor = initial.color;
    double newMinValue = initial.minValue;
    double newMaxValue = initial.maxValue;
    int? newDivisions = initial.divisions == (newMaxValue - newMinValue).floor()
        ? null
        : initial.divisions;
    double? newInitialValue =
    initial.initialValue == newMinValue ? null : initial.initialValue;
    int newDisplayFractionDigits = initial.displayFractionDigits;

    if (newColor != null && newColor != defaultColorHex) {
      lastColor = newColor;
    }

    // Show a form to edit above attributes.
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
              DoubleInputField(
                  context: context,
                  labelText: AppLocale.min_value.getString(context),
                  initValue: newMinValue,
                  nullable: false,
                  onValueChange: (value) => newMinValue = value!,
                  valueValidator: (value) {
                    if (value! >= newMaxValue) {
                      return AppLocale.validator_min_less_than_max;
                    }
                    return null;
                  }),
              DoubleInputField(
                  context: context,
                  labelText: AppLocale.max_value.getString(context),
                  initValue: newMaxValue,
                  nullable: false,
                  onValueChange: (value) => newMaxValue = value!,
                  valueValidator: (value) {
                    if (value! <= newMinValue) {
                      return AppLocale.validator_min_less_than_max;
                    }
                    return null;
                  }),
              DoubleInputField(
                  context: context,
                  labelText: AppLocale.initial_value.getString(context),
                  initValue: newInitialValue,
                  onValueChange: (value) => newInitialValue = value,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }

                    if (value < newMinValue || value > newMaxValue) {
                      return AppLocale.validator_between;
                    }
                    return null;
                  }),
              IntInputField(
                context: context,
                labelText: AppLocale.divisions.getString(context),
                initValue: newDivisions,
                minValue: 1,
                onValueChange: (value) => newDivisions = value,
              ),
              const SizedBox(height: 12),
              Text(AppLocale.display_section.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              IntInputField(
                context: context,
                labelText: AppLocale.fraction_digits.getString(context),
                initValue: newDisplayFractionDigits,
                // Max and min are limited by [double.toStringAsFixed].
                minValue: 0,
                maxValue: 20,
                nullable: false,
                onValueChange: (value) => newDisplayFractionDigits = value!,
              ),
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

        propCompleter.complete(ConsoleAdjusterWidgetProperty(
          channel: newChannel,
          color: newColor,
          minValue: newMinValue,
          maxValue: newMaxValue,
          initialValue: newInitialValue,
          divisions: newDivisions ?? (newMaxValue - newMinValue).floor(),
          displayFractionDigits: newDisplayFractionDigits,
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
