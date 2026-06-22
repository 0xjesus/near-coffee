import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'theme.dart';
import 'widgets.dart';
import 'creator.dart';

/// The printed tip receipt. Lines cascade in like a thermal printer, then the
/// mint "PAID" stamp thumps down and the on-chain tx hash types out.
Future<void> showReceipt(
  BuildContext context, {
  required String from,
  required String to,
  required Tier tier,
  required String message,
  required String txHash,
  required String explorerUrl,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    barrierColor: Coffee.espresso.withValues(alpha: 0.35),
    builder: (_) => ReceiptSheet(
      from: from,
      to: to,
      tier: tier,
      message: message,
      txHash: txHash,
      explorerUrl: explorerUrl,
    ),
  );
}

class ReceiptSheet extends StatelessWidget {
  const ReceiptSheet({
    super.key,
    required this.from,
    required this.to,
    required this.tier,
    required this.message,
    required this.txHash,
    required this.explorerUrl,
  });

  final String from, to, message, txHash, explorerUrl;
  final Tier tier;

  String get _short =>
      txHash.length > 14 ? '${txHash.substring(0, 7)}…${txHash.substring(txHash.length - 5)}' : txHash;

  @override
  Widget build(BuildContext context) {
    int step = 0;
    Duration at() => Duration(milliseconds: 120 * step++);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: TornEdge(
            top: true,
            bottom: true,
            child: Container(
              color: Coffee.receipt,
              padding: const EdgeInsets.fromLTRB(26, 30, 26, 30),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Reveal(
                    delay: at(),
                    child: Column(
                      children: [
                        Text('NEAR ☕ COFFEE',
                            textAlign: TextAlign.center,
                            style: Coffee.stamp(15, color: Coffee.ink)),
                        const SizedBox(height: 4),
                        Text('TIP RECEIPT',
                            textAlign: TextAlign.center,
                            style: Coffee.stamp(11, color: Coffee.inkSoft)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Reveal(delay: at(), child: const DashedLine()),
                  const SizedBox(height: 16),
                  Reveal(delay: at(), child: _RLine('FROM', from)),
                  const SizedBox(height: 10),
                  Reveal(delay: at(), child: _RLine('TO', to)),
                  const SizedBox(height: 10),
                  Reveal(
                    delay: at(),
                    child: _RLine('ITEM', '${tier.emoji} ${tier.label} × 1'),
                  ),
                  if (message.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Reveal(delay: at(), child: _RLine('MEMO', '“${message.trim()}”')),
                  ],
                  const SizedBox(height: 16),
                  Reveal(delay: at(), child: const DashedLine()),
                  const SizedBox(height: 18),
                  Reveal(
                    delay: at(),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text('TOTAL', style: Coffee.stamp(12)),
                        const Spacer(),
                        Text(tier.near, style: Coffee.mono(30, weight: FontWeight.w700)),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Text('NEAR',
                              style: Coffee.mono(13, color: Coffee.inkSoft)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Center(
                    child: Reveal(delay: at(), dy: 0, child: const PaidStamp()),
                  ),
                  const SizedBox(height: 20),
                  Reveal(delay: at(), child: const DashedLine()),
                  const SizedBox(height: 14),
                  Reveal(
                    delay: at(),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('SETTLED ON NEAR TESTNET',
                            style: Coffee.stamp(10, color: Coffee.mintInk)),
                        const SizedBox(height: 8),
                        InkWell(
                          onTap: () => launchUrl(Uri.parse(explorerUrl),
                              mode: LaunchMode.externalApplication),
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text('TX  ', style: Coffee.stamp(12)),
                                Text(_short,
                                    style: Coffee.mono(13,
                                        color: Coffee.terracotta,
                                        weight: FontWeight.w700)),
                                const SizedBox(width: 6),
                                const Icon(Icons.open_in_new,
                                    size: 14, color: Coffee.terracotta),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Reveal(
                    delay: at(),
                    child: Text('thank you for the coffee  ☕',
                        textAlign: TextAlign.center,
                        style: Coffee.display(17, color: Coffee.espresso)),
                  ),
                  const SizedBox(height: 18),
                  Reveal(
                    delay: at(),
                    child: CoffeeButton(
                      label: 'Done',
                      filled: false,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _RLine extends StatelessWidget {
  const _RLine(this.label, this.value);
  final String label, value;
  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(width: 64, child: Text(label, style: Coffee.stamp(12))),
        const SizedBox(width: 10),
        Expanded(
          child: Text(value,
              textAlign: TextAlign.right,
              style: Coffee.mono(13.5, color: Coffee.ink)),
        ),
      ],
    );
  }
}
