// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'token_wallet.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TokenWalletAdapter extends TypeAdapter<TokenWallet> {
  @override
  final int typeId = 20;

  @override
  TokenWallet read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TokenWallet(
      balance: fields[0] as int,
      totalEarned: fields[1] as int,
      totalSpent: fields[2] as int,
      lastUpdated: fields[3] as DateTime,
      dailyConversionsUsed: fields[4] as int,
      lastConversionDate: fields[5] as DateTime?,
      schemaVersion: fields[6] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TokenWallet obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.balance)
      ..writeByte(1)
      ..write(obj.totalEarned)
      ..writeByte(2)
      ..write(obj.totalSpent)
      ..writeByte(3)
      ..write(obj.lastUpdated)
      ..writeByte(4)
      ..write(obj.dailyConversionsUsed)
      ..writeByte(5)
      ..write(obj.lastConversionDate)
      ..writeByte(6)
      ..write(obj.schemaVersion);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenWalletAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TokenTransactionAdapter extends TypeAdapter<TokenTransaction> {
  @override
  final int typeId = 21;

  @override
  TokenTransaction read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TokenTransaction(
      id: fields[0] as String,
      delta: fields[1] as int,
      type: fields[2] as TokenTransactionType,
      timestamp: fields[3] as DateTime,
      description: fields[4] as String,
      reference: fields[5] as String?,
      metadata: (fields[6] as Map?)?.cast<String, dynamic>(),
    );
  }

  @override
  void write(BinaryWriter writer, TokenTransaction obj) {
    writer
      ..writeByte(7)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.delta)
      ..writeByte(2)
      ..write(obj.type)
      ..writeByte(3)
      ..write(obj.timestamp)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.reference)
      ..writeByte(6)
      ..write(obj.metadata);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenTransactionAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
