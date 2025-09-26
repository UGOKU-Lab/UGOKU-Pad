import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugoku_console/util/AppLocale.dart';

class PrivacyPage extends StatefulWidget {
  const PrivacyPage({super.key});

  @override
  State<StatefulWidget> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends State<PrivacyPage> {
  Future<void> acceptPrivacyPolicy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasAcceptedPrivacyPolicy', true);
    Navigator.of(context).pop(true); // Closes the dialog with a result of true
  }

  Future<String> loadPrivacyPolicy() async {
    try {
      return await rootBundle.loadString(AppLocale.privacy_file.getString(context));
    } catch (e) {
      throw Exception('Failed to load privacy policy');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(AppLocale.privacy.getString(context), style: const TextStyle(fontSize: 16.0)),
      content: FutureBuilder<String>(
        future: loadPrivacyPolicy(),
        builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Text('Failed to load privacy policy.');
          } else if (snapshot.hasData) {
            return SizedBox(
              width: double.maxFinite, // Ensures the dialog takes up available width
              child: SingleChildScrollView(
                child: Text(
                  snapshot.data!,
                  style: const TextStyle(fontSize: 16.0),
                ),
              ),
            );
          } else {
            return const Text('No data available.');
          }
        },
      ),
      actions: [
        /*
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Dismiss without accepting
          child: Text(AppLocale.privacy_close.getString(context), style: const TextStyle(fontSize: 16.0)),
        ),*/
        TextButton(
          onPressed: acceptPrivacyPolicy, // Accept and close
          child: Text(AppLocale.privacy_agree.getString(context), style: const TextStyle(fontSize: 16.0)),
        ),
      ],
    );
  }
}
