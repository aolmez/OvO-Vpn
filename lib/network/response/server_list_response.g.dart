// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_list_response.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ServerListResponse _$ServerListResponseFromJson(Map<String, dynamic> json) =>
    ServerListResponse(
      json['status'] as bool?,
      (json['data'] as List<dynamic>?)
          ?.map((e) => Server.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$ServerListResponseToJson(ServerListResponse instance) =>
    <String, dynamic>{
      'status': instance.status,
      'data': instance.data,
    };
