import 'package:flutter/foundation.dart';
import 'package:near_dart/near_dart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

const _scheme = 'nearcoffee';
const _prefKey = 'pending_tip';

/// Per-transaction MyNearWallet signing for tips.
///
/// A function-call key **cannot attach a deposit**, so a tip (which carries
/// NEAR) must be signed by the wallet's full-access key. We build the
/// transaction, redirect to MyNearWallet's `/sign`, the wallet signs + sends
/// it, and on the way back we read the resulting tx hash to show the receipt.
class WalletTip {
  WalletTip({required this.client, required this.contractId});

  final NearRpcClient client;
  final AccountId contractId;

  String get _successUrl => kIsWeb
      ? Uri.base.replace(query: '', fragment: '').toString()
      : '$_scheme://callback/success';
  String get _failureUrl => kIsWeb
      ? Uri.base.replace(query: '', fragment: '').toString()
      : '$_scheme://callback/failure';

  Future<bool> _launch(Uri uri) => launchUrl(
    uri,
    webOnlyWindowName: kIsWeb ? '_self' : null,
    mode: kIsWeb ? LaunchMode.platformDefault : LaunchMode.externalApplication,
  );

  /// Builds the tip transaction, remembers it, and hands it to the wallet.
  Future<void> requestTip({
    required Account signer,
    required String near,
    required String message,
  }) async {
    final keyRes = await client.viewAccessKey(
      accountId: signer.accountId,
      publicKey: signer.keyPair.publicKey,
      blockReference: BlockReference.finality(Finality.final_),
    );
    if (keyRes is! RpcSuccess) {
      throw StateError('Could not load the access key');
    }
    final v = (keyRes as RpcSuccess).value;
    final text = message.trim().isEmpty ? '🤍' : message.trim();

    final tx = Transaction(
      signerId: signer.accountId,
      receiverId: contractId,
      publicKey: signer.keyPair.publicKey,
      nonce: BigInt.from(v.nonce) + BigInt.one,
      blockHash: CryptoHash(v.blockHash),
      actions: [
        FunctionCallAction(
          methodName: 'tip',
          args: {'message': text},
          gas: BigInt.from(30000000000000),
          deposit: NearToken.parse(near),
        ),
      ],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _prefKey,
      [near, signer.accountId.value, text].join(''),
    );

    final adapter = MyNearWalletAdapter(
      config: MyNearWalletConfig(
        contractId: contractId,
        successUrl: _successUrl,
        failureUrl: _failureUrl,
        network: MyNearWalletNetwork.testnet,
      ),
      keyStore: InMemoryKeyStore(),
      launchUrl: _launch,
    );
    final url = adapter.buildTransactionUrl(
      transactions: [tx],
      callbackUrl: _successUrl,
    );
    await _launch(url);
  }

  /// If [uri] carries a transaction result, returns the pending tip + tx hash.
  static Future<TipResult?> parseCallback(Uri uri) async {
    final hashes = uri.queryParameters['transactionHashes'];
    if (hashes == null || hashes.isEmpty) return null;
    final txHash = hashes.split(',').first;

    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    await prefs.remove(_prefKey);

    var near = '', from = '', message = '';
    if (raw != null) {
      final p = raw.split('');
      near = p.isNotEmpty ? p[0] : '';
      from = p.length > 1 ? p[1] : '';
      message = p.length > 2 ? p[2] : '';
    }
    return TipResult(txHash: txHash, near: near, from: from, message: message);
  }
}

class TipResult {
  TipResult({
    required this.txHash,
    required this.near,
    required this.from,
    required this.message,
  });
  final String txHash;
  final String near;
  final String from;
  final String message;
}
