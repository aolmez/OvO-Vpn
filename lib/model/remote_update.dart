// To parse this JSON data, do
//
//     final remoteUpdate = remoteUpdateFromJson(jsonString);

import 'dart:convert';

RemoteUpdate remoteUpdateFromJson(String str) =>
    RemoteUpdate.fromJson(json.decode(str));

String remoteUpdateToJson(RemoteUpdate data) => json.encode(data.toJson());

class RemoteUpdate {
  RemoteUpdate({
    this.version,
    this.deprecatedVersions,
    this.releaseNsote,
    this.isForce,
    this.isAppClose,
  });

  String? version;
  List<String>? deprecatedVersions;
  String? releaseNsote;
  bool? isForce;
  bool? isAppClose;

  factory RemoteUpdate.fromJson(Map<String, dynamic> json) => RemoteUpdate(
        version: json["version"],
        deprecatedVersions: json["deprecated_versions"] == null
            ? null
            : List<String>.from(json["deprecated_versions"].map((x) => x)),
        releaseNsote:
            json["release_nsote"],
        isForce: json["isForce"],
        isAppClose: json["isAppClose"],
      );

  Map<String, dynamic> toJson() => {
        "version": version,
        "deprecated_versions": deprecatedVersions == null
            ? null
            : List<dynamic>.from(deprecatedVersions!.map((x) => x)),
        "release_nsote": releaseNsote ,
        "isForce": isForce ,
        "isAppClose": isAppClose,
      };
}
