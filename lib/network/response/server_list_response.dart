import 'package:json_annotation/json_annotation.dart';
import 'package:vpn/network/response/server.dart';

part 'server_list_response.g.dart';

@JsonSerializable()
class ServerListResponse {
  @JsonKey(name: "status")
  bool? status;

  @JsonKey(name: "data")
  List<Server>? data;

  ServerListResponse(this.status,this.data,);

  factory ServerListResponse.fromJson(Map<String, dynamic> json) =>
      _$ServerListResponseFromJson(json);

  Map<String, dynamic> toJson() => _$ServerListResponseToJson(this);
}
