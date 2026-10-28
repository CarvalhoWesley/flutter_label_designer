import 'package:flutter/material.dart';
import 'package:flutter_label_printer/flutter_label_printer.dart';

import '../style/shape_style_fields.dart';
import '../widgets/property_panel_section.dart';

/// Type-specific fields for [CircleElement]: stroke/fill only. The canvas
/// (not this panel) is responsible for keeping `size.width == size.height`
/// while resizing — see `docs/ARCHITECTURE.md` section 8.
class CircleSection extends StatelessWidget {
  const CircleSection({
    super.key,
    required this.element,
    required this.onChange,
  });

  final CircleElement element;
  final void Function(LabelElement Function(LabelElement) apply) onChange;

  @override
  Widget build(BuildContext context) {
    return PropertyPanelSection(
      title: 'Círculo',
      children: [
        ShapeStyleFields(
          style: element.style,
          onChanged: (value) =>
              onChange((e) => (e as CircleElement).copyWith(style: value)),
        ),
      ],
    );
  }
}
