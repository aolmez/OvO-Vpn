// To parse this JSON data, do
//
//     final noti = notiFromJson(jsonString);

// ignore_for_file: prefer_if_null_operators

import 'dart:convert';

List<Noti> notiFromJson(String str) =>
    List<Noti>.from(json.decode(str).map((x) => Noti.fromJson(x)));

String notiToJson(List<Noti> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));

class Noti {
  Noti({
    this.title,
    this.subtitle,
    this.context,
    this.image,
    this.type,
    this.time,
  });

  String? title;
  String? subtitle;
  String? context;
  String? image;
  String? type;
  String? time;

  factory Noti.fromJson(Map<String, dynamic> json) => Noti(
        title: json["title"] == null ? null : json["title"],
        subtitle: json["subtitle"] == null ? null : json["subtitle"],
        context: json["context"] == null ? null : json["context"],
        image: json["image"] == null ? null : json["image"],
        type: json["type"] == null ? null : json["type"],
        time: json["time"] == null ? null : json["time"],
      );

  Map<String, dynamic> toJson() => {
        "title": title == null ? null : title,
        "subtitle": subtitle == null ? null : subtitle,
        "context": context == null ? null : context,
        "image": image == null ? null : image,
        "type": type == null ? null : type,
        "time": time == null ? null : time,
      };
}
