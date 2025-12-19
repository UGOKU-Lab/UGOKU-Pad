import 'dart:async';

import 'package:flutter/material.dart';

import '../../util/form/common_form_page.dart';
import '../console_widget_creator.dart';
import 'package:ugoku_console/util/AppLocale.dart';
import 'package:flutter_localization/flutter_localization.dart';

/// Creates a console widget that contains a title text.
///
/// The text will be styled to titleMedium of the theme of the context.
final consoleTitleTextWidgetCreator = ConsoleWidgetCreator(
  name: "Title Text",
  localizedNameKey: AppLocale.widget_name_title_text,
  description: "Displays a title text.",
  localizedDescriptionKey: AppLocale.widget_desc_title_text,
  series: "Decoration Widgets",
  localizedSeriesKey: AppLocale.widget_series_decoration,
  builder: (context, property) => Container(
    alignment: Alignment.centerLeft,
    child: Text(
      property["text"]?.toString() ?? "",
      style: Theme.of(context).textTheme.titleMedium,
      overflow: TextOverflow.fade,
    ),
  ),
  propertyCreator: (context, {oldProperty}) {
    final propCompleter = Completer<ConsoleWidgetProperty?>();
    String newText = oldProperty?["text"]?.toString() ?? "";

    // Open the edit form, then return the edited property.
    // If edit form is closed without saving, return null.
    CommonFormPage.show(
      context,
      title: AppLocale.property_edit.getString(context),
      content: Column(children: [
        TextFormField(
            initialValue: newText,
            decoration: InputDecoration(
                labelText: AppLocale.field_text.getString(context)),
            autofocus: true,
            onChanged: (value) => newText = value),
      ]),
    ).then((ok) {
      if (ok) {
        propCompleter.complete({"text": newText});
      } else {
        propCompleter.complete(oldProperty);
      }
    });

    return propCompleter.future;
  },
  sampleProperty: {"text": "Sample Text"},
);
