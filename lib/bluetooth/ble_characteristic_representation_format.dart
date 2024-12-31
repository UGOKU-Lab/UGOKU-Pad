import 'dart:math';
import 'dart:typed_data';

class BleCharacteristicPresentationFormat {
  final int _format;
  final int _exponent;

  // ignore: unused_field
  final int _unit;

  // ignore: unused_field
  final int _namespace;

  // ignore: unused_field
  final int _description;

  BleCharacteristicPresentationFormat.fromUint8List(Uint8List list)
      : assert(list.length == 7),
        _format = list.buffer.asByteData().getUint8(0),
        _exponent = list.buffer.asByteData().getUint8(1),
        _unit = list.buffer.asByteData().getUint16(2),
        _namespace = list.buffer.asByteData().getUint8(4),
        _description = list.buffer.asByteData().getUint16(5);

  List<int> formatFromDouble(double value) {
    late ByteData bytes;

    switch (_format) {
      case FormatTypes.bool:
        bytes = ByteData(1);
        bytes.setUint8(0, value.floor() & 1);

      case FormatTypes.uint8:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(1);
        bytes.setUint8(0, value.clamp(0, 255).floor());

      case FormatTypes.uint16:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(2);
        bytes.setUint16(0, value.clamp(0, 255).floor());

      case FormatTypes.uint32:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(4);
        bytes.setUint32(
            0, value.clamp(0, pow(2, 32) - 1).floor(), Endian.little);

      case FormatTypes.uint64:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(8);
        bytes.setUint64(
            0, value.clamp(0, pow(2, 64) - 1).floor(), Endian.little);

      case FormatTypes.int8:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(1);
        bytes.setInt8(0, value.clamp(-128, 127).floor());

      case FormatTypes.int16:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(2);
        bytes.setInt16(0, value.clamp(-pow(2, 15), pow(2, 15) - 1).floor());

      case FormatTypes.int32:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(4);
        bytes.setInt32(
            0, value.clamp(-pow(2, 31), pow(2, 31) - 1).floor(), Endian.little);

      case FormatTypes.int64:
        value = value * pow(0.1, _exponent);

        bytes = ByteData(8);
        bytes.setInt64(
            0, value.clamp(-pow(2, 63), pow(2, 63) - 1).floor(), Endian.little);

      case FormatTypes.float32:
        bytes = ByteData(4);
        bytes.setFloat32(0, value, Endian.little);

      case FormatTypes.float64:
        bytes = ByteData(8);
        bytes.setFloat64(0, value, Endian.little);
    }

    return bytes.buffer.asUint8List();
  }

  double? formatToDouble(List<int> values) {
    if (values.isEmpty) return null;

    ByteData bytes = ByteData(values.length);

    for (var i = 0; i < values.length; i++) {
      bytes.setUint8(i, values[i]);
    }

    switch (_format) {
      case FormatTypes.bool:
        return (bytes.getUint8(0) != 0) ? 1 : 0;
      case FormatTypes.uint8:
        return bytes.getUint8(0).toDouble() * pow(10, _exponent);
      case FormatTypes.uint16:
        return values.length < 2
            ? null
            : bytes.getUint8(0).toDouble() * pow(10, _exponent);
      case FormatTypes.uint32:
        return values.length < 4
            ? null
            : bytes.getUint32(0, Endian.little).toDouble() * pow(10, _exponent);
      case FormatTypes.uint64:
        return values.length < 8
            ? null
            : bytes.getUint64(0, Endian.little).toDouble() * pow(10, _exponent);
      case FormatTypes.int8:
        return bytes.getInt8(0).toDouble() * pow(10, _exponent);
      case FormatTypes.int16:
        return values.length < 2
            ? null
            : bytes.getUint8(0).toDouble() * pow(10, _exponent);
      case FormatTypes.int32:
        return values.length < 4
            ? null
            : bytes.getInt32(0, Endian.little).toDouble() * pow(10, _exponent);
      case FormatTypes.int64:
        return values.length < 8
            ? null
            : bytes.getInt64(0, Endian.little).toDouble() * pow(10, _exponent);
      case FormatTypes.float32:
        return values.length < 4 ? null : bytes.getFloat32(0, Endian.little);
      case FormatTypes.float64:
        return values.length < 8 ? null : bytes.getFloat64(0, Endian.little);
    }

    return bytes.getUint8(0).toDouble();
  }
}

class FormatTypes {
  static const bool = 0x01;
  static const uint8 = 0x04;
  static const uint16 = 0x06;
  static const uint32 = 0x08;
  static const uint64 = 0x0A;
  static const int8 = 0x0C;
  static const int16 = 0x0E;
  static const int32 = 0x10;
  static const int64 = 0x12;
  static const float32 = 0x14;
  static const float64 = 0x15;
}