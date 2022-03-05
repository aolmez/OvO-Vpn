import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:openvpn_flutter/openvpn_flutter.dart';
import 'package:vpn/Router/route.dart';
import 'package:vpn/controller/update_controller.dart';
import 'package:vpn/controller/vpn_controller.dart';
import 'package:vpn/model/vpn.dart';

class HomeUI extends StatefulWidget {
  const HomeUI({Key? key}) : super(key: key);

  @override
  State<HomeUI> createState() => _HomeUIState();
}

class _HomeUIState extends State<HomeUI> {

  UpdateController controller = Get.put(UpdateController()); 

  late OpenVPN engine;
  VpnStatus? status;
  VPNStage? stage;
  bool _granted = false;

  @override
  void initState() {
    engine = OpenVPN(
      onVpnStatusChanged: (data) {
        setState(() {
          status = data;
        });
      },
      onVpnStageChanged: (data, raw) {
        setState(() {
          stage = data;
        });
      },
    );
    engine.initialize(
        groupIdentifier: "group.com.laskarmedia.vpn",
        providerBundleIdentifier:
            "id.laskarmedia.openvpnFlutterExample.VPNExtension",
        localizedDescription: "VPN by OvO God");
    super.initState();
  }

  Future<void> initPlatformState({required Vpn vpn}) async {
    engine.connect(
        utf8.fuse(base64).decode(vpn.config!), vpn.serverName ?? "OvO Server",
        username: vpn.username, password: vpn.password);
    if (!mounted) return;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'OvO VPN',
              style: TextStyle(color: Colors.black),
            ),
            // GestureDetector(
            //   onTap: () {
            //     // FirebaseFirestore.instance.collection("vpnServer").add({
            //     //   "server_name": "Canada (Montreal)",
            //     //   "cod": "CN",
            //     //   "config": "IyBBdXRvbWF0aWNhbGx5IGdlbmVyYXRlZCBPcGVuVlBOIGNsaWVudCBjb25maWcgZmlsZQojIEdlbmVyYXRlZCBvbiBGcmkgTWFyICA0IDEzOjI2OjQ1IDIwMjIgYnkgaXAtMTcyLTI2LTEtMjI2LmNhLWNlbnRyYWwtMS5jb21wdXRlLmludGVybmFsCgojIERlZmF1bHQgQ2lwaGVyCmNpcGhlciBBRVMtMjU2LUNCQwojIE5vdGU6IHRoaXMgY29uZmlnIGZpbGUgY29udGFpbnMgaW5saW5lIHByaXZhdGUga2V5cwojICAgICAgIGFuZCB0aGVyZWZvcmUgc2hvdWxkIGJlIGtlcHQgY29uZmlkZW50aWFsIQojIE5vdGU6IHRoaXMgY29uZmlndXJhdGlvbiBpcyB1c2VyLWxvY2tlZCB0byB0aGUgdXNlcm5hbWUgYmVsb3cKIyBPVlBOX0FDQ0VTU19TRVJWRVJfVVNFUk5BTUU9b3ZvCiMgRGVmaW5lIHRoZSBwcm9maWxlIG5hbWUgb2YgdGhpcyBwYXJ0aWN1bGFyIGNvbmZpZ3VyYXRpb24gZmlsZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9QUk9GSUxFPW92b0AxNzIuMjYuMS4yMjYKIyBPVlBOX0FDQ0VTU19TRVJWRVJfQ0xJX1BSRUZfQUxMT1dfV0VCX0lNUE9SVD1UcnVlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0NMSV9QUkVGX0JBU0lDX0NMSUVOVD1GYWxzZQojIE9WUE5fQUNDRVNTX1NFUlZFUl9DTElfUFJFRl9FTkFCTEVfQ09OTkVDVD1UcnVlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX0NMSV9QUkVGX0VOQUJMRV9YRF9QUk9YWT1UcnVlCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX1dTSE9TVD0xNzIuMjYuMS4yMjY6NDQzCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX1dFQl9DQV9CVU5ETEVfU1RBUlQKIyAtLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KIyBNSUlESERDQ0FnU2dBd0lCQWdJRVlpSUZQakFOQmdrcWhraUc5dzBCQVFzRkFEQkhNVVV3UXdZRFZRUURERHhQCiMgY0dWdVZsQk9JRmRsWWlCRFFTQXlNREl5TGpBekxqQTBJREV5T2pJMU9qTTBJRlZVUXlCcGNDMHhOekl0TWpZdAojIE1TMHlNall1WTJFdFkyVXdIaGNOTWpJd01qSTFNVEl5TlRNMFdoY05Nekl3TXpBeE1USXlOVE0wV2pCSE1VVXcKIyBRd1lEVlFRREREeFBjR1Z1VmxCT0lGZGxZaUJEUVNBeU1ESXlMakF6TGpBMElERXlPakkxT2pNMElGVlVReUJwCiMgY0MweE56SXRNall0TVMweU1qWXVZMkV0WTJVd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFSwojIEFvSUJBUURDc3RDYkNnOHBjdkt4b2g4Tks5eXdZZDZLWjM1THNOdTdzYWFLOHM1a1pieXQxdUMvQm1IMldROUIKIyBFa3ZheXlMTFlsdGFpT05QUjNPMXJGZ3MxMm9pV1B6ZUs2QS9GdmlUQ1pYTmtkMFlPQ0pPY2VtV04vRlFxbklJCiMgREVLZGdWUm41SmNneERwSzBuRTlxSXpMSldaQkloSFBXeXVvdHZBRGtaRTVScTJJVWtlWm4yOHd0NlhpMS9XOQojIDd0c0dLTWJQLzVlQ09MVHpCbW5Td05YeWpoSzU5Rm82bk9DYzE4UEVMWkU0T1ZyOW9FeUphd2R2b1dQQVNkNncKIyBGeWdzeHprZGY1a0w1RXJ3NGxMMXNNbUpkdEQyZUFJcmVqcjVWUWJ6bVBpVmkvZ0pZMExPbTh2WlVRRy9ybktHCiMgNEVVdk0rSitzRFYwOFUzUFViWVFMNUI2WkhjTkFnTUJBQUdqRURBT01Bd0dBMVVkRXdRRk1BTUJBZjh3RFFZSgojIEtvWklodmNOQVFFTEJRQURnZ0VCQUVzSHB3anN5UnVTd0o4eXVNSDA1eGw2NUxtTTZyMnplNEp1ajR6eGJvSksKIyBDYnVqaUZtYVlMSmlxcmNnN3RMejBYa1BjdUNUaWJWdHhRYktYclpJTitJV0prTmp4aXVxc3RQUmZhbi8vZmNyCiMgenNnM0RoazF1ZFlLYXZvb2NGQkd2N0dOYy8zMDJqL2gwa080clBDWHVnM0Y1aTJnLzhjU2k2S1M1WTdzWTJJZAojIGJiNll1VWhad2VuTnpsZ1VnaU83TmZKSXpUelJBTWROVTdteU5zQndnSEhPZVFxOW9KTHAvTTBrVk5nSHhOeVkKIyBaWGl1OWt4Y2x0QXkrVVVNcTQ2ZGJHTVVxd1RZNkdsWm9zL05Nb3B4MzFtVmY3aDdWNk55VkU1ZldqUW5jNlViCiMgTzBmeUtNaUNnaWxZOEJ0WFpXa1lSMSsyVW82ZEluQkkyUmlhdWFXbHRaND0KIyAtLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX1dFQl9DQV9CVU5ETEVfU1RPUAojIE9WUE5fQUNDRVNTX1NFUlZFUl9JU19PUEVOVlBOX1dFQl9DQT0xCiMgT1ZQTl9BQ0NFU1NfU0VSVkVSX09SR0FOSVpBVElPTj1PcGVuVlBOLCBJbmMuCnNldGVudiBGT1JXQVJEX0NPTVBBVElCTEUgMQpjbGllbnQKc2VydmVyLXBvbGwtdGltZW91dCA0Cm5vYmluZApyZW1vdGUgMTcyLjI2LjEuMjI2IDExOTQgdWRwCnJlbW90ZSAxNzIuMjYuMS4yMjYgMTE5NCB1ZHAKcmVtb3RlIDE3Mi4yNi4xLjIyNiA0NDMgdGNwCnJlbW90ZSAxNzIuMjYuMS4yMjYgMTE5NCB1ZHAKcmVtb3RlIDE3Mi4yNi4xLjIyNiAxMTk0IHVkcApyZW1vdGUgMTcyLjI2LjEuMjI2IDExOTQgdWRwCnJlbW90ZSAxNzIuMjYuMS4yMjYgMTE5NCB1ZHAKcmVtb3RlIDE3Mi4yNi4xLjIyNiAxMTk0IHVkcApkZXYgdHVuCmRldi10eXBlIHR1bgpucy1jZXJ0LXR5cGUgc2VydmVyCnNldGVudiBvcHQgdGxzLXZlcnNpb24tbWluIDEuMCBvci1oaWdoZXN0CnJlbmVnLXNlYyA2MDQ4MDAKc25kYnVmIDEwMDAwMApyY3ZidWYgMTAwMDAwCmF1dGgtdXNlci1wYXNzCiMgTk9URTogTFpPIGNvbW1hbmRzIGFyZSBwdXNoZWQgYnkgdGhlIEFjY2VzcyBTZXJ2ZXIgYXQgY29ubmVjdCB0aW1lLgojIE5PVEU6IFRoZSBiZWxvdyBsaW5lIGRvZXNuJ3QgZGlzYWJsZSBMWk8uCmNvbXAtbHpvIG5vCnZlcmIgMwpzZXRlbnYgUFVTSF9QRUVSX0lORk8KCjxjYT4KLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN1RENDQWFDZ0F3SUJBZ0lFWWlJRlBUQU5CZ2txaGtpRzl3MEJBUXNGQURBVk1STXdFUVlEVlFRRERBcFAKY0dWdVZsQk9JRU5CTUI0WERUSXlNREl5TlRFeU1qVXpNMW9YRFRNeU1ETXdNVEV5TWpVek0xb3dGVEVUTUJFRwpBMVVFQXd3S1QzQmxibFpRVGlCRFFUQ0NBU0l3RFFZSktvWklodmNOQVFFQkJRQURnZ0VQQURDQ0FRb0NnZ0VCCkFOQjlJRGtOdkFpdVpYNlJaekRsYys1bDJLSVBVWkd0ZGR2b0pRdktFUElWR1A0TlprcTArWitZcGRVTU1lSVUKaHpxRXYwRExMMUY3aE1IQlRSNHlZQU0wSjd3ZDNYaWIxbHBqNndoQ21GS1h4RHc5V0t2SEg3dFNXcDBhcXR2eQpFaVFrcSs2TFZrV0V5c1B2OGNORGpVZ3VETFc3bGNtdDMzNUR2SVhMenFnZE5mVTdEcTUwdVB0TlAvYXlMSDVhCjdmSHBRK2J6aTUxNkNtMGx0SmVtNWx3bEtOS2cyMTBTTExzRWg5Y1gvTWVqcUE3OGFCYUpqUHI2VEFKR2xKQWQKQ00ySFlBMmdJNWgzWFRCamZjWWFLcUFlanlJNnNpekkwcUcwVk13YWhueWRlalhPS25XRUVxVTdualBQMjZ4YQorU3k0OXh0MmE4ZHlUTXNCNHdGV2NTRUNBd0VBQWFNUU1BNHdEQVlEVlIwVEJBVXdBd0VCL3pBTkJna3Foa2lHCjl3MEJBUXNGQUFPQ0FRRUF4YjZPWEpFUktaRVV3OVZOZkR1TEtMVFc4VUNOcWFFTkZXbXYyN2FUSmJFcUFVVWoKMCs5WFpIRklZdWVBWVJXM1VpaExlaFJSZnhYRVB5Tm9zclRkVXYraEZjaHl0T0lUMVRldFBpbjB1Wi9jUzJmbQpBQ3RJcDRnQWRHeWtiOXBTYUhBL0RENXcxUThBOU9qWmJBYmFNUVlIMWM1OTNJV3ZvMWtZaWFwN3pNamUxRHUvCkswS01idDNRK3FKck95S2VHajA2T21TN2xTUkxPU0svSm0wQkhrWm5jc01Fb0EwVk9KcmkvaUtuRUNlMlk2SEEKUW4xNnU0QmQySVR6Y0hSYk1zQUdSd3l3eFJEUXo4Ky9EUDlMNGJEUGcwbms2UjBCeURIejNyQnc2WkpHNGtCbQpBVXpKQTNSTlNyTnFmbjh2dmpMcFNGZWFVdDBuWk9EaXJicmNZUT09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KPC9jYT4KCjxjZXJ0PgotLS0tLUJFR0lOIENFUlRJRklDQVRFLS0tLS0KTUlJQ3ZqQ0NBYWFnQXdJQkFnSUJBakFOQmdrcWhraUc5dzBCQVFzRkFEQVZNUk13RVFZRFZRUUREQXBQY0dWdQpWbEJPSUVOQk1CNFhEVEl5TURJeU5URXpNall6TTFvWERUTXlNRE13TVRFek1qWXpNMW93RGpFTU1Bb0dBMVVFCkF3d0RiM1p2TUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUExam02MjdadW1QQ0MKT2t2cjQrWGlCMTVra1Z4YmNNdFk0NWl4bmxXc01QZkZRdmlsQkRtaU9JcUcrS2t1N0VMTWtDdTRTU0c3VkZNbApBZmNnMEFia2h2STF1UUxzSlNoNDlsTXluamRTSTk0K1BuQUVVcldMZk9LcW4xaGlzZ0I1UDR0TGVIeVF4T3B0Ck1XaDRmQm9mWHN0enZLZHBIbnB6Y1FrRkp1NGIweUlqbllkUkZwa3JrekFwc1VjdnBjYUc2OGFxS2lSK1hiOXYKTnhVdTg4LytSY3owbThsN09KOG5DbjhqTFNVOVBtZm03aExWekNxRmlpL2J3Y2YxU250NXo5SzNtUmJ2dXpjNgpLeHl1TnBDZncxZ0svWllrSzBPS2kwUGlHOFZOd3dZYmdkV2swUURhNi9zeUxLMCtNZWpZYWpUY1k5M1YxUGlGCmY3Wm8raGYzNXdJREFRQUJveUF3SGpBSkJnTlZIUk1FQWpBQU1CRUdDV0NHU0FHRytFSUJBUVFFQXdJSGdEQU4KQmdrcWhraUc5dzBCQVFzRkFBT0NBUUVBVVdjNTh4eUFGeWFXYm9DK2JkbUIyZlZKRnhKdFpLSnBXWCtJNlhQYgpQT2NndnNrVUIyMkk1Zi9RZXFBNncxWGRXTU1vUE5aVnBXcjlnM05UT1VvQmFidWhHai9xakNJYXFWUjR5N0RJCmhSWldwZmNPaW1yR0FUeDlobWN3VFFUdkw2L3pGdDV1VTAreVJFaC9LcUFkckN0YUIyLzQyV3QyN0krQktqL24KM3dTZEFvbFdZVG1aYnM1em5CTmwxdDZlUXFYbi9COVNqUWdZWmw2Tld0NkhBdEdFQjNicWZLWFNidGM2NmhTYwp1Qm4wa2trTW9yeDBsWDdZaWYrb1JpOXRoU3psSytxdVQ4R0x3eEZEcDA0ZmkwemhZNFl1bkZIMFlaUFAvTWZ6ClNOS1l2anFJUVE1d1E5RWQ0ekpIYTF2cTN6SDRtVU1ZZ2RkaDVPMHJXQ0MveGc9PQotLS0tLUVORCBDRVJUSUZJQ0FURS0tLS0tCjwvY2VydD4KCjxrZXk+Ci0tLS0tQkVHSU4gUFJJVkFURSBLRVktLS0tLQpNSUlFdmdJQkFEQU5CZ2txaGtpRzl3MEJBUUVGQUFTQ0JLZ3dnZ1NrQWdFQUFvSUJBUURXT2JyYnRtNlk4SUk2ClMrdmo1ZUlIWG1TUlhGdHd5MWpqbUxHZVZhd3c5OFZDK0tVRU9hSTRpb2I0cVM3c1FzeVFLN2hKSWJ0VVV5VUIKOXlEUUJ1U0c4alc1QXV3bEtIajJVektlTjFJajNqNCtjQVJTdFl0ODRxcWZXR0t5QUhrL2kwdDRmSkRFNm0weAphSGg4R2g5ZXkzTzhwMmtlZW5OeENRVW03aHZUSWlPZGgxRVdtU3VUTUNteFJ5K2x4b2JyeHFvcUpINWR2MjgzCkZTN3p6LzVGelBTYnlYczRueWNLZnlNdEpUMCtaK2J1RXRYTUtvV0tMOXZCeC9WS2UzblAwcmVaRnUrN056b3IKSEs0MmtKL0RXQXI5bGlRclE0cUxRK0lieFUzREJodUIxYVRSQU5ycit6SXNyVDR4Nk5ocU5OeGozZFhVK0lWLwp0bWo2Ri9mbkFnTUJBQUVDZ2dFQkFNN2RQbUJ1SVF4VXF4eUtOY2FETlNteWIrQ2lVN1p1MW00cEE5T0duVmxICjJWZWJiUlhRWmFLOXVpb2lqU29lTXhWQThwckVGUFlQdDl2Vy9QdUV2R2JIT3pObDdBelJzVVVFQUF3aUZaS0gKU0luWWQ0UTZ4UENhblBKMFVoSGJQVG9zVTN1TXBldFJDSkkrZEtJNlEzS3hlaGlCZkpPdTRRMFZEY0dUQ3BGcwpVSkRmN09FT0tsZXUvNHdWbDNyTzUyWnEzY2tHdGZxODg1TEJoSTRDaUpaWklZMjJXSTN2WG9ZdWFJdEllOVozCnJjSG1FbkkwaWhtdk9ldVQyK3Z1SHhrbk1tVjY4VkFsWDBPVDBoN1FmSFA0QlJDelcyNHJ1MFpjc1htQnhlUnkKcUFXZnI5eDBSRWxtRGJFdlVmRXIybDBjZU41SHBwUDhIYmMrMlBsTXdSRUNnWUVBOEk2ZDdwdlFOUWx3NjhNQQpLNk1SdzhZNW5KRVBIL1c2Ym5JWldaR2RoM2l3TGFSY3JJUS92VkhPeGJ3cnFHKzdIdkRlaDFiWmovYXpTTkptCnU2MUpoVTA4MUhVRE9OZnpjYnViUkcyckRBSm1tRHhDUUJmRFZGOVNPUXd0WnMxcys2MkQwNDRUVmMwT3FIblUKK3VGVmRrOWpNNDAyRzFvbStrRmp4SDAxZHBrQ2dZRUE0L3BmU25pem1VanM3V2t2bTU5dGJLclJteTRlVlRqUAorejJwNEczS1VHcTM0ZVpvUlk0a1U3aXhlRytsNHNFYis0NExDa0pkK3NIUnBWMmk3ZGt6aTNXYWNKOXlKNEJpCnAzbTlVTTZpYS8zY29hNDRkYjdXblhna3RoMHJCQ0RiK0IvcTFrWGFHcWdmbG4wUlpJY2dQeTNBU3lrekJHSUMKdHVYUHpjOFNjbjhDZ1lFQWpJTXh1ek9tWGFTRElpT0lVUFR5cG9GK0czY2I5NVlvYk9VVzY1dkVBV0s4dmh4WQp5YWlDTnNxM1ZnY0JGV1VXVHc5eFhHcWRzSnJ3eEdPcUFJeEsrcU5RR2VXem1SdURKdmJuemdPbE91R1lIZXBzCjVGVTlFbWFQZDZVbVMvdElZb1pMRDJMWTVuQmQxSWs5bjhISmtzN3lhaVZjNm9NeGExS1F2VEJKNzFrQ2dZQlUKOHFJM09hcVNYMTRKU0x4NG5IdEZscERyNWM5ZnFmKzFlbENtVThLakhHRFFSKzVxbklCa3dkay9LenNBdHp3YQpDOStKUHhtTnFsTFg3NEFhYUdpUWVvM0ZrV1FUMi83bXNMSWVQaUMvWktTbGlpbDNsbGlaN0g2aGJWVHVBT0IyCklFNTg4U0pIOUlWd3FjR2xWOFJvUmovMHdiRkUzTkJ1SGt2RVFIaDdPUUtCZ0hmWDJaZHNCU3Vpc2ZERlVPQXkKaVlnSXRtUGNLVDBsbHlQWll1Ym53Qyt1NFhZMXJzM1AySmFWb2JSbDNJSzMySmpJa2svbTFUV1AvbXJEc1pyYgo4dCtnTFNjeUVpZFFuUEpNT21icnNQejJmV2FmWUFiSDNNTGEwVWl1NklHM0xZUHd0MVlhRUVEZEFNQjIzQTU3CjJUYjJVa3UyL21ESXRaMEM1c1gwMGZqWAotLS0tLUVORCBQUklWQVRFIEtFWS0tLS0tCjwva2V5PgoKa2V5LWRpcmVjdGlvbiAxCjx0bHMtYXV0aD4KIwojIDIwNDggYml0IE9wZW5WUE4gc3RhdGljIGtleSAoU2VydmVyIEFnZW50KQojCi0tLS0tQkVHSU4gT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KNjAzMDhkMmFiMzRmYjE1ZDczYWE2MzNhNzY1N2I5OTIKYjJmOTEzMDU4YTA5MjBkOGRhYWE0YjNiNTU1NmZjOTUKNzhkMjRlMTk2ZGM5NWUwNmUwMmU3MzQ1YmQwZDRkOWQKYjk0ZmFjY2VjODBhYTU4ODk4OTNkNTY3NDg2ODZkMWEKYTAzMWQ5N2Y1OWQwOTZkNDUxOTNlM2RmMzkzODUxYjYKMjU0OWYzZmI2YTNhYTBmOTg0Y2Y2ZjA5NjM0NzliNWEKYzEzNDNjYmQ4ZTI4NGJjMDNiOTdjYTBjM2U2YzM0YzYKYTBlZjJmMmRlODdlODYxNTMwZTlhZmJhYWUwZDQyYTgKYmQ0YWU5NTU2YjNlOTA1MmJmN2Y4NGRmMWIwZGNiYTAKZDg3YmM4Y2NjYjVlZTk4MDJjOTU0ZGYwYTk5MjNhNGQKMzc4ZTdlNzMwYTlhZjcxNDE4MzYyN2U3ZDA4OGU1YTAKMjVhZTE0MjMzNmRjYjA4MWRiODIxYzY0ZmIzMTAwOTAKYWJhMGFiZjJjYThkZWE1M2UzMDYyMzVjYWE3MjA0ZWQKOTM2NDllYzYxOWI0ZjNhMzQxZGQzZDhlMzM1MDdiM2EKOWZhOWU3ZjM4N2E1ZTYwNWE0YWJjOGY5NzljYzk3OWUKMGU5MzdlOGFkNjBlNjhjMmE3NjE4NWIyYWY3M2QzNTQKLS0tLS1FTkQgT3BlblZQTiBTdGF0aWMga2V5IFYxLS0tLS0KPC90bHMtYXV0aD4KCiMjIC0tLS0tQkVHSU4gUlNBIFNJR05BVFVSRS0tLS0tCiMjIERJR0VTVDpzaGEyNTYKIyMgb2s1bndhSHJYb2RBTlJjekNJME93MW1QQWJGak5QNEkvRFJwT2FTaEhTMzNZT04yV2EKIyMgUHJTMmpDK3B2cmMxdjdEcXFBbmRoNGZKdjkvNHBONUVPNFpSRnpZOEJyT24yQ2xCVU8KIyMgUGVQRXllcldkQmFCTVdsaTFLeE5YaXZ0YTBBTEgzVlpoY3hRT2VYMk16Qk1BUlN5Z2oKIyMgWmVSVFJzRGt5M2R5TzNQdTEvSGVWaUVITllubmp0QXlSeGd1NU00MmFLMytlZlpwU20KIyMgU1FyQ3pVUFVMU3ZKbzBWd3p1Nm1UMUpkV1d5UmNYWDVjMFBRc05vZTA1OHpVNzgvaWQKIyMgb01pM3I1VnZWWFJJN2JOclJ6S2xHdERKc2M3dGpxbDB5amhtNHM1dVJsQzJPaE8xeHoKIyMgV3JYck0rTG40dWZQelN5enQ4SUkvMit0enloelloTld1QnVaRWFTVzVnPT0KIyMgLS0tLS1FTkQgUlNBIFNJR05BVFVSRS0tLS0tCiMjIC0tLS0tQkVHSU4gQ0VSVElGSUNBVEUtLS0tLQojIyBNSUlESFRDQ0FnV2dBd0lCQWdJRVlpSUZQekFOQmdrcWhraUc5dzBCQVFzRkFEQkhNVVV3UXdZRFZRUURERHhQCiMjIGNHVnVWbEJPSUZkbFlpQkRRU0F5TURJeUxqQXpMakEwSURFeU9qSTFPak0wSUZWVVF5QnBjQzB4TnpJdE1qWXQKIyMgTVMweU1qWXVZMkV0WTJVd0hoY05Nakl3TWpJMU1USXlOVE0wV2hjTk16SXdNekF4TVRJeU5UTTBXakE0TVRZdwojIyBOQVlEVlFRRERDMXBjQzB4TnpJdE1qWXRNUzB5TWpZdVkyRXRZMlZ1ZEhKaGJDMHhMbU52YlhCMWRHVXVhVzUwCiMjIFpYSnVZV3d3Z2dFaU1BMEdDU3FHU0liM0RRRUJBUVVBQTRJQkR3QXdnZ0VLQW9JQkFRRENvY2VkTHdXR25WUVIKIyMgOHZ5MDNkQzduclZNUllLeDRyQ1NmaDNVTFpMeHVVYW1kdHg0bkVndFdILzRZSjFTY1hDTXcweUgrUlFWVVVGQQojIyBjU3hvYlo1YzZEeGpqREp2SmJqSDg2cmYwNGJ4T093bzJOcVdCQnc3NmZYM3hkNjlhbGlzRkJKNnlrMjhsTS9uCiMjIGlOZEpYd0VWb1VXR1RRV2wzYmJDUDRuNWNhNWF0TFpRaWk1ZDN1OEIySzJyaGpnUGk5K2UwMEQrNEFKUU1sMVIKIyMgT2UwTUNMYW5CSkZnTTRkTXh2bWJSKzBuaWNlVFRST3lnMlo0Uy9SOEx4N1J4eXdrWkdMRzhrV0lOUnRhdlVOSQojIyA4c2lXR3NFWEpxYm9UUlBsYnJ0NHNzaUN3MjduS0Nwd0NRVE84bE5MZ2c0MTMxbkZrSnFvSU04ZjN4Rk4veWluCiMjIE82WThRS2d0QWdNQkFBR2pJREFlTUFrR0ExVWRFd1FDTUFBd0VRWUpZSVpJQVliNFFnRUJCQVFEQWdaQU1BMEcKIyMgQ1NxR1NJYjNEUUVCQ3dVQUE0SUJBUUNFNmtyWTdDRmdFZDRiWEx0WE1FZVRIZGs2a2pPdEN5YmFUM1NlKzRMWgojIyBaMEd3cWJzaEtmNXpxZC9wSWpmQXQxV1lnOHc1WEs1N2hKWmIzQ1lydyt6QkN0LyswdHMzbU0rOFdneE4zSnNzCiMjIFVRODNDUHVWWUJ0T2NCWUthNVF6NzRSQ29TbThvRGlIS1orNEhMQk1rUlAwNkRJbG9DNDNqbFh4dWlvTlhGajgKIyMgVFViYW9ZbFl4MzE0ZXBWcTYzQ1Y3V2pyc0FoSFpoYVRxb3pFSFR5cGtRV0tNY1VqNExtM2k3Y2FVVW5DMTRwVQojIyB5RGplQVo2eG5uYTgyL1NOLzlNTlI0dkNHUms5azFuT3c1cE1nUzdTblNIVzJXN05Bb21qL3lUYXBDM1d4SnNECiMjIGh1aXk1SUg3NG1SK2x5L3BIbGN6N3lRT1VjdXE5STVIZnZUUFhHemI3RytMCiMjIC0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0KIyMgLS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCiMjIE1JSURIRENDQWdTZ0F3SUJBZ0lFWWlJRlBqQU5CZ2txaGtpRzl3MEJBUXNGQURCSE1VVXdRd1lEVlFRREREeFAKIyMgY0dWdVZsQk9JRmRsWWlCRFFTQXlNREl5TGpBekxqQTBJREV5T2pJMU9qTTBJRlZVUXlCcGNDMHhOekl0TWpZdAojIyBNUzB5TWpZdVkyRXRZMlV3SGhjTk1qSXdNakkxTVRJeU5UTTBXaGNOTXpJd016QXhNVEl5TlRNMFdqQkhNVVV3CiMjIFF3WURWUVFERER4UGNHVnVWbEJPSUZkbFlpQkRRU0F5TURJeUxqQXpMakEwSURFeU9qSTFPak0wSUZWVVF5QnAKIyMgY0MweE56SXRNall0TVMweU1qWXVZMkV0WTJVd2dnRWlNQTBHQ1NxR1NJYjNEUUVCQVFVQUE0SUJEd0F3Z2dFSwojIyBBb0lCQVFEQ3N0Q2JDZzhwY3ZLeG9oOE5LOXl3WWQ2S1ozNUxzTnU3c2FhSzhzNWtaYnl0MXVDL0JtSDJXUTlCCiMjIEVrdmF5eUxMWWx0YWlPTlBSM08xckZnczEyb2lXUHplSzZBL0Z2aVRDWlhOa2QwWU9DSk9jZW1XTi9GUXFuSUkKIyMgREVLZGdWUm41SmNneERwSzBuRTlxSXpMSldaQkloSFBXeXVvdHZBRGtaRTVScTJJVWtlWm4yOHd0NlhpMS9XOQojIyA3dHNHS01iUC81ZUNPTFR6Qm1uU3dOWHlqaEs1OUZvNm5PQ2MxOFBFTFpFNE9WcjlvRXlKYXdkdm9XUEFTZDZ3CiMjIEZ5Z3N4emtkZjVrTDVFcnc0bEwxc01tSmR0RDJlQUlyZWpyNVZRYnptUGlWaS9nSlkwTE9tOHZaVVFHL3JuS0cKIyMgNEVVdk0rSitzRFYwOFUzUFViWVFMNUI2WkhjTkFnTUJBQUdqRURBT01Bd0dBMVVkRXdRRk1BTUJBZjh3RFFZSgojIyBLb1pJaHZjTkFRRUxCUUFEZ2dFQkFFc0hwd2pzeVJ1U3dKOHl1TUgwNXhsNjVMbU02cjJ6ZTRKdWo0enhib0pLCiMjIENidWppRm1hWUxKaXFyY2c3dEx6MFhrUGN1Q1RpYlZ0eFFiS1hyWklOK0lXSmtOanhpdXFzdFBSZmFuLy9mY3IKIyMgenNnM0RoazF1ZFlLYXZvb2NGQkd2N0dOYy8zMDJqL2gwa080clBDWHVnM0Y1aTJnLzhjU2k2S1M1WTdzWTJJZAojIyBiYjZZdVVoWndlbk56bGdVZ2lPN05mSkl6VHpSQU1kTlU3bXlOc0J3Z0hIT2VRcTlvSkxwL00wa1ZOZ0h4TnlZCiMjIFpYaXU5a3hjbHRBeStVVU1xNDZkYkdNVXF3VFk2R2xab3MvTk1vcHgzMW1WZjdoN1Y2TnlWRTVmV2pRbmM2VWIKIyMgTzBmeUtNaUNnaWxZOEJ0WFpXa1lSMSsyVW82ZEluQkkyUmlhdWFXbHRaND0KIyMgLS0tLS1FTkQgQ0VSVElGSUNBVEUtLS0tLQo=",
            //     //   "username":"ovo",
            //     //   "password":"12345"
            //     // }).then((value) {
            //     //   print(value.id);
            //     // });
            //   },
            //   child: const Icon(
            //     Icons.settings_sharp,
            //     color: Colors.black,
            //   ),
            // ),
          ],
        ),
      ),
      body: Column(children: [
        //
        GetBuilder<VpnController>(
            init: VpnController(),
            builder: (controller) {
              return Card(
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    children: [
                      //
                      Positioned(
                        left: 20,
                        top: 5,
                        bottom: 5,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const SizedBox(
                              height: 15,
                            ),
                            Container(
                              padding: const EdgeInsets.all(5.0),
                              height: 80,
                              child: Image.asset(
                                (stage.toString() ==
                                        VPNStage.connected.toString())
                                    ? "assets/icon/vpn.png"
                                    : "assets/icon/vpn_off.png",
                              ),
                            ),
                            Column(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.north_sharp,
                                      size: 15,
                                    ),
                                    Text(
                                        "Up     : ${status!.byteOut.toString()} bytes"),
                                  ],
                                ),
                                const SizedBox(
                                  height: 3,
                                ),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.south_sharp,
                                      size: 15,
                                    ),
                                    Text(
                                        "Down: ${status!.byteIn.toString()} bytes"),
                                  ],
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      Positioned(
                        right: 20,
                        top: 10,
                        bottom: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            controller.haveVpn
                                ? Column(
                                    children: [
                                      const SizedBox(
                                        height: 15,
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 10, right: 5),
                                        child: Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.start,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Image.asset(
                                                "assets/flag/${controller.vpn!.cod ?? "US"}.png",
                                                height: 35),
                                            const SizedBox(
                                              height: 10,
                                            ),
                                            Text(
                                                (stage.toString() ==
                                                            VPNStage
                                                                .disconnected
                                                                .toString() ||
                                                        stage.toString() ==
                                                            "null")
                                                    ? "Disconnected"
                                                    : stage!.name.toString(),
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.red)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : Container(),
                            const SizedBox(
                              height: 12,
                            ),
                            Center(
                              child: GestureDetector(
                                onTap: () {
                                  if (controller.haveVpn == true) {
                                    if (_granted == null) {
                                      engine
                                          .requestPermissionAndroid()
                                          .then((value) {
                                        setState(() {
                                          _granted = value;
                                        });
                                      });
                                    }
                                    if (stage.toString() ==
                                        VPNStage.connected.toString()) {
                                      engine.disconnect();
                                    } else {
                                      initPlatformState(vpn: controller.vpn!);
                                    }
                                  } else {
                                    Get.toNamed(VPNRoute.serverlist);
                                  }
                                },
                                child: Container(
                                  height: 38,
                                  width: 140,
                                  padding: const EdgeInsets.all(5),
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    color: (stage.toString() ==
                                                VPNStage.disconnected
                                                    .toString() ||
                                            stage.toString() == "null")
                                        ? Colors.grey.shade400
                                        : (stage.toString() ==
                                                VPNStage.connected.toString())
                                            ? Colors.green.shade400
                                            : Colors.green.shade200,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        (stage.toString() ==
                                                    VPNStage.disconnected
                                                        .toString() ||
                                                stage.toString() == "null")
                                            ? "Connect Now"
                                            : (stage.toString() ==
                                                    VPNStage.connected
                                                        .toString())
                                                ? "Connected"
                                                : (stage.toString() ==
                                                        VPNStage.wait_connection
                                                            .toString())
                                                    ? "Wating..."
                                                    : (stage.toString() ==
                                                            VPNStage
                                                                .vpn_generate_config
                                                                .toString())
                                                        ? "Generate VPN"
                                                        : "Wating...",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500),
                                      ),
                                      const SizedBox(
                                        width: 10,
                                      ),
                                      Icon(
                                        Icons.circle,
                                        size: 10,
                                        color: (stage.toString() ==
                                                    VPNStage.disconnected
                                                        .toString() ||
                                                stage.toString() == "null")
                                            ? Colors.grey.shade800
                                            : (stage.toString() ==
                                                    VPNStage.connected
                                                        .toString())
                                                ? Colors.green.shade800
                                                : Colors.white,
                                      )
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
        GestureDetector(
          onTap: () {
            if (stage.toString() == VPNStage.connected.toString()) {
              engine.disconnect();
            } else {
              Get.toNamed(VPNRoute.serverlist);
            }
          },
          child: Card(
            child: SizedBox(
              height: 45,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: const [
                  Icon(Icons.location_on),
                  SizedBox(
                    width: 10,
                  ),
                  Text(
                    "Pick Your Server",
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ),
      ]),
    );
  }
}
