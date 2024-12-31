import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../util/form/common_form_page.dart';
import '../../util/widget/console_widget_card.dart';
import '../console_widget_creator.dart';

final consoleNoteWidgetCreator = ConsoleWidgetCreator(
  name: "Note",
  description: "Displays a note.",
  series: "Decoration Widgets",
  builder: (context, property) {
    // Determine if the device language is Japanese
    final locale = Localizations.localeOf(context);
    final isJapanese = locale.languageCode == 'ja';

    // Select the appropriate body based on the device language
    final bodyText = isJapanese
        ? property["body_ja"]?.toString() ?? ""
        : property["body"]?.toString() ?? "";

    // Parse the body text to create a clickable link.
    List<InlineSpan> parseBody(String body) {
      final spans = <InlineSpan>[];
      final regex = RegExp(r'\[url=(.+?)\](.+?)\[/url\]');
      final matches = regex.allMatches(body);

      int lastMatchEnd = 0;
      for (final match in matches) {
        // Add text before the match
        if (match.start > lastMatchEnd) {
          spans.add(TextSpan(
            text: body.substring(lastMatchEnd, match.start),
            style: Theme.of(context).textTheme.bodyLarge,
          ));
        }

        // Add the clickable link
        final url = match.group(1)!;
        final displayText = match.group(2)!;
        spans.add(
          TextSpan(
            text: displayText,
            style: const TextStyle(
              color: const Color(0xFF673AB7),
              decoration: TextDecoration.underline,
              decorationColor: const Color(0xFF673AB7),
            ),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                if (await canLaunchUrl(Uri.parse(url))) {
                  await launchUrl(Uri.parse(url));
                } else {
                  throw 'Could not launch $url';
                }
              },
          ),
        );

        lastMatchEnd = match.end;
      }

      // Add remaining text after the last match
      if (lastMatchEnd < body.length) {
        spans.add(TextSpan(
          text: body.substring(lastMatchEnd),
          style: Theme.of(context).textTheme.bodyLarge,
        ));
      }

      return spans;
    }

    return ConsoleWidgetCard(
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                property["title"]?.toString() ?? "",
                style: Theme.of(context).textTheme.headlineMedium,
                overflow: TextOverflow.fade,
              ),
              RichText(
                text: TextSpan(
                  children: parseBody(bodyText),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  },
  propertyCreator: (context, {oldProperty}) {
    final propCompleter = Completer<ConsoleWidgetProperty?>();
    String newTitle = oldProperty?["title"]?.toString() ?? "";
    String newBody = oldProperty?["body"]?.toString() ?? "";
    String newBodyJa = oldProperty?["body_ja"]?.toString() ?? "";

    // Open the edit form, then return the edited property.
    // If edit form is closed without saving, return null.
    CommonFormPage.show(
      context,
      title: "Property Edit",
      content: Column(children: [
        TextFormField(
          initialValue: newTitle,
          decoration: const InputDecoration(labelText: "Title"),
          autofocus: true,
          onChanged: (value) => newTitle = value,
        ),
        TextFormField(
          initialValue: newBody,
          decoration: const InputDecoration(labelText: "Body"),
          maxLines: null,
          onChanged: (value) => newBody = value,
        ),
        TextFormField(
          initialValue: newBodyJa,
          decoration: const InputDecoration(labelText: "Body (Japanese)"),
          maxLines: null,
          onChanged: (value) => newBodyJa = value,
        ),
      ]),
    ).then((ok) {
      if (ok) {
        propCompleter.complete({
          "title": newTitle,
          "body": newBody,
          "body_ja": newBodyJa,
        });
      } else {
        propCompleter.complete(oldProperty);
      }
    });

    return propCompleter.future;
  },
  sampleProperty: {
    "title": "Sample",
    "body": "Sample body.",
    "body_ja": "サンプルボディ。",
  },
);

