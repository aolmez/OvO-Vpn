import 'package:json_annotation/json_annotation.dart';

import 'category.dart';

part 'server.g.dart';

@JsonSerializable()
class Server {
  @JsonKey(name: "id")
  int? id;

  @JsonKey(name: "name")
  String? name;

  @JsonKey(name: "address")
  String? address;

  @JsonKey(name: "ip")
  String? ip;

  @JsonKey(name: "created_at")
  String? createdAt;

  @JsonKey(name: "updated_at")
  String? updatedAt;

  @JsonKey(name: "category")
  Category? category;

  Server(this.id, this.name, this.address, this.ip, this.createdAt,
      this.updatedAt, this.category);

  factory Server.fromJson(Map<String, dynamic> json) => _$ServerFromJson(json);

  Map<String, dynamic> toJson() => _$ServerToJson(this);

  @override
  String toString() {
    return 'Server{id: $id, name: $name, address: $address, ip: $ip, createdAt: $createdAt, updatedAt: $updatedAt, category: $category,}';
  }
}
