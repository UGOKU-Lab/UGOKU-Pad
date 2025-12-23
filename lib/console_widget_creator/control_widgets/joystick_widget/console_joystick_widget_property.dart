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
class ConsoleJoystickWidgetProperty extends TypedConsoleWidgetProperty {
  /// The identifier of the channel to broadcast the output value X.
  final String? channelX;

  /// The identifier of the channel to broadcast the output value Y.
  final String? channelY;

  final String? color;

  /// The min value of the output X.
  final double minValueX;

  /// The max value of the output X.
  final double maxValueX;

  /// The min value of the output Y.
  final double minValueY;

  /// The max value of the output Y.
  final double maxValueY;

  /// The width of the range of value x.
  double get valueWidthX => maxValueX - minValueX;

  /// The width of the range of value y.
  double get valueWidthY => maxValueY - minValueY;

  /// Creates the parameter.
  ConsoleJoystickWidgetProperty(
      {this.channelX,
        this.channelY,
        String? color,
        double? minValueX,
        double? maxValueX,
        double? minValueY,
        double? maxValueY})
      : color = color ?? defaultColorHex,
        minValueX = minValueX ?? 0,
        maxValueX = maxValueX ?? 255,
        minValueY = minValueY ?? 0,
        maxValueY = maxValueY ?? 255;

  /// Creates the parameter from an [prop].
  factory ConsoleJoystickWidgetProperty.fromUntyped(
      ConsoleWidgetProperty prop) {
    return ConsoleJoystickWidgetProperty(
      channelX: selectAttributeAs(prop, "channelX", null),
      channelY: selectAttributeAs(prop, "channelY", null),
      color: selectAttributeAs(prop, "color", defaultColorHex),
      minValueX: selectAttributeAs(prop, "minValueX", null),
      maxValueX: selectAttributeAs(prop, "maxValueX", null),
      minValueY: selectAttributeAs(prop, "minValueY", null),
      maxValueY: selectAttributeAs(prop, "maxValueY", null),
    );
  }

  /// Creates the property of itself.
  @override
  ConsoleWidgetProperty toUntyped() {
    return {
      "channelX": channelX,
      "channelY": channelY,
      "color": color,
      "minValueX": minValueX,
      "maxValueX": maxValueX,
      "minValueY": minValueY,
      "maxValueY": maxValueY,
    };
  }

  @override
  String? validate(BuildContext context) {
    if (maxValueX <= minValueX) {
      return AppLocale.validator_min_less_than_max.getString(context);
    }

    if (maxValueY <= minValueY) {
      return AppLocale.validator_min_less_than_max.getString(context);
    }

    return null;
  }

  static Future<ConsoleJoystickWidgetProperty?> edit(BuildContext context,
      {ConsoleJoystickWidgetProperty? oldProperty}) {
    final propCompleter = Completer<ConsoleJoystickWidgetProperty?>();
    final initial = oldProperty ?? ConsoleJoystickWidgetProperty();

    // Attributes of the parameter for editing.
    String? newChannelX = initial.channelX;
    String? newChannelY = initial.channelY;
    String? newColor = initial.color;
    int newMinValueX = initial.minValueX.toInt();
    int newMaxValueX = initial.maxValueX.toInt();
    int newMinValueY = initial.minValueY.toInt();
    int newMaxValueY = initial.maxValueY.toInt();

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
                  labelText: AppLocale.x_direction.getString(context),
                  initialValue: newChannelX,
                  onChanged: (value) => newChannelX = value),
              ChannelSelector(
                  labelText: AppLocale.y_direction.getString(context),
                  initialValue: newChannelY,
                  onChanged: (value) => newChannelY = value),
              const SizedBox(height: 12),
              Text(AppLocale.output_x.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              IntInputField(
                  context: context,
                  labelText: AppLocale.min_value.getString(context),
                  initValue: newMinValueX,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newMinValueX = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value >= newMaxValueX) {
                      return AppLocale.validator_min_less_than_max
                          .getString(context);
                    }
                    return null;
                  }),
              IntInputField(
                  context: context,
                  labelText: AppLocale.max_value.getString(context),
                  initValue: newMaxValueX,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newMaxValueX = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value <= newMinValueX) {
                      return AppLocale.validator_min_less_than_max
                          .getString(context);
                    }
                    return null;
                  }),
              const SizedBox(height: 12),
              Text(AppLocale.output_y.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              IntInputField(
                  context: context,
                  labelText: AppLocale.min_value.getString(context),
                  initValue: newMinValueY,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newMinValueY = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value >= newMaxValueY) {
                      return AppLocale.validator_min_less_than_max
                          .getString(context);
                    }
                    return null;
                  }),
              IntInputField(
                  context: context,
                  labelText: AppLocale.max_value.getString(context),
                  initValue: newMaxValueY,
                  nullable: false,
                  minValue: 0,
                  maxValue: 255,
                  onValueChange: (value) => newMaxValueY = value!,
                  valueValidator: (value) {
                    if (value == null) {
                      return null;
                    }
                    if (value <= newMinValueY) {
                      return AppLocale.validator_min_less_than_max
                          .getString(context);
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

        propCompleter.complete(ConsoleJoystickWidgetProperty(
          channelX: newChannelX,
          channelY: newChannelY,
          color: newColor,
          minValueX: newMinValueX.toDouble(),
          maxValueX: newMaxValueX.toDouble(),
          minValueY: newMinValueY.toDouble(),
          maxValueY: newMaxValueY.toDouble(),
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
