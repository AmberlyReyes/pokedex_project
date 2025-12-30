// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cached_pokemon_list.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class CachedPokemonListAdapter extends TypeAdapter<CachedPokemonList> {
  @override
  final int typeId = 6;

  @override
  CachedPokemonList read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return CachedPokemonList(
      pokemons: (fields[0] as List).cast<PokemonListItem>(),
      cachedAt: fields[1] as DateTime,
      offset: fields[2] as int,
      limit: fields[3] as int,
    );
  }

  @override
  void write(BinaryWriter writer, CachedPokemonList obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.pokemons)
      ..writeByte(1)
      ..write(obj.cachedAt)
      ..writeByte(2)
      ..write(obj.offset)
      ..writeByte(3)
      ..write(obj.limit);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CachedPokemonListAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
