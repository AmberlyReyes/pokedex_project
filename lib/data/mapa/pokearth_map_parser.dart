import 'dart:ui';
import 'package:flutter/services.dart' show rootBundle;

class PokearthArea {
  final Rect coordinates; // los lados del rectangulo
  final String title;

  PokearthArea({
    required this.coordinates,
    required this.title,
  });

  @override
  String toString() => '$title ($coordinates)';
}

class PokearthMap {
  static Future<List<PokearthArea>> loadAreas() async {
    // Carga el archivo HTML
    final html = await rootBundle.loadString('assets/ubicaciones.html');

    // Se crea donde se guardaran las areas
    final areas = <PokearthArea>[];

    // Extrae todo lo que tengas las etiquetas <area> del HTML
    final areaPattern = RegExp(
      r'<area\s+([^>]+)>',
      multiLine: true,
    );

    // Itera sobre cada coincidencia encontrada
    for (final match in areaPattern.allMatches(html)) {
      final attributes = match.group(1) ?? '';

      // Extraer atributos title y coords
      final titleMatch = RegExp(r'title="([^"]*)"').firstMatch(attributes);
      final coordsMatch = RegExp(r'coords="([^"]*)"').firstMatch(attributes);

      // Si encuentra un atrubito nulo salta al siguiente
      if (titleMatch == null || coordsMatch == null) {
        continue;
      }

      // Obtener valores de los atributos
      final title = titleMatch.group(1) ?? '';
      final coordsStr = coordsMatch.group(1) ?? '';

      // Si las coordenadas estan vacias salta al siguiente
      if (coordsStr.isEmpty) continue;

      // Parsear coordenadas
      final coords = coordsStr
          .split(',')
          .map((e) => int.tryParse(e.trim()))
          .toList();

      // Si alguna de las coordenadas no son validas salta al siguiente
      if (coords.length != 4 || coords.any((e) => e == null)) continue;

      final left = coords[0]!.toDouble();
      final top = coords[1]!.toDouble();
      final right = coords[2]!.toDouble();
      final bottom = coords[3]!.toDouble();

      areas.add(PokearthArea(
        title: title,
        coordinates: Rect.fromLTRB(left, top, right, bottom),
      ));
    }

    return areas;
  }
}