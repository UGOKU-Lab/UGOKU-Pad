import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';
import 'package:ugoku_console/util/AppLocale.dart';

/// The property of the console widget.
class ConsoleValueMonitorProperty implements TypedConsoleWidgetProperty {
  /// The identifier of the channel to broadcast the control value.
  final String? channel;

  final String? color;

  final String labelText;

  final int displayFractionDigits;

  /// Creates a property.
  ConsoleValueMonitorProperty({
    this.channel,
    String? color,
    String? labelText,
    this.displayFractionDigits = 0,
  })  : labelText = labelText ?? "",
        color = color ?? defaultColorHex;

  /// Creates a property from the untyped [property].
  ConsoleValueMonitorProperty.fromUntyped(ConsoleWidgetProperty property)
      : channel = selectAttributeAs(property, "channel", null),
        color = selectAttributeAs(property, "color", defaultColorHex),
        labelText = selectAttributeAs(property, "labelText", ""),
        displayFractionDigits =
        selectAttributeAs(property, "displayFractionDigits", 0);

  @override
  ConsoleWidgetProperty toUntyped() => {
    "channel": channel,
    "color": color,
    "labelText": labelText,
    "displayFractionDigits": displayFractionDigits,
  };

  @override
  String? validate(BuildContext context) {
    if (displayFractionDigits < 0 || displayFractionDigits > 20) {
      return AppLocale.validator_fraction_digits_range.getString(context);
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
    String newLabelText = initial.labelText;

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
              Text(AppLocale.display_section.getString(context),
                  style: Theme.of(context).textTheme.headlineMedium),
              TextFormField(
                initialValue: newLabelText,
                decoration: InputDecoration(
                    labelText: AppLocale.title_field.getString(context)),
                onChanged: (value) => newLabelText = value,
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

        propCompleter.complete(ConsoleValueMonitorProperty(
          channel: newChannel,
          color: newColor,
          labelText: newLabelText,
          displayFractionDigits: 0,
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
