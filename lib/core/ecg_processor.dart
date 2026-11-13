import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:csv/csv.dart';
import 'package:xml/xml.dart';
import 'package:svg_path_parser/svg_path_parser.dart';

class EcgProcessor {
  /// Transforma o primeiro caminho SVG usando um ECG.
  static String transform({
    required String svgXml,
    required String csvText,
    double amplitude = 12,
    int pathIndex = 0,
    int timeColumn = 0,
    int voltageColumn = 1,
  }) {
    // -----------------------------------------
    // 1. LER O CSV
    // -----------------------------------------

    final rows = const CsvToListConverter(eol: '\n').convert(csvText);

    if (rows.length < 2) {
      throw Exception('CSV vazio ou inválido.');
    }

    final data = <List<double>>[];

    // Ignora o cabeçalho.
    for (final row in rows.skip(1)) {
      if (row.length <= math.max(timeColumn, voltageColumn)) {
        continue;
      }

      final t = double.tryParse(row[timeColumn].toString().trim());

      final v = double.tryParse(row[voltageColumn].toString().trim());

      if (t != null && v != null) {
        data.add([t, v]);
      }
    }

    if (data.length < 2) {
      throw Exception('Poucos pontos válidos no CSV.');
    }

    // Ordenar pelo tempo.
    data.sort((a, b) => a[0].compareTo(b[0]));

    // Tratar tempos duplicados pela média.
    final grouped = <double, List<double>>{};

    for (final point in data) {
      grouped.putIfAbsent(point[0], () => []);
      grouped[point[0]]!.add(point[1]);
    }

    final times = <double>[];
    final values = <double>[];

    for (final entry in grouped.entries) {
      times.add(entry.key);

      final mean = entry.value.reduce((a, b) => a + b) / entry.value.length;

      values.add(mean);
    }

    // Remover deslocamento da linha de base.
    final sortedValues = [...values]..sort();

    final baseline = sortedValues[sortedValues.length ~/ 2];

    for (var i = 0; i < values.length; i++) {
      values[i] -= baseline;
    }

    // -----------------------------------------
    // 2. LER O SVG
    // -----------------------------------------

    final document = XmlDocument.parse(svgXml);

    final paths = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'path')
        .toList();

    if (pathIndex < 0 || pathIndex >= paths.length) {
      throw Exception('Caminho SVG não encontrado.');
    }

    final element = paths[pathIndex];

    final originalPath = parseSvgPath(element.getAttribute('d') ?? '');

    // -----------------------------------------
    // 3. OBTER AS MÉTRICAS DA CURVA
    // -----------------------------------------

    final metrics = originalPath.computeMetrics().toList();

    if (metrics.isEmpty) {
      throw Exception('O SVG não possui uma curva válida.');
    }

    // Por enquanto, utilizamos o primeiro contorno.
    final metric = metrics.first;
    final length = metric.length;

    if (length <= 0) {
      throw Exception('Comprimento inválido.');
    }

    // -----------------------------------------
    // 4. INTERPOLAR O ECG
    // -----------------------------------------

    double interpolate(double t) {
      if (t <= times.first) return values.first;
      if (t >= times.last) return values.last;

      var low = 0;
      var high = times.length - 1;

      while (high - low > 1) {
        final mid = (low + high) ~/ 2;

        if (times[mid] <= t) {
          low = mid;
        } else {
          high = mid;
        }
      }

      final ratio = (t - times[low]) / (times[high] - times[low]);

      return values[low] + ratio * (values[high] - values[low]);
    }

    // -----------------------------------------
    // 5. APLICAR A TRANSFORMAÇÃO
    // -----------------------------------------

    final coordinates = <ui.Offset>[];

    final startTime = times.first;
    final endTime = times.last;

    for (var i = 0; i < rows.length; i++) {
      // Distância percorrida no SVG.
      final s = length * i / (rows.length - 1);

      final tangent = metric.getTangentForOffset(s);

      if (tangent == null) continue;

      final position = tangent.position;
      final direction = tangent.vector;

      final magnitude = math.sqrt(
        direction.dx * direction.dx + direction.dy * direction.dy,
      );

      if (magnitude < 1e-10) continue;

      // Tangente unitária.
      final tx = direction.dx / magnitude;
      final ty = direction.dy / magnitude;

      // Normal unitária.
      final nx = -ty;
      final ny = tx;

      // Associar posição no desenho ao tempo do ECG.
      final t = startTime + (endTime - startTime) * i / (rows.length - 1);

      final signal = interpolate(t);

      final displacement = amplitude * signal;

      // Q(s) = P(s) + A * E(t) * N(s)
      coordinates.add(
        ui.Offset(
          position.dx + displacement * nx,
          position.dy + displacement * ny,
        ),
      );
    }

    if (coordinates.length < 2) {
      throw Exception('Não foi possível reconstruir a curva.');
    }

    // -----------------------------------------
    // 6. GERAR O NOVO PATH
    // -----------------------------------------

    final generatedPath = ui.Path();
    final buffer = StringBuffer();

    generatedPath.moveTo(coordinates.first.dx, coordinates.first.dy);
    buffer.write(
      'M ${coordinates.first.dx.toStringAsFixed(3)} '
      '${coordinates.first.dy.toStringAsFixed(3)} ',
    );

    for (final point in coordinates.skip(1)) {
      generatedPath.lineTo(point.dx, point.dy);
      buffer.write(
        'L ${point.dx.toStringAsFixed(3)} '
        '${point.dy.toStringAsFixed(3)} ',
      );
    }

    element.setAttribute('d', buffer.toString());

    // Garantir que seja uma linha, não uma área preenchida.
    element.setAttribute('fill', 'none');
    _setInlineStyle(element, 'fill', 'none');

    if (element.getAttribute('stroke') == null) {
      element.setAttribute('stroke', '#000000');
    }

    element.setAttribute('stroke-linecap', 'round');
    element.setAttribute('stroke-linejoin', 'round');

    if (!_hasTransformedAncestor(element)) {
      final bounds = generatedPath.getBounds();
      const padding = 8.0;
      final left = bounds.left - padding;
      final top = bounds.top - padding;
      final width = bounds.width + padding * 2;
      final height = bounds.height + padding * 2;
      final root = document.rootElement;
      root
        ..setAttribute(
          'viewBox',
          '${left.toStringAsFixed(3)} ${top.toStringAsFixed(3)} '
              '${width.toStringAsFixed(3)} ${height.toStringAsFixed(3)}',
        )
        ..setAttribute('width', width.toStringAsFixed(3))
        ..setAttribute('height', height.toStringAsFixed(3));
    }

    return document.toXmlString(pretty: true);
  }

  static String styleSvg({
    required String svgXml,
    int pathIndex = 0,
    String? strokeColor,
    double? strokeWidth,
    String? fillColor,
    double? opacity,
    String? lineCap,
    String? lineJoin,
    String? dashArray,
  }) {
    final document = XmlDocument.parse(svgXml);

    // Localiza os paths do SVG.
    final paths = document.findAllElements('path').toList();

    if (pathIndex < 0 || pathIndex >= paths.length) {
      throw RangeError('Path index inválido: $pathIndex');
    }

    final path = paths[pathIndex];

    // Altera somente os parâmetros informados.
    if (strokeColor != null) {
      path.setAttribute('stroke', strokeColor);
      _setInlineStyle(path, 'stroke', strokeColor);
    }

    if (strokeWidth != null) {
      if (strokeWidth <= 0) {
        throw ArgumentError('strokeWidth deve ser maior que zero.');
      }

      path.setAttribute('stroke-width', strokeWidth.toString());
      _setInlineStyle(path, 'stroke-width', strokeWidth.toString());
    }

    if (fillColor != null) {
      path.setAttribute('fill', fillColor);
      _setInlineStyle(path, 'fill', fillColor);
    }

    if (opacity != null) {
      if (opacity < 0 || opacity > 1) {
        throw ArgumentError('opacity deve estar entre 0 e 1.');
      }

      path.setAttribute('opacity', opacity.toString());
      _setInlineStyle(path, 'opacity', opacity.toString());
    }

    if (lineCap != null) {
      const validCaps = ['butt', 'round', 'square'];

      if (!validCaps.contains(lineCap)) {
        throw ArgumentError('lineCap inválido.');
      }

      path.setAttribute('stroke-linecap', lineCap);
      _setInlineStyle(path, 'stroke-linecap', lineCap);
    }

    if (lineJoin != null) {
      const validJoins = ['arcs', 'bevel', 'miter', 'miter-clip', 'round'];

      if (!validJoins.contains(lineJoin)) {
        throw ArgumentError('lineJoin inválido.');
      }

      path.setAttribute('stroke-linejoin', lineJoin);
      _setInlineStyle(path, 'stroke-linejoin', lineJoin);
    }

    if (dashArray != null) {
      path.setAttribute('stroke-dasharray', dashArray);
      _setInlineStyle(path, 'stroke-dasharray', dashArray);
    }

    return document.toXmlString();
  }

  static void _setInlineStyle(
    XmlElement element,
    String property,
    String value,
  ) {
    final declarations = (element.getAttribute('style') ?? '')
        .split(';')
        .where((declaration) {
          final separator = declaration.indexOf(':');
          return separator >= 0 &&
              declaration.substring(0, separator).trim().toLowerCase() !=
                  property;
        })
        .map((declaration) => declaration.trim())
        .toList();
    declarations.add('$property: $value !important');
    element.setAttribute('style', declarations.join('; '));
  }

  static bool _hasTransformedAncestor(XmlElement element) {
    XmlNode? ancestor = element.parent;
    while (ancestor is XmlElement) {
      if (ancestor.getAttribute('transform') != null) return true;
      ancestor = ancestor.parent;
    }
    return false;
  }
}
