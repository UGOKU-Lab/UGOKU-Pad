import 'dart:async';

import 'package:flutter/material.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/form/channel_selector.dart';
import '../../../util/form/color_selector.dart';
import '../../../util/form/common_form_page.dart';
import '../../console_widget_creator.dart';
import '../../typed_console_widget_creator.dart';

/// Parameter of the console widget.
class ConsoleConnectorWidgetProperty extends TypedConsoleWidgetProperty {
  /// The identifier of the source channel.
  final String? channelSrc;

  /// The identifier of the destination channel.
  final String? channelDst;

  final String? color;

  /// Creates the parameter.
  ConsoleConnectorWidgetProperty({
    this.channelSrc,
    this.channelDst,
    String? color,
  })
      : color = color ?? defaultColorHex;

  /// Creates the parameter from an [prop].
  factory ConsoleConnectorWidgetProperty.fromUntyped(
      ConsoleWidgetProperty prop) {
    return ConsoleConnectorWidgetProperty(
      channelSrc: selectAttributeAs(prop, "channelSrc", null),
      channelDst: selectAttributeAs(prop, "channelDst", null),
      color: selectAttributeAs(prop, "color", defaultColorHex),
    );
  }

  /// Creates the property of itself.
  @override
  ConsoleWidgetProperty toUntyped() {
    return {
      "channelSrc": channelSrc,
      "channelDst": channelDst,
      "color": color,
    };
  }

  @override
  String? validate() {
    if (channelSrc != null && channelDst != null && channelSrc == channelDst) {
      return "Source and destination must be different.";
    }

    return null;
  }

  static Future<ConsoleConnectorWidgetProperty?> edit(BuildContext context,
      {ConsoleConnectorWidgetProperty? oldProperty}) {
    final propCompleter = Completer<ConsoleConnectorWidgetProperty?>();
    final initial = oldProperty ?? ConsoleConnectorWidgetProperty();

    // Attributes of the parameter for editing.
    String? newChannelSrc = initial.channelSrc;
    String? newChannelDst = initial.channelDst;
    String? newColor = initial.color;

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
              Text("Source Channel",
                  style: Theme.of(context).textTheme.headlineMedium),
              ChannelSelector(
                initialValue: newChannelSrc,
                onChanged: (value) => newChannelSrc = value,
                validator: (src) {
                  if (src != null && src == newChannelDst) {
                    return "Source and destination must be different.";
                  }

                  return null;
                },
              ),
              const Text(""),
              Text("Destination Channel",
                  style: Theme.of(context).textTheme.headlineMedium),
              ChannelSelector(
                initialValue: newChannelDst,
                onChanged: (value) => newChannelDst = value,
                validator: (dst) {
                  if (dst != null && dst == newChannelSrc) {
                    return "Source and destination must be different.";
                  }

                  return null;
                },
              ),
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

        propCompleter.complete(ConsoleConnectorWidgetProperty(
          channelSrc: newChannelSrc,
          channelDst: newChannelDst,
          color: newColor,
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
