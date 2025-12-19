import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../broadcaster_provider.dart';
import '../AppLocale.dart';

/// Creates a dropdown button to select a broadcast channel.
class ChannelSelector extends ConsumerWidget {
  final String? labelText;
  final String? initialValue;
  final void Function(String?)? onChanged;
  final String? Function(String?)? validator;

  const ChannelSelector({
    super.key,
    this.labelText,
    this.initialValue,
    this.onChanged,
    this.validator,
  });

  @override
  Widget build(context, ref) {
    var channel = initialValue;

    final availableChannels = ref.watch(availableChannelProvider);

    // Reset the channel if not available.
    if (availableChannels.every((chan) => chan.identifier != channel)) {
      channel = null;
    }

    // Return the stated dropdown button; the state makes the button can display
    // the selected option.
    return StatefulBuilder(
      builder: (context, setState) => DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: labelText),
        itemHeight: null,
        isExpanded: true,
        initialValue: channel,
        validator: validator,
        selectedItemBuilder: (context) => [
          Container(
              height: kMinInteractiveDimension,
              alignment: Alignment.centerLeft,
              child: Text(AppLocale.empty.getString(context))),
          ...availableChannels.map((chan) => Container(
              height: kMinInteractiveDimension,
              alignment: Alignment.centerLeft,
              child: Text(chan.name ?? chan.identifier))),
        ],
        items: [
            DropdownMenuItem(
              child: ListTile(
                title: Text(AppLocale.empty.getString(context)),
                subtitle:
                  Text(AppLocale.no_channel_to_allocate.getString(context)))),
          ...availableChannels.map((chan) => DropdownMenuItem(
              value: chan.identifier,
              child: ListTile(
                title: Text(chan.name ?? chan.identifier),
                subtitle:
                chan.description != null ? Text(chan.description!) : null,
              )))
        ],
        onChanged: (value) {
          setState(() {
            channel = value;
          });
          onChanged?.call(channel);
        },
      ),
    );
  }
}
