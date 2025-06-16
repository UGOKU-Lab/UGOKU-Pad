import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../../bluetooth/constants.dart';
import '../../../util/broadcaster/multi_channel_broadcaster.dart';
import '../../../util/widget/console_widget_card.dart';
import '../../../util/widget/handle_widget.dart';
import '../../console_error_widget_creator.dart';
import 'console_joystick_widget_property.dart';

class ConsoleJoystickWidget extends StatefulWidget {
  final ConsoleJoystickWidgetProperty property;
  final MultiChannelBroadcaster? broadcaster;

  const ConsoleJoystickWidget({
    super.key,
    required this.property,
    this.broadcaster,
  });

  @override
  State<ConsoleJoystickWidget> createState() => _ConsoleJoystickWidgetState();
}

class _ConsoleJoystickWidgetState extends State<ConsoleJoystickWidget> {
  bool _activate = false;

  late double _rateX;
  late double _rateY;

  //double? _prevValueX;
  //double? _prevValueY;
  StreamSubscription? _subscriptionX;
  StreamSubscription? _subscriptionY;

  /// Sets the value and adds the value to the sink.
  void _setRate(double rateX, double rateY, {bool broadcast = true}) {
    setState(() {
      _rateX = rateX.clamp(0, 1);
      _rateY = rateY.clamp(0, 1);
    });

    final valueX =
    (_rateX * widget.property.valueWidthX + widget.property.minValueX)
        .floorToDouble();

    final valueY =
    (_rateY * widget.property.valueWidthY + widget.property.minValueY)
        .floorToDouble();

    //print("_setRate: valueX: " + valueX.toString() + " valueY: " + valueY.toString());

    if (broadcast) {
      if (widget.property.channelX != null /* && _prevValueX != valueX*/) {
        widget.broadcaster?.sinkOn(widget.property.channelX!)?.add(valueX);

        //print("broadcast: valueX: " + valueX.toString());
      } else {
        //print("broadcast2: valueX: " + valueX.toString());
      }

      if (widget.property.channelY != null /* && _prevValueY != valueY*/) {
        widget.broadcaster?.sinkOn(widget.property.channelY!)?.add(valueY);

        //print("broadcast: valueY: " + valueY.toString());
      } else {
        //print("broadcast2: valueY: " + valueY.toString());
      }
    }

    //_prevValueX = valueX;
    //_prevValueY = valueY;
  }

  void _initState() {
    final valueX = widget.property.channelX != null
        ? widget.broadcaster?.read(widget.property.channelX!)
        : null;

    final valueY = widget.property.channelY != null
        ? widget.broadcaster?.read(widget.property.channelY!)
        : null;

    final rateX = valueX != null
        ? (valueX - widget.property.minValueX) / widget.property.valueWidthX
        : 0.5;

    final rateY = valueY != null
        ? (valueY - widget.property.minValueY) / widget.property.valueWidthY
        : 0.5;

    // Set the values.
    _setRate(rateX, rateY, broadcast: valueX == null || valueY == null);
  }

  void _initBroadcastListening() {
    _subscriptionX?.cancel();
    _subscriptionX = null;

    _subscriptionY?.cancel();
    _subscriptionY = null;

    // For dim x.
    if (widget.property.channelX != null) {
      _subscriptionX = widget.broadcaster
          ?.streamOn(widget.property.channelX!)
          ?.listen((event) {
        // Exit when already activated.
        if (_activate) return;

        // Update the value.
        setState(() {
          _rateX = ((event - widget.property.minValueX) /
              widget.property.valueWidthX)
              .clamp(0, 1);
        });
      });
    }

    // For dim y.
    if (widget.property.channelY != null) {
      _subscriptionY = widget.broadcaster
          ?.streamOn(widget.property.channelY!)
          ?.listen((event) {
        // Exit when already activated.
        if (_activate) return;

        // Update the value.
        setState(() {
          _rateY = ((event - widget.property.minValueY) /
              widget.property.valueWidthY)
              .clamp(0, 1);
        });
      });
    }
  }

  @override
  void initState() {
    _initState();

    _initBroadcastListening();

    super.initState();
  }

  @override
  void didUpdateWidget(covariant ConsoleJoystickWidget oldWidget) {
    // Initialize members with the widget if required.
    if (widget.property != oldWidget.property) {
      _initState();
    }

    // Add a lister for the broadcasting if required.
    if (widget.broadcaster != oldWidget.broadcaster ||
        widget.property.channelX != oldWidget.property.channelX ||
        widget.property.channelY != oldWidget.property.channelY) {
      _initBroadcastListening();
    }

    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _subscriptionX?.cancel();
    _subscriptionY?.cancel();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final paramError = widget.property.validate();

    if (paramError != null) {
      return ConsoleErrorWidgetCreator.createWith(
          brief: "Parameter Error", detail: paramError);
    }

    return ConsoleWidgetCard(
      color: widget.property.color.toString(),
      activate: _activate,
      child: LayoutBuilder(
        builder: (context, constraints) =>
            Stack(fit: StackFit.expand, children: [
              Container(color: Theme.of(context).colorScheme.surface),
              Positioned(
                top: -constraints.maxHeight * (_rateY - 0.5) +
                    (constraints.maxHeight / 2 - _getSquareSize(constraints) / 3),
                left: constraints.maxWidth * (_rateX - 0.5) +
                    (constraints.maxWidth / 2 - _getSquareSize(constraints) / 3),
                child: Container(
                    width: _getSquareSize(constraints) * 2 / 3,
                    height: _getSquareSize(constraints) * 2 / 3,
                    decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(13),
                        color: hexToColor(widget.property.color.toString()))),
              ),
              Center(
                child: Icon(
                  Icons.control_camera,
                  size: _getSquareSize(constraints) / 2,
                  color: Color.lerp(
                      Theme.of(context).colorScheme.surface,
                      hexToColor(widget.property.color.toString()),
                      (_rateX - 0.5).abs() + (_rateY - 0.5).abs()),
                ),
              ),
              // Gesture handle.
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onPanEnd: (_) {
                  // Whenever the finger lifts anywhere in this area,
                  // send neutral “stop” to servos:
                  _setRate(0.5, 0.5);
                },
                onPanCancel: () {
                  // Also handle cancellation (in case the system interrupts the drag)
                  _setRate(0.5, 0.5);
                },
                child: HandleWidget(
                  onValueChange: (dx, dy) => _setRate(
                    dx / constraints.maxWidth + 0.5,
                    -dy / constraints.maxHeight + 0.5,
                  ),
                  onValueFix: () {
                    //print("handle_widget: onValueFix1");
                    _setRate(0.5, 0.5);

                    Timer(const Duration(milliseconds: 50), () { //100
                      //print("handle_widget: onValueFix2");
                      //_prevValueX = -1;
                      //_prevValueY = -1;

                      _setRate(0.5, 0.5);
                    });
                  },
                  onActivationChange: (act) => setState(() => _activate = act),
                ),
              ),
            ]),
      ),
    );
  }

  static double _getSquareSize(BoxConstraints constraints) =>
      min(constraints.maxHeight, constraints.maxWidth);
}
