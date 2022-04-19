import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';
import 'package:vpn/network/response/server_list_response.dart';

import 'api_constant.dart';

part 'rest_service.g.dart';

@RestApi(
    baseUrl:
        BASE_URL)
abstract class RestService {
  factory RestService(Dio dio) = _RestService;

  @POST("/api/servers")
  Future<ServerListResponse> getServerList(
  );
}
