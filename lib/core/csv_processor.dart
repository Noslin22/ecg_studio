import 'package:csv/csv.dart';

class EcgPoint {
  final double time;
  final double amplitude;

  const EcgPoint({required this.time, required this.amplitude});

  @override
  String toString() => 'EcgPoint($time, $amplitude)';
}

class CsvProcessor {
  /// Lê um CSV e converte seu conteúdo em pontos ECG.
  ///
  /// Suporta:
  /// - Separador ; ou ,
  /// - Decimal com ponto ou vírgula
  /// - Arquivos com ou sem cabeçalho
  static List<EcgPoint> parse(
    String content, {
    bool hasHeader = false,
    String? delimiter,
  }) {
    final separator = delimiter ?? _detectDelimiter(content);

    final rows = const CsvToListConverter(
      eol: '\n',
    ).convert(content, fieldDelimiter: separator);

    final points = <EcgPoint>[];

    for (var i = hasHeader ? 1 : 0; i < rows.length; i++) {
      final row = rows[i];

      if (row.length < 2) continue;

      final time = _parseNumber(row[0]);
      final amplitude = _parseNumber(row[1]);

      if (time == null || amplitude == null) {
        continue;
      }

      points.add(EcgPoint(time: time, amplitude: amplitude));
    }

    if (points.isEmpty) {
      throw FormatException('Nenhum ponto válido encontrado.');
    }

    return points;
  }

  /// Concatena vários segmentos ECG.
  static List<EcgPoint> concatenate(
    List<String> contents, {
    List<bool>? headers,
    List<String>? delimiters,
    bool averageDuplicates = true,
  }) {
    if (contents.isEmpty) {
      throw ArgumentError('Nenhum arquivo informado.');
    }

    if (headers != null && headers.length != contents.length) {
      throw ArgumentError('Quantidade de cabeçalhos incompatível.');
    }

    if (delimiters != null && delimiters.length != contents.length) {
      throw ArgumentError('Quantidade de delimitadores incompatível.');
    }

    final allPoints = <EcgPoint>[];

    for (var i = 0; i < contents.length; i++) {
      allPoints.addAll(
        parse(
          contents[i],
          hasHeader: headers?[i] ?? false,
          delimiter: delimiters?[i],
        ),
      );
    }

    // Ordenar pelo tempo.
    allPoints.sort((a, b) => a.time.compareTo(b.time));

    // Agrupar tempos iguais.
    final result = <EcgPoint>[];

    var i = 0;

    while (i < allPoints.length) {
      final currentTime = allPoints[i].time;
      final values = <double>[];

      while (i < allPoints.length && allPoints[i].time == currentTime) {
        values.add(allPoints[i].amplitude);
        i++;
      }

      final value = averageDuplicates
          ? values.reduce((a, b) => a + b) / values.length
          : values.first;

      result.add(EcgPoint(time: currentTime, amplitude: value));
    }

    return result;
  }

  /// Exporta os pontos em CSV padronizado.
  static String export(List<EcgPoint> points) {
    final rows = <List<dynamic>>[
      ['tempo_s', 'amplitude'],
      ...points.map(
        (point) => [
          point.time.toStringAsFixed(6),
          point.amplitude.toStringAsFixed(6),
        ],
      ),
    ];

    return const ListToCsvConverter(
      fieldDelimiter: ',',
      eol: '\n',
    ).convert(rows);
  }

  /// Pipeline completo: concatena e exporta.
  static String process(
    List<String> contents, {
    List<bool>? headers,
    List<String>? delimiters,
    bool averageDuplicates = true,
  }) {
    final points = concatenate(
      contents,
      headers: headers,
      delimiters: delimiters,
      averageDuplicates: averageDuplicates,
    );

    return export(points);
  }

  static String _detectDelimiter(String content) {
    final firstLine = content
        .split(RegExp(r'\r?\n'))
        .firstWhere((line) => line.trim().isNotEmpty, orElse: () => '');

    return firstLine.split(';').length > firstLine.split(',').length
        ? ';'
        : ',';
  }

  static double? _parseNumber(dynamic value) {
    var text = value.toString().trim();

    if (text.isEmpty) return null;

    // Aceita decimal com vírgula ou ponto.
    if (text.contains(',') && text.contains('.')) {
      // Assume ponto como separador de milhar
      // e vírgula como separador decimal.
      text = text.replaceAll('.', '').replaceAll(',', '.');
    } else {
      text = text.replaceAll(',', '.');
    }

    return double.tryParse(text);
  }
}
