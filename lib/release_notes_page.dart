import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugoku_console/util/AppLocale.dart';
import 'package:url_launcher/url_launcher.dart';

/// A dialog that displays the release notes loaded from a Markdown asset file.
class ReleaseNotesPage extends StatefulWidget {
  const ReleaseNotesPage({super.key});

  @override
  State<StatefulWidget> createState() => _ReleaseNotesPageState();
}

class _ReleaseNotesPageState extends State<ReleaseNotesPage> {
  Future<void> _dismissReleaseNotes() async {
    final prefs = await SharedPreferences.getInstance();
    final version = prefs.getString('version') ?? '';
    await prefs.setString('release_notes_seen_version', version);
    if (!mounted) return;
    Navigator.of(context).pop();
  }

  Future<String> _loadReleaseNotes() async {
    try {
      return await rootBundle
          .loadString(AppLocale.release_notes_file.getString(context));
    } catch (e) {
      throw Exception(
          AppLocale.release_notes_load_failed.getString(context));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        AppLocale.release_notes.getString(context),
        style: const TextStyle(fontSize: 16.0),
      ),
      content: FutureBuilder<String>(
        future: _loadReleaseNotes(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Text(
                AppLocale.release_notes_load_failed.getString(context));
          } else if (snapshot.hasData) {
            return SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: MarkdownBlock(
                  data: snapshot.data!,
                  config: MarkdownConfig(configs: [
                    LinkConfig(onTap: (url) {
                      final uri = Uri.tryParse(url);
                      if (uri != null) {
                        launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    }),
                  ]),
                ),
              ),
            );
          } else {
            return Text(
                AppLocale.release_notes_load_failed.getString(context));
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: _dismissReleaseNotes,
          child: Text(
            AppLocale.release_notes_dismiss.getString(context),
            style: const TextStyle(fontSize: 16.0),
          ),
        ),
      ],
    );
  }
}
