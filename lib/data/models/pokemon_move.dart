import 'package:hive/hive.dart';

part 'pokemon_move.g.dart';

@HiveType(typeId: 4)
class PokemonMove {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final String method; // 'level-up', 'machine', 'tutor', 'egg'

  @HiveField(2)
  final int? level; // null para TM, Tutor, Egg

  @HiveField(3)
  final String versionGroup; // ej: 'scarlet-violet', 'sword-shield'

  PokemonMove({
    required this.name,
    required this.method,
    this.level,
    required this.versionGroup,
  });

  factory PokemonMove.fromGraphQL(Map<String, dynamic> json) {
    final name = (json['pokemon_v2_move'] as Map<String, dynamic>)['name'] as String;
    
    final level = json['level'] as int?;
    
    // Obtener el método de aprendizaje desde la API
    String method = 'level-up'; // valor por defecto
    final methodData = json['pokemon_v2_movelearnmethod'] as Map<String, dynamic>?;
    if (methodData != null) {
      method = methodData['name'] as String? ?? 'level-up';
    } else if (level == null) {
      // Fallback: Si no tiene nivel, asumimos que es TM/máquina
      method = 'machine';
    }

    final versionGroupData = json['pokemon_v2_versiongroup'] as Map<String, dynamic>?;
    String versionGroup = 'latest';
    if (versionGroupData != null) {
      versionGroup = versionGroupData['name'] as String? ?? 'latest';
    }

    return PokemonMove(
      name: name,
      method: method,
      level: level,
      versionGroup: versionGroup,
    );
  }

  static String getMethodDisplay(String method) {
    switch (method.toLowerCase()) {
      case 'all':
        return 'Todos';
      case 'level-up':
        return 'Nivel';
      case 'machine':
        return 'TM/HM';
      case 'tutor':
        return 'Tutor';
      case 'egg':
        return 'Huevo';
      default:
        return method;
    }
  }
}
