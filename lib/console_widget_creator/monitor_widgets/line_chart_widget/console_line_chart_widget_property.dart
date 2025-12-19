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
class ConsoleLineChartWidgetProperty implements TypedConsoleWidgetProperty {
  /// The identifier of the channel to broadcast the control value.
  final String? channel;

  final String? color;

  /// The min value of the area.
  final double minValue;

  /// The max value of the area.
  final double maxValue;

  /// The number of the sampling value.
  final int samples;

  /// The sampling period[ms].
  final int period;

  /// Creates a property.
  ConsoleLineChartWidgetProperty({
    this.channel,
    String? color,
    this.minValue = 0,
    this.maxValue = 255,
    this.samples = 10,
    this.period = 100,
  }) : color = color ?? defaultColorHex;

  /// Creates a property from the untyped [property].
  ConsoleLineChartWidgetProperty.fromUntyped(ConsoleWidgetProperty property)
      : channel = selectAttributeAs(property, "channel", null),
        color = selectAttributeAs(property, "color", defaultColorHex),
        minValue = selectAttributeAs(property, "minValue", 0),
        maxValue = selectAttributeAs(property, "maxValue", 255),
        samples = selectAttributeAs(property, "samples", 10),
        period = selectAttributeAs(property, "period", 100);

  @override
  ConsoleWidgetProperty toUntyped() => {
    "channel": channel,
    "color": color,
    "minValue": minValue,
    "maxValue": maxValue,
    "samples": samples,
    "period": period,
  };

  @override
  String? validate(BuildContext context) {
    if (maxValue == minValue) {
      return AppLocale.validator_min_max_difference.getString(context);
    }

    return null;
  }

  /// Edits interactively to create new property.
  static Future<ConsoleLineChartWidgetProperty?> create(
      BuildContext context, {
        ConsoleLineChartWidgetProperty? oldProperty,
      }) {
    final propCompleter = Completer<ConsoleLineChartWidgetProperty?>();
    final initial = oldProperty ?? ConsoleLineChartWidgetProperty();

    // Attributes of the property for editing.
    String? newChannel = initial.channel;
    String? newColor = initial.color;
    double newMinValue = initial.minValue;
    double newMaxValue = initial.maxValue;
    int newSamples = initial.samples;
    int newPeriod = initial.period;

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
              Text(AppLocale.input_channel.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              ChannelSelector(
                  initialValue: newChannel,
                  onChanged: (value) => newChannel = value),
              const SizedBox(height: 12),
              Text(AppLocale.input_value.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              DoubleInputField(
                  context: context,
                  labelText: AppLocale.min_value.getString(context),
                  initValue: newMinValue,
                  nullable: false,
                  onValueChange: (value) => newMinValue = value!,
                  valueValidator: (value) {
                    if (value! == newMaxValue) {
                      return "Min must be different from max.";
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
                    if (value! == newMinValue) {
                      return "Max must be different from min.";
                    }
                    return null;
                  }),
                const SizedBox(height: 12),
                Text(AppLocale.sampling.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              IntInputField(
                  context: context,
                  labelText:
                  AppLocale.number_of_samplings.getString(context),
                  initValue: newSamples,
                  maxValue: 100,
                  minValue: 2,
                  nullable: false,
                  onValueChange: (value) => newSamples = value!),
              IntInputField(
                  context: context,
                  labelText: AppLocale.sampling_period.getString(context),
                  initValue: newPeriod,
                  minValue: 10,
                  nullable: false,
                  onValueChange: (value) => newPeriod = value!),
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

        propCompleter.complete(ConsoleLineChartWidgetProperty(
          channel: newChannel,
          color: newColor,
          minValue: newMinValue,
          maxValue: newMaxValue,
          samples: newSamples,
          period: newPeriod,
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
