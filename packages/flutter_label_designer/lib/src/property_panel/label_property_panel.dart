/// Reactive property panel for the editor, wired to `designer_state`.
/// See `docs/ARCHITECTURE.md` section 7.
///
/// Edits the selected element(s)' fields; never calculates layout, never
/// imports `layout_engine` nor any `renderer_*`.
library;

export 'src/label_property_panel.dart';
export 'src/widgets/labeled_number_field.dart';
export 'src/widgets/labeled_text_field.dart';
export 'src/widgets/property_panel_section.dart';
