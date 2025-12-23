import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localization/flutter_localization.dart';
import 'package:ugoku_console/util/AppLocale.dart';

class IntInputField extends TextFormField {
  final String? labelText;
  final String? hintText;
  final int? initValue;
  final int? minValue;
  final int? maxValue;
  /// Whether the value is nullable: not required.
  ///
  /// If false, checks if the value is not null before [onValueChange] and
  /// [valueValidator] are called, and never pass null.
  final bool nullable;

  final void Function(int?)? onValueChange;
  final String? Function(int?)? valueValidator;

  IntInputField({
    super.key,
    required BuildContext context,
    this.labelText,
    this.hintText,
    this.initValue,
    this.minValue,
    this.maxValue,
    this.nullable = true,
    this.onValueChange,
    this.valueValidator,
  })  : super(
    initialValue: initValue?.toString(),
    decoration: InputDecoration(
        labelText: labelText != null || !nullable
            ? [labelText ?? "", nullable ? "" : "*"].join(" ")
            : null,
        hintText: hintText),
    keyboardType: TextInputType.number,
    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
    onChanged: (value) {
      final intValue = int.tryParse(value);

      if (!nullable && intValue == null) {
        return;
      }

      if (intValue != null) {
        if ((minValue != null && intValue < minValue) ||
            (maxValue != null && intValue > maxValue)) {
          return;
        }
      }

      onValueChange?.call(intValue);
    },
    validator: (value) {
      final intValue = value != null ? int.tryParse(value) : null;

      if (!nullable && intValue == null) {
        if (value?.isEmpty ?? true) {
          return AppLocale.validator_required.getString(context);
        }
        return AppLocale.validator_integer.getString(context);
      }

      if (intValue != null) {
        if (minValue != null && intValue < minValue) {
          return AppLocale.validator_min_value
              .getString(context)
              .replaceFirst('{value}', '$minValue');
        }
        if (maxValue != null && intValue > maxValue) {
          return AppLocale.validator_max_value
              .getString(context)
              .replaceFirst('{value}', '$maxValue');
        }
      }

      return valueValidator?.call(intValue);
    },
  );
}
