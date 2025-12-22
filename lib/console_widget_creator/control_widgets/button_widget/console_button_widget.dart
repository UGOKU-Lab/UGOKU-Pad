import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/broadcaster/multi_channel_broadcaster.dart';
import '../../../util/widget/console_widget_card.dart';
import '../../console_error_widget_creator.dart';
import 'console_button_widget_property.dart';
import 'package:ugoku_console/util/AppLocale.dart';

class ConsoleButtonWidget extends StatefulWidget {
  final ConsoleButtonWidgetProperty property;
  final MultiChannelBroadcaster? broadcaster;

  const ConsoleButtonWidget({
    super.key,
    required this.property,
    this.broadcaster,
  });

  @override
  State<ConsoleButtonWidget> createState() =>
      _ConsoleButtonWidgetState();
}

class _ConsoleButtonWidgetState extends State<ConsoleButtonWidget> {
  late double _value;
  bool _activate = false;

  StreamSubscription? _subscription;

  /// Sets the delta value and adds the value to the sink.
  void _toggleValue() {
    setState(() {
      _value = _value == widget.property.initialValue
          ? widget.property.tappedValue
          : widget.property.initialValue;
    });

    if (widget.property.channel != null) {
      widget.broadcaster
          ?.sinkOn(widget.property.channel!)
          ?.add(_value.toDouble());
    }
  }

  void _setValue(bool isOn) {
    setState(() {
      if (isOn) {
        _value = widget.property.tappedValue;
      } else {
        _value = widget.property.initialValue;
      }
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
            } else if (event == widget.property.tappedValue) {
              _value = widget.property.tappedValue;
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
  void didUpdateWidget(covariant ConsoleButtonWidget oldWidget) {
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

    return LayoutBuilder(
      builder: (context, constraints) => ConsoleWidgetCard(
        color: widget.property.color.toString(),  //widget.property.color != null ? widget.property.color.toString() : defaultColorHex,
        activate: _activate,
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: GestureDetector(
              onTapDown: (_) => setState(() {
                _activate = true;
                _setValue(true);
              }),
              onTapCancel: () => setState(() {
                _activate = false;
                _setValue(false);
              }),
              onTap: () {
                setState(() {
                  _activate = false;
                  _setValue(false);
                });
              },
              child: AbsorbPointer(
                child: ElevatedButton(
                  onPressed: () {
                    //_toggleValue();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.property.color != null ? hexToColor(widget.property.color.toString()) : hexToColor(defaultColorHex),
                    minimumSize: Size(
                      min(constraints.maxHeight, constraints.maxWidth),
                      min(constraints.maxHeight, constraints.maxWidth),
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                  child: Center(
                    child: Text(
                      widget.property.buttonText,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.surface,
                        fontSize: min(constraints.maxHeight, constraints.maxWidth) / 8,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
