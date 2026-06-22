import 'package:near_dart/near_dart.dart';

/// One on-chain supporter entry (a guestbook message — premium = a paid tip).
class Supporter {
  const Supporter({required this.sender, required this.text, required this.premium});
  final String sender;
  final String text;
  final bool premium;

  factory Supporter.fromJson(Map<String, dynamic> j) => Supporter(
        sender: (j['sender'] ?? '') as String,
        text: (j['text'] ?? '') as String,
        premium: (j['premium'] ?? false) as bool,
      );
}

/// All NEAR reads/writes for Brew, on testnet, via the published near_dart SDK.
///
/// Tips are settled on-chain through the canonical NEAR guestbook contract:
/// `add_message{ text }` carries the tip as its attached deposit, and
/// `get_messages` is the public supporters wall. (For mainnet you'd deploy a
/// dedicated tip contract that forwards the deposit to the creator — same SDK
/// calls, different `contractId`.)
class NearService {
  NearService() : client = NearRpcClient.testnet();

  final NearRpcClient client;

  static final contractId = AccountId('guestbook.near-examples.testnet');

  /// Latest supporters, newest first.
  Future<List<Supporter>> supporters({int limit = 12}) async {
    final total = await _totalMessages();
    if (total == 0) return const [];
    final from = (total - limit).clamp(0, total);
    final res = await client.callFunction(
      accountId: contractId,
      methodName: 'get_messages',
      args: {'from_index': '$from', 'limit': '$limit'},
      blockReference: BlockReference.finality(Finality.final_),
    );
    if (!res.isSuccess) return const [];
    final raw = res.getOrNull()!.resultAsJson();
    if (raw is! List) return const [];
    final list = raw
        .whereType<Map>()
        .map((m) => Supporter.fromJson(m.cast<String, dynamic>()))
        .toList()
        .reversed
        .toList();
    return list;
  }

  Future<int> _totalMessages() async {
    final res = await client.callFunction(
      accountId: contractId,
      methodName: 'total_messages',
      args: const {},
      blockReference: BlockReference.finality(Finality.final_),
    );
    if (!res.isSuccess) return 0;
    final v = res.getOrNull()!.resultAsJson();
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  /// Sends a tip on-chain: signs `add_message` locally with the connected
  /// function-call key, attaching the tier amount as the deposit.
  Future<RpcResult<TransactionResponse>> sendTip({
    required Account signer,
    required String near,
    required String message,
  }) {
    return signer.callFunction(
      contractId: contractId,
      methodName: 'add_message',
      args: {'text': message.isEmpty ? '🤍' : message},
      deposit: NearToken.parse(near),
    );
  }

  String explorerTxUrl(String hash) => 'https://testnet.nearblocks.io/txns/$hash';

  void close() => client.close();
}
