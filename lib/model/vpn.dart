// To parse this JSON data, do
//
//     final vpn = vpnFromJson(jsonString);

// ignore_for_file: prefer_if_null_operators

import 'dart:convert';

List<Vpn> vpnFromJson(String str) =>
    List<Vpn>.from(json.decode(str).map((x) => Vpn.fromJson(x)));

String vpnToJson(List<Vpn> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Vpn {
  Vpn({
    this.cod,
    this.config,
    this.source,
    this.status,
    this.username,
    this.password,
    this.serverName,
  });

  String? cod;
  String? config;
  String? source;
  String? status;
  String? username;
  String? password;
  String? serverName;

  factory Vpn.fromJson(Map<String, dynamic> json) => Vpn(
        cod: json["cod"] == null ? null : json["cod"],
        config: json["config"] == null ? null : json["config"],
        source: json["source"] == null ? null : json["source"],
        status: json["status"] == null ? null : json["status"],
        password: json["password"] == null ? null : json["password"],
        username: json["username"] == null ? null : json["username"],
        serverName: json["server_name"] == null ? null : json["server_name"],
      );

  Map<String, dynamic> toJson() => {
        "cod": cod == null ? null : cod,
        "config": config == null ? null : config,
        "source": source == null ? null : source,
        "status": status == null ? null : status,
        "password": password == null ? null : password,
        "username": username == null ? null : username,
        "server_name": serverName == null ? null : serverName,
      };
}

 //   "source": "aws",
                //   "status": "live",
