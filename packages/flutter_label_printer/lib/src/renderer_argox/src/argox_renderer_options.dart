import '../../renderer/label_renderer.dart';

/// Which Argox command language to emit. See `docs/ROADMAP.md`, etapa 16.
enum ArgoxDialect {
  /// Printer Programming Language A — Datamax-compatible, mostly
  /// resolution-independent. Implemented.
  ppla,

  /// Printer Programming Language B — Eltron/EPL2-compatible,
  /// resolution-dependent. Not implemented yet; [ArgoxRenderer.render]
  /// throws [UnimplementedError] for this dialect.
  pplb,
}

/// `direct-thermal` needs no ribbon; `thermal-transfer` prints through a
/// ribbon and produces more durable labels.
enum ArgoxTransferType { directThermal, thermalTransfer }

/// How the printer finds where each label starts.
enum ArgoxMediaSensing {
  /// Die-cut labels separated by a gap — `<STX>e` (edge/gap sensor). The
  /// printer re-syncs on every gap, so feed error never accumulates.
  gap,

  /// Media with a black mark on the back — `<STX>r` (reflective sensor).
  blackMark,

  /// Continuous media with no separation — `<STX>c####` fixed feed length.
  /// Any mismatch between that length and the real pitch accumulates over
  /// a batch, so only use it for genuinely continuous paper.
  continuous,
}

/// Settings specific to [ArgoxRenderer].
class ArgoxRendererOptions extends RendererOptions {
  const ArgoxRendererOptions({
    this.dialect = ArgoxDialect.ppla,
    this.darkness = 10,
    this.copies = 1,
    this.transferType = ArgoxTransferType.directThermal,
    this.offsetXMm = 0,
    this.offsetYMm = 0,
    this.feedOffsetMm = 0,
    this.mediaSensing = ArgoxMediaSensing.gap,
  }) : assert(darkness >= 2 && darkness <= 20, 'darkness (heat) is 2-20'),
       assert(copies >= 1 && copies <= 9999, 'copies is 1-9999');

  final ArgoxDialect dialect;

  /// Heat/darkness value, `H02`-`H20` in PPLA. Higher prints darker.
  final int darkness;

  /// Number of copies to print, `Q0001`-`Q9999` in PPLA.
  final int copies;

  final ArgoxTransferType transferType;

  /// Manual calibration offset (millimeters) added to every element's X/Y
  /// position before it's sent to the printer — compensates for a print
  /// head/gap-sensor mechanical offset specific to a given physical
  /// printer/media, the same kind of adjustment BarTender exposes as
  /// "print offset". There's no way to read this from the printer or the
  /// Windows driver (PPLA goes out as a raw byte stream, bypassing the
  /// driver entirely — see `WindowsRawPrintTransport`), so it has to be a
  /// user-supplied value found by trial print.
  final double offsetXMm;
  final double offsetYMm;

  /// Manual calibration offset (millimeters) added to the label length used
  /// in the `c` command — controls how far the printer physically feeds
  /// per label cycle, not where content is drawn within it (that's
  /// [offsetXMm]/[offsetYMm]). Mirrors what a printer driver's own
  /// "sensor offset"/"top offset" media setting does (e.g. Argox's
  /// "Deslocamento superior"), which isn't reachable from a raw PPLA
  /// stream — see `WindowsRawPrintTransport`.
  ///
  /// Only used with [ArgoxMediaSensing.continuous]: with a gap or black
  /// mark sensor the printer measures the pitch itself.
  final double feedOffsetMm;

  final ArgoxMediaSensing mediaSensing;
}
