import 'package:get/state_manager.dart';
import 'package:vpn/network/data_agent.dart';
import 'package:vpn/network/data_agent_impl.dart';
import 'package:vpn/network/response/server.dart';

class ServerController extends GetxController {
  var isLoading = true.obs;
  var servers = <Server>[].obs;
  DataAgent dataAgent = DataAgentImpl();

  void fetchServers() async {
    try {
      isLoading(true);
      var res = await dataAgent.getServerList();
      if (res != null) {
        servers.assignAll(res);
      }
    } finally {
      isLoading(false);
    }
  }
}
