// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Server _$ServerFromJson(Map<String, dynamic> json) => Server(
      json['id'] as int?,
      json['name'] as String?,
      json['address'] as String?,
      json['ip'] as String?,
      json['created_at'] as String?,
      json['updated_at'] as String?,
      json['category'] == null
          ? null
          : Category.fromJson(json['category'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ServerToJson(Server instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'address': instance.address,
      'ip': instance.ip,
      'created_at': instance.createdAt,
      'updated_at': instance.updatedAt,
      'category': instance.category,
    };
