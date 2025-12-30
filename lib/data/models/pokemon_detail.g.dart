// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_detail.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PokemonDetailAdapter extends TypeAdapter<PokemonDetail> {
  @override
  final int typeId = 1;

  @override
  PokemonDetail read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PokemonDetail(
      id: fields[0] as int,
      name: fields[1] as String,
      height: fields[2] as int,
      weight: fields[3] as int,
      types: (fields[4] as List).cast<String>(),
      abilities: (fields[5] as List).cast<PokemonAbility>(),
      stats: (fields[6] as Map).cast<String, int>(),
      spriteUrl: fields[7] as String,
      moves: (fields[8] as List).cast<PokemonMove>(),
      eggGroups: (fields[9] as List).cast<String>(),
      typeMatchups: (fields[10] as Map).cast<String, double>(),
      isFavorite: fields[11] as bool,
      evolutions: (fields[12] as List).cast<PokemonEvolution>(),
      variants: (fields[13] as List).cast<PokemonVariant>(),
      flavorText: fields[14] as String,
    );
  }

  @override
  void write(BinaryWriter writer, PokemonDetail obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.height)
      ..writeByte(3)
      ..write(obj.weight)
      ..writeByte(4)
      ..write(obj.types)
      ..writeByte(5)
      ..write(obj.abilities)
      ..writeByte(6)
      ..write(obj.stats)
      ..writeByte(7)
      ..write(obj.spriteUrl)
      ..writeByte(8)
      ..write(obj.moves)
      ..writeByte(9)
      ..write(obj.eggGroups)
      ..writeByte(10)
      ..write(obj.typeMatchups)
      ..writeByte(11)
      ..write(obj.isFavorite)
      ..writeByte(12)
      ..write(obj.evolutions)
      ..writeByte(13)
      ..write(obj.variants)
      ..writeByte(14)
      ..write(obj.flavorText);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonDetailAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
