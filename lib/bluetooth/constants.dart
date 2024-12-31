import 'dart:ui';

class DescriptorUuidPatten {
  static final userDescription = RegExp(r"^00002901.*");
  static final presentationFormat = RegExp(r"^00002904.*");
  static final aggregationFormat = RegExp(r"^00002905.*");
}

String defaultColorHex = "673AB7";

String lastColor = defaultColorHex;

bool isEditingConsole = false;
bool isAddingConsole = false;

Color hexToColor(String? hex) {
  // Use default color if hex is null
  if (hex == null || hex.isEmpty || hex == "null") {
    hex = "FF$defaultColorHex"; // Use default constant
  } else if (hex.length == 6) {
    hex = "FF$hex"; // Add alpha channel for full opacity if needed
  }

  // Parse the hex string and create a Color object
  return Color(int.parse("0x$hex"));
}