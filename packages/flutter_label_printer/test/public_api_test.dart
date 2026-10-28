import 'package:flutter_label_printer/flutter_label_printer.dart';
import 'package:test/test.dart';

void main() {
  test('exposes the consumer API', () {
    expect(const LabelLayoutEngine(), isNotNull);
    expect(const ArgoxRasterRenderer(), isA<LabelRenderer>());
    expect(const PdfRenderer(), isA<LabelRenderer>());
    expect(ArgoxMediaSensing.gap, isNotNull);
  });
}
