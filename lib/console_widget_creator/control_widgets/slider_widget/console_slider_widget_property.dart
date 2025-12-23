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
  String? validate(BuildContext context) {
    if (maxValue <= minValue) {
      return AppLocale.validator_min_less_than_max.getString(context);
    }
    if (initialValue < minValue || maxValue < initialValue) {
      return AppLocale.validator_between.getString(context);
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
    int newMinValue = initial.minValue.toInt();
    int newMaxValue = initial.maxValue.toInt();
    int? newInitialValue = initial.initialValue.toInt();

    if (newInitialValue == newMinValue) {
      newInitialValue = null;
    }

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
                  labelText: AppLocale.min_value.getString(context),
                  initValue: newMinValue,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newMinValue = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value >= newMaxValue) {
                      return AppLocale.validator_min_less_than_max
                          .getString(context);
                    }
                    return null;
                  }),
              IntInputField(
                  context: context,
                  labelText: AppLocale.max_value.getString(context),
                  initValue: newMaxValue,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newMaxValue = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value <= newMinValue) {
                      return AppLocale.validator_min_less_than_max
                          .getString(context);
                    }
                    return null;
                  }),
              IntInputField(
                  context: context,
                  labelText: AppLocale.initial_value.getString(context),
                  initValue: newInitialValue,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newInitialValue = value,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }

                    if (value < newMinValue || value > newMaxValue) {
                      return AppLocale.validator_between.getString(context);
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
          minValue: newMinValue.toDouble(),
          maxValue: newMaxValue.toDouble(),
          initialValue: newInitialValue?.toDouble(),
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
