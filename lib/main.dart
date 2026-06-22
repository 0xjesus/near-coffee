import 'package:flutter/material.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart';

import 'home_page.dart';
import 'theme.dart';
import 'near_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CoffeeApp());
}

class CoffeeApp extends StatefulWidget {
  const CoffeeApp({super.key});

  @override
  State<CoffeeApp> createState() => _CoffeeAppState();
}

class _CoffeeAppState extends State<CoffeeApp> {
  final NearService service = NearService();

  late final NearWalletController controller = NearWalletController(
    network: MyNearWalletNetwork.testnet,
    contractId: NearService.contractId,
    methodNames: const ['add_message'],
    callbackScheme: 'nearcoffee',
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
      title: 'NearCoffee · buy a NEAR builder a coffee',
      debugShowCheckedModeBanner: false,
      theme: Coffee.theme(),
      home: CoffeePage(controller: controller, service: service),
    );
  }
}
