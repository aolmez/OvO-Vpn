import 'package:dio/dio.dart';
import 'package:vpn/network/data_agent.dart';
import 'package:vpn/network/response/server.dart';
import 'package:vpn/network/rest_service.dart';

class DataAgentImpl extends DataAgent {
  late RestService api;

  static final DataAgentImpl _singleton = DataAgentImpl._internal();

  factory DataAgentImpl() {
    return _singleton;
  }

  DataAgentImpl._internal() {
    final dio = Dio();
    api = RestService(dio);
  }
  @override
  Future<List<Server>?>? getServerList() {
    return api
        .getServerList()
        .asStream()
        .map((response) => response.data)
        .first;
  }
}
