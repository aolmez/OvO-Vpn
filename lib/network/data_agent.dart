import 'package:vpn/network/response/server.dart';

abstract class DataAgent {
  Future<List<Server>?>? getServerList();
}
