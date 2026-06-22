import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

import 'brew_page.dart';
import 'brew_theme.dart';
import 'near_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const BrewApp());
}

class BrewApp extends StatefulWidget {
  const BrewApp({super.key});

  @override
  State<BrewApp> createState() => _BrewAppState();
}

class _BrewAppState extends State<BrewApp> {
  final NearService service = NearService();

  late final NearWalletController controller = NearWalletController(
    network: MyNearWalletNetwork.testnet,
    contractId: NearService.contractId,
    methodNames: const ['add_message'],
    callbackScheme: 'brew',
    keyStore: SharedPrefsKeyStore(),
    client: NearRpcClient.testnet(),
  );

  @override
  void dispose() {
    controller.dispose();
    service.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Brew · buy a NEAR builder a coffee',
      debugShowCheckedModeBanner: false,
      theme: Brew.theme(),
      home: BrewPage(controller: controller, service: service),
    );
  }
}
