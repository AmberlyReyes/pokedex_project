// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_list_item.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PokemonListItemAdapter extends TypeAdapter<PokemonListItem> {
  @override
  final int typeId = 0;

  @override
  PokemonListItem read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PokemonListItem(
      name: fields[0] as String,
      id: fields[1] as int,
      imageUrl: fields[2] as String,
      types: (fields[3] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PokemonListItem obj) {
    writer
      ..writeByte(4)
      ..writeByte(0)
      ..write(obj.name)
      ..writeByte(1)
      ..write(obj.id)
      ..writeByte(2)
      ..write(obj.imageUrl)
      ..writeByte(3)
      ..write(obj.types);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonListItemAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
