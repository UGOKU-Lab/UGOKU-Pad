import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/broadcaster/multi_channel_broadcaster.dart';
import '../../../util/widget/console_widget_card.dart';
import '../../console_error_widget_creator.dart';
import 'console_toggle_switch_widget_property.dart';
import 'package:ugoku_console/util/AppLocale.dart';

class ConsoleToggleSwitchWidget extends StatefulWidget {
  final ConsoleToggleSwitchWidgetProperty property;
  final MultiChannelBroadcaster? broadcaster;

  const ConsoleToggleSwitchWidget({
    super.key,
    required this.property,
    this.broadcaster,
  });

  @override
  State<ConsoleToggleSwitchWidget> createState() =>
      _ConsoleToggleSwitchWidgetState();
}

class _ConsoleToggleSwitchWidgetState extends State<ConsoleToggleSwitchWidget> {
  late double _value;
  bool _activate = false;

  StreamSubscription? _subscription;

  /// Sets the delta value and adds the value to the sink.
  void _toggleValue() {
    setState(() {
      _value = _value == widget.property.initialValue
          ? widget.property.reversedValue
          : widget.property.initialValue;
    });

    if (widget.property.channel != null) {
      widget.broadcaster
          ?.sinkOn(widget.property.channel!)
          ?.add(_value.toDouble());
    }
  }

  void _initState() {
    final latestValue = widget.property.channel != null
        ? widget.broadcaster?.read(widget.property.channel!)
        : null;

    _value = latestValue ?? widget.property.initialValue;

    // Broadcast the initial value.
    if (latestValue == null && widget.property.channel != null) {
      widget.broadcaster
          ?.sinkOn(widget.property.channel!)
          ?.add(_value.toDouble());
    }
  }

  void _initBroadcastListening() {
    _subscription?.cancel();
    _subscription = null;

    if (widget.property.channel == null) {
      return;
    }

    _subscription =
        widget.broadcaster?.streamOn(widget.property.channel!)?.listen((event) {
          // Exit when already activated.
          if (_activate) return;

          // Update the value.
          setState(() {
            if (event == widget.property.initialValue) {
              _value = widget.property.initialValue;
            } else if (event == widget.property.reversedValue) {
              _value = widget.property.reversedValue;
            }
          });
        });
  }

  void _broadcastCurrentValue() {
    if (widget.property.channel == null) {
      return;
    }

    widget.broadcaster
        ?.sinkOn(widget.property.channel!)
        ?.add(_value.toDouble());
  }

  @override
  void initState() {
    // Initialize state.
    _initState();

    // Add a lister for the broadcasting.
    _initBroadcastListening();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ConsoleToggleSwitchWidget oldWidget) {
    if (widget.property != oldWidget.property) {
      _initState();
    }

    final broadcasterChanged = widget.broadcaster != oldWidget.broadcaster;
    if (broadcasterChanged) {
      _broadcastCurrentValue();
    }

    if (broadcasterChanged ||
        widget.property.channel != oldWidget.property.channel) {
      _initBroadcastListening();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  Widget build(BuildContext context) {
    final paramError = widget.property.validate(context);
    if (paramError != null) {
      return ConsoleErrorWidgetCreator.createWith(
          brief: AppLocale.parameter_error.getString(context),
          detail: paramError);
    }

    final labelText = widget.property.labelText;
    final hasLabel = labelText.trim().isNotEmpty;
    final isOff = _value == widget.property.initialValue;
    final backgroundColor = isOff
        ? Theme.of(context).colorScheme.surface
        : hexToColor(widget.property.color.toString());
    final labelColor = isOff
        ? Theme.of(context).colorScheme.onSurface
        : Theme.of(context).colorScheme.surface;
    final baseLabelStyle =
        Theme.of(context).textTheme.titleSmall ?? const TextStyle();
    final labelStyle = baseLabelStyle.copyWith(
      color: labelColor,
      fontSize: 24,
    );

    return ConsoleWidgetCard(
      color: widget.property.color.toString(),
      activate: _activate,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _activate = true),
        onTapCancel: () => setState(() => _activate = false),
        onTap: () {
          setState(() {
            _activate = false;
            _toggleValue();
          });
        },
        //onLongPress: () => {},
        child: Container(
          color: backgroundColor,
          child: Stack(
            children: [
              Center(
                child: LayoutBuilder(
                  builder: (context, constraints) => isOff
                      ? Icon(
                          Icons.toggle_off_outlined,
                          size:
                              min(constraints.maxHeight, constraints.maxWidth) /
                                  2,
                          color: widget.property.color != null
                              ? hexToColor(widget.property.color.toString())
                              : hexToColor(defaultColorHex),
                        )
                      : Icon(
                          Icons.toggle_on_outlined,
                          size:
                              min(constraints.maxHeight, constraints.maxWidth) /
                                  2,
                          color: Theme.of(context).colorScheme.surface,
                        ),
                ),
              ),
              if (hasLabel)
                Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      labelText,
                      style: labelStyle,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.fade,
                      softWrap: false,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
