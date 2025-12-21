import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ugoku_console/bluetooth/constants.dart';

import 'console_edit_page.dart';
import 'console_panel/generation_parameter.dart';
import 'package:ugoku_console/util/AppLocale.dart';

/// The save object that contains the parameters to build the console.
class ConsoleSaveObject {
  /// The title of the save.
  String title;

  /// The parameter of the console panel.
  ConsolePanelParameter parameter;

  /// Creates a save object named to the [title] with the [parameter].
  ConsoleSaveObject(this.title, this.parameter);

  /// Creates a save object from a JSON map.
  factory ConsoleSaveObject.fromJson(dynamic json) {
    if (json is! Map) {
      return ConsoleSaveObject.fromError(
        "Illegal Save Object",
        "The save object must be a map.",
      );
    }

    final title = json["title"];

    if (title is! String) {
      return ConsoleSaveObject.fromError(
        "Illegal Save Object",
        'The "title" property must be a string.',
      );
    }

    final parameter = ConsolePanelParameter.fromJson(json["parameter"]);

    return ConsoleSaveObject(title, parameter);
  }

  /// Creates a save object with the error described in [brief] and [detail]ed
  /// texts.
  factory ConsoleSaveObject.fromError(
      String brief,
      String detail, {
        String title = '!ERROR!',
      }) {
    return ConsoleSaveObject(
      title,
      ConsolePanelParameter.fromError(brief, detail),
    );
  }

  /// Returns a JSON map.
  Map<String, dynamic> toJson() {
    return {
      "title": title,
      "parameter": parameter.toJson(),
    };
  }

  /// Creates new object with copied data.
  ConsoleSaveObject copy() {
    return ConsoleSaveObject(title, parameter.copy());
  }
}

/// The page that lists consoles.
class ConsoleListPage extends StatefulWidget {
  const ConsoleListPage({super.key});

  @override
  State<ConsoleListPage> createState() => _ConsoleListPageState();
}

class _ConsoleListPageState extends State<ConsoleListPage> {
  List<ConsoleSaveObject> _saves = [];
  final Set<int> _selectedIndexes = {};
  SharedPreferences? _prefs;

  bool get _inSelectMode => _selectedIndexes.isNotEmpty;

  @override
  void initState() {
    SharedPreferences.getInstance().then((pref) {
      _prefs = pref;
      setState(() {
        _saves = pref
            .getStringList("consoles")
            ?.map((json) => jsonDecode(json))
            .whereType<Map<String, dynamic>>()
            .map((map) => ConsoleSaveObject.fromJson(map))
            .toList() ??
            [];
      });
    });

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocale.consoles.getString(context)),
          centerTitle: true,
          actions: [
            ...(_selectedIndexes.isEmpty
                ? [
              IconButton(
                  onPressed: _addConsole, icon: const Icon(Icons.add)),
            ]
                : []),
            ...(_selectedIndexes.length == 1
                ? [
              // Duplicate the selected save.
              IconButton(
                  onPressed: () async {
                    final selectedSave = _saves[_selectedIndexes.first];
                    setState(() {
                      _saves.add(ConsoleSaveObject(
                          _getUniqueTitle(selectedSave.title),
                          selectedSave.parameter.copy()));
                    });
                  },
                  icon: const Icon(Icons.content_copy_outlined)),
            ]
                : []),
            ...(_selectedIndexes.isNotEmpty
                ? [
              IconButton(
                  onPressed: _deleteSelection,
                  icon: const Icon(Icons.delete)),
            ]
                : []),
          ],
        ),
        body: _saves.isEmpty
            ? Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(AppLocale.nothing_here.getString(context),
                  style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 12),
              OutlinedButton(
                  onPressed: _addConsole,
                  child: Text(AppLocale.create_new.getString(context)))
            ],
          ),
        )
            : ListView.builder(
          itemCount: _saves.length,
          itemBuilder: (context, index) => _ConsoleListTile(
            _saves[index],
            selected: _selectedIndexes.contains(index),
            showCheckbox: _selectedIndexes.isNotEmpty,
            onTap: () {
              // Pop the target console if not in select mode.
              if (!_inSelectMode) {
                // Save consoles.
                SharedPreferences.getInstance().then((pref) {
                  pref.setStringList(
                      "consoles",
                      _saves
                          .map((save) => jsonEncode(save.toJson()))
                          .toList());

                  // Set the
                  pref.setString("recentlyUsed",
                      jsonEncode(_saves[index].parameter.toJson()));
                  pref.setString("recentlyUsedTitle", _saves[index].title);
                });

                // Pop the tapped console.
                Navigator.of(context).pop(_saves[index].parameter);
              }
              // Toggle select for the target in select mode.
              else {
                _toggleSelection(index);
              }
            },
            onLongPress: () {
              setState(() {
                _toggleSelection(index);
              });
            },
            trailing: !_inSelectMode
                ? Wrap(children: [
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editConsoleAt(index),
              ),
            ])
                : null,
          ),
        ),
      ),
      onPopInvoked: (final didPop) async {
        // Save current parameters.
        await SharedPreferences.getInstance().then((pref) {
          pref.setStringList("consoles",
              _saves.map((save) => jsonEncode(save.toJson())).toList());
        });
      },
    );
  }

  void _persistSaves(
    List<ConsoleSaveObject> saves, {
    ConsoleSaveObject? recentlyUsed,
  }) {
    final encodedSaves =
        saves.map((save) => jsonEncode(save.toJson())).toList();
    final recentlyUsedJson = recentlyUsed != null
        ? jsonEncode(recentlyUsed.parameter.toJson())
        : null;
    final recentlyUsedTitle = recentlyUsed?.title;

    void persist(SharedPreferences pref) {
      pref.setStringList("consoles", encodedSaves);
      if (recentlyUsedJson != null) {
        pref.setString("recentlyUsed", recentlyUsedJson);
      }
      if (recentlyUsedTitle != null) {
        pref.setString("recentlyUsedTitle", recentlyUsedTitle);
      }
    }

    final pref = _prefs;
    if (pref != null) {
      persist(pref);
      return;
    }

    SharedPreferences.getInstance().then(persist);
  }

  /// Toggles the selection of the item indexed at [index].
  void _toggleSelection(int index) {
    // Remove if already selected, otherwise add.
    setState(() {
      if (!_selectedIndexes.remove(index)) {
        _selectedIndexes.add(index);
      }
    });
  }

  /// Deletes all selected items.
  void _deleteSelection() {
    final shouldDeleteCompleter = Completer<bool>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppLocale.warning.getString(context)),
        content:
        Text(AppLocale.delete_console_warning.getString(context)),
        actions: [
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shouldDeleteCompleter.complete(false);
              },
              child: Text(AppLocale.no.getString(context))),
          TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                shouldDeleteCompleter.complete(true);
              },
              child: Text(AppLocale.yes.getString(context))),
        ],
      ),
    );

    shouldDeleteCompleter.future.then((shouldDelete) {
      // Do nothing if canceled.
      if (!shouldDelete) return;

      final selectionList = _selectedIndexes.toList();
      selectionList.sort();

      // Remove the selection from the tail of the list.
      for (final index in selectionList.reversed) {
        _saves.removeAt(index);
      }

      // Update for also [_save].
      setState(() {
        _selectedIndexes.clear();
      });
    });
  }

  /// Returns the unique title begins with the [title].
  ///
  /// The serial number may be appended to the tail.
  String _getUniqueTitle(String title, {List<ConsoleSaveObject>? saves}) {
    final baseTitle = title;
    final existingTitles =
        (saves ?? _saves).map((save) => save.title).toList();
    int serialNo = 1;

    // Determine the title: "title #".
    while (existingTitles.contains(title)) {
      title = "$baseTitle $serialNo";
      serialNo++;
    }

    return title;
  }

  /// Adds a console.
  Future _addConsole() async {
    isAddingConsole = true;
    isEditingConsole = false;

    // Push the edit page.
    final ConsoleSaveObject? save =
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
        ConsoleEditPage(
          save: ConsoleSaveObject(
            _getUniqueTitle(AppLocale.untitled.getString(context)),
            ConsolePanelParameter(rows: 2, columns: 2, cells: [])),
          focusTitle: true),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));

    if (save == null) {
      return;
    }

    final newTitle = _getUniqueTitle(save.title);
    final newSave = ConsoleSaveObject(newTitle, save.parameter);
    final updatedSaves = List<ConsoleSaveObject>.from(_saves)
      ..add(newSave)
      ..sort((a, b) => a.title.compareTo(b.title));

    _persistSaves(updatedSaves, recentlyUsed: newSave);

    if (!mounted) {
      return;
    }

    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop(newSave.parameter);
      return;
    }

    setState(() {
      _saves = updatedSaves;
    });
  }

  /// Edits the console indexed at the [index].
  Future _editConsoleAt(int index) async {

    isEditingConsole = true;
    isAddingConsole = false;

    // Push the edit page.
    final ConsoleSaveObject? save =
    await Navigator.of(context).push(PageRouteBuilder(
      pageBuilder: (context, animation, secondaryAnimation) =>
          ConsoleEditPage(save: _saves[index]),
      transitionDuration: Duration.zero,
      reverseTransitionDuration: Duration.zero,
    ));

    // Update a save object with the popped parameter.
    if (save != null) {
      final updatedSaves = List<ConsoleSaveObject>.from(_saves)
        ..removeAt(index);
      final newTitle = _getUniqueTitle(save.title, saves: updatedSaves);
      final updatedSave = ConsoleSaveObject(newTitle, save.parameter);
      updatedSaves.add(updatedSave);
      updatedSaves.sort((a, b) => a.title.compareTo(b.title));

      _persistSaves(updatedSaves, recentlyUsed: updatedSave);

      if (!mounted) {
        return;
      }

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(updatedSave.parameter);
        return;
      }

      setState(() {
        _saves = updatedSaves;
      });
    }
  }
}

/// The list tile for the console.
class _ConsoleListTile extends ListTile {
  final ConsoleSaveObject saveObject;
  final bool showCheckbox;

  _ConsoleListTile(
      this.saveObject, {
        this.showCheckbox = false,
        super.selected,
        super.onTap,
        super.onLongPress,
        super.trailing,
      }) : super(
    title: Text(saveObject.title),
    leading: showCheckbox
        ? (Icon(
        selected ? Icons.check_box : Icons.check_box_outline_blank))
        : null,
  );
}
