// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'pokemon_variant.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class PokemonVariantAdapter extends TypeAdapter<PokemonVariant> {
  @override
  final int typeId = 5;

  @override
  PokemonVariant read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return PokemonVariant(
      id: fields[0] as int,
      name: fields[1] as String,
      formName: fields[2] as String,
      imageUrl: fields[3] as String,
      variantType: fields[4] as String,
      types: (fields[5] as List).cast<String>(),
    );
  }

  @override
  void write(BinaryWriter writer, PokemonVariant obj) {
    writer
      ..writeByte(6)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.formName)
      ..writeByte(3)
      ..write(obj.imageUrl)
      ..writeByte(4)
      ..write(obj.variantType)
      ..writeByte(5)
      ..write(obj.types);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PokemonVariantAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
