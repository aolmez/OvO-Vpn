import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:vpn/model/vpn.dart';

class ServerListUI extends StatefulWidget {
  const ServerListUI({Key? key}) : super(key: key);

  @override
  State<ServerListUI> createState() => _ServerListUIState();
}

final vpnsRef =
    FirebaseFirestore.instance.collection('vpnServer').withConverter<Vpn>(
          fromFirestore: (snapshots, _) => Vpn.fromJson(snapshots.data()!),
          toFirestore: (vpn, _) => vpn.toJson(),
        );

class _ServerListUIState extends State<ServerListUI> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pick Your Server"),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot<Vpn>>(
        stream: vpnsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(snapshot.error.toString()),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.requireData;

          return ListView.builder(
            itemCount: data.size,
            itemBuilder: (context, index) {
              return item(vpn: data.docs[index].data());
            },
          );
        },
      ),
    );
  }

  Widget item({required Vpn vpn}) {
    return Container(
      padding: const EdgeInsets.all(5),
      margin: const EdgeInsets.only(top: 5, left: 8, right: 8),
      decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10), color: Colors.grey.shade200),
      child: ListTile(
        contentPadding: const EdgeInsets.only(left: 5),
        leading: Image.asset("assets/flag/${vpn.cod}.png", height: 35),
        title: Text(
          vpn.serverName!,
          style:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}
