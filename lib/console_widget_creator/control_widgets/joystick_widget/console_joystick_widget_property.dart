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
  String? validate() {
    if (maxValueX <= minValueX) {
      return "Max value must be greater than min value.";
    }

    if (maxValueY <= minValueY) {
      return "Max value must be greater than min value.";
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
    double newMinValueX = initial.minValueX;
    double newMaxValueX = initial.maxValueX;
    double newMinValueY = initial.minValueY;
    double newMaxValueY = initial.maxValueY;

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
                  labelText: "X Direction",
                  initialValue: newChannelX,
                  onChanged: (value) => newChannelX = value),
              ChannelSelector(
                  labelText: "Y Direction",
                  initialValue: newChannelY,
                  onChanged: (value) => newChannelY = value),
              const Text(""),
              Text("Output X",
                  style: Theme.of(context).textTheme.headlineMedium),
              DoubleInputField(
                  labelText: "Min Value",
                  initValue: newMinValueX,
                  nullable: false,
                  onValueChange: (value) => newMinValueX = value!,
                  valueValidator: (value) {
                    if (value! >= newMaxValueX) {
                      return "Min value must be less than max.";
                    }
                    return null;
                  }),
              DoubleInputField(
                  labelText: "Max Value",
                  initValue: newMaxValueX,
                  nullable: false,
                  onValueChange: (value) => newMaxValueX = value!,
                  valueValidator: (value) {
                    if (value! <= newMinValueX) {
                      return "Max value must be greater than min.";
                    }
                    return null;
                  }),
              const Text(""),
              Text("Output Y",
                  style: Theme.of(context).textTheme.headlineMedium),
              DoubleInputField(
                  labelText: "Min Value",
                  initValue: newMinValueY,
                  nullable: false,
                  onValueChange: (value) => newMinValueY = value!,
                  valueValidator: (value) {
                    if (value! >= newMaxValueY) {
                      return "Min value must be less than max.";
                    }
                    return null;
                  }),
              DoubleInputField(
                  labelText: "Max Value",
                  initValue: newMaxValueY,
                  nullable: false,
                  onValueChange: (value) => newMaxValueY = value!,
                  valueValidator: (value) {
                    if (value! <= newMinValueY) {
                      return "Max value must be greater than min.";
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
