// To parse this JSON data, do
//
//     final vpn = vpnFromJson(jsonString);

import 'dart:convert';

List<Vpn> vpnFromJson(String str) =>
    List<Vpn>.from(json.decode(str).map((x) => Vpn.fromJson(x)));

String vpnToJson(List<Vpn> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Vpn {
  Vpn({
    this.cod,
    this.config,
    this.password,
    this.username,
    this.serverName,
  });

  String? cod;
  String? config;
  String? password;
  String? username;
  String? serverName;

  factory Vpn.fromJson(Map<String, dynamic> json) => Vpn(
        cod: json["cod"] == null ? null : json["cod"],
        config: json["config"] == null ? null : json["config"],
        password: json["password"] == null ? null : json["password"],
        username: json["username"] == null ? null : json["username"],
        serverName: json["server_name"] == null ? null : json["server_name"],
      );

  Map<String, dynamic> toJson() => {
        "cod": cod == null ? null : cod,
        "config": config == null ? null : config,
        "password": password == null ? null : password,
        "username": username == null ? null : username,
        "server_name": serverName == null ? null : serverName,
      };
}
