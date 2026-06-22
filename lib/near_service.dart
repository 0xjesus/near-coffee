import 'package:near_dart/near_dart.dart';

/// One on-chain supporter entry from the NearCoffee tip-jar contract.
class Supporter {
  const Supporter({
    required this.sender,
    required this.text,
    required this.amountNear,
  });
  final String sender;
  final String text;
  final String amountNear; // display, e.g. "1.00"

  factory Supporter.fromJson(Map<String, dynamic> j) => Supporter(
    sender: (j['account_id'] ?? '') as String,
    text: (j['message'] ?? '') as String,
    amountNear: _yoctoToNear((j['amount'] ?? '0').toString()),
  );

  static String _yoctoToNear(String yocto) {
    try {
      return NearToken.fromYocto(yocto).toNearString(fractionDigits: 2);
    } catch (_) {
      return '0';
    }
  }
}

/// All NEAR reads/writes for NearCoffee, on testnet, via the published
/// near_dart SDK.
///
/// Tips settle through our own tip-jar contract (deployed from `contract/`):
/// `tip{ message }` records the supporter + message on-chain and **forwards the
/// attached deposit straight to the creator**; `get_tips` is the supporters
/// wall. Point [contractId] at a mainnet deployment to go live.
class NearService {
  NearService() : client = NearRpcClient.testnet();

  final NearRpcClient client;

  /// Our deployed tip-jar contract (beneficiary = nearcoffee-creator.testnet).
  static final contractId = AccountId('nearcoffee-jar.testnet');

  /// Latest supporters, newest first.
  Future<List<Supporter>> supporters({int limit = 12}) async {
    final total = await _totalTips();
    if (total == 0) return const [];
    final from = (total - limit).clamp(0, total);
    final res = await client.callFunction(
      accountId: contractId,
      methodName: 'get_tips',
      args: {'from_index': from, 'limit': limit},
      blockReference: BlockReference.finality(Finality.final_),
    );
    if (!res.isSuccess) return const [];
    final raw = res.getOrNull()!.resultAsJson();
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((m) => Supporter.fromJson(m.cast<String, dynamic>()))
        .toList()
        .reversed
        .toList();
  }

  Future<int> _totalTips() async {
    final res = await client.callFunction(
      accountId: contractId,
      methodName: 'total_tips',
      args: const {},
      blockReference: BlockReference.finality(Finality.final_),
    );
    if (!res.isSuccess) return 0;
    final v = res.getOrNull()!.resultAsJson();
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  /// Sends a tip on-chain: signs `tip` locally with the connected function-call
  /// key, attaching the tier amount as the deposit (forwarded to the creator).
  Future<RpcResult<TransactionResponse>> sendTip({
    required Account signer,
    required String near,
    required String message,
  }) {
    return signer.callFunction(
      contractId: contractId,
      methodName: 'tip',
      args: {'message': message.trim().isEmpty ? '🤍' : message.trim()},
      deposit: NearToken.parse(near),
    );
  }

  String explorerTxUrl(String hash) =>
      'https://testnet.nearblocks.io/txns/$hash';

  void close() => client.close();
}
