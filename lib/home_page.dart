import 'package:flutter/material.dart';
import 'package:near_dart/near_dart.dart';
import 'package:near_wallet_connect/near_wallet_connect.dart'
    show NearWalletController;

import 'atmosphere.dart';
import 'theme.dart';
import 'widgets.dart';
import 'creator.dart';
import 'near_service.dart';
import 'receipt_sheet.dart';

class CoffeePage extends StatefulWidget {
  const CoffeePage({
    super.key,
    required this.controller,
    required this.service,
    this.creator = Creator.jesus,
  });

  final NearWalletController controller;
  final NearService service;
  final Creator creator;

  @override
  State<CoffeePage> createState() => _CoffeePageState();
}

class _CoffeePageState extends State<CoffeePage> {
  final _msg = TextEditingController();
  int _tier = 0;
  bool _sending = false;
  bool _loadingWall = true;
  List<Supporter> _supporters = const [];

  NearWalletController get _c => widget.controller;

  @override
  void initState() {
    super.initState();
    _c.addListener(_onWallet);
    _c.init();
    _loadSupporters();
  }

  @override
  void dispose() {
    _c.removeListener(_onWallet);
    _msg.dispose();
    super.dispose();
  }

  void _onWallet() => setState(() {});

  Future<void> _loadSupporters() async {
    setState(() => _loadingWall = true);
    final list = await widget.service.supporters();
    if (!mounted) return;
    setState(() {
      _supporters = list;
      _loadingWall = false;
    });
  }

  Future<void> _send() async {
    final tier = kTiers[_tier];
    final signer = await _c.signer();
    if (signer == null) {
      _toast('Connect a wallet first');
      return;
    }
    setState(() => _sending = true);
    final res = await widget.service
        .sendTip(signer: signer, near: tier.near, message: _msg.text);
    if (!mounted) return;
    setState(() => _sending = false);

    switch (res) {
      case RpcSuccess(:final value):
        final hash = value.transaction.hash;
        await showReceipt(
          context,
          from: signer.accountId.value,
          to: widget.creator.handle,
          tier: tier,
          message: _msg.text,
          txHash: hash,
          explorerUrl: widget.service.explorerTxUrl(hash),
        );
        _msg.clear();
        _loadSupporters();
      case RpcFailure(:final error):
        _toast(error.message);
    }
  }

  void _toast(String m) {
    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(SnackBar(
        backgroundColor: Coffee.ink,
        content: Text(m, style: Coffee.body(14, color: Coffee.paper)),
      ));
  }

  @override
  Widget build(BuildContext context) {
    final connected = _c.isConnected;
    return Scaffold(
      backgroundColor: Coffee.paper,
      body: CoffeeBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 26),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 440),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Reveal(delay: _d(0), child: _header()),
                    const SizedBox(height: 18),
                    Reveal(delay: _d(1), child: _jar(connected)),
                    const SizedBox(height: 22),
                    Reveal(delay: _d(2), child: _wallHeader()),
                    const SizedBox(height: 12),
                    Reveal(delay: _d(3), child: _wall()),
                    const SizedBox(height: 26),
                    Reveal(delay: _d(4), child: _builtWith()),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Duration _d(int i) => Duration(milliseconds: 90 * i);

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _header() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Coffee.paperDeep,
            shape: BoxShape.circle,
            border: Border.all(color: Coffee.line),
          ),
          child: const Text('☕', style: TextStyle(fontSize: 26)),
        ),
        const SizedBox(height: 14),
        Text.rich(
          TextSpan(children: [
            TextSpan(text: 'buy ', style: Coffee.display(30)),
            TextSpan(
                text: widget.creator.name,
                style: Coffee.display(30, color: Coffee.terracotta)),
            TextSpan(text: ' a coffee', style: Coffee.display(30)),
          ]),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Text(widget.creator.bio,
              textAlign: TextAlign.center,
              style: Coffee.body(14.5, color: Coffee.inkSoft, height: 1.4)),
        ),
      ],
    );
  }

  // ── The jar (profile + tiers + message + CTA) ──────────────────────────
  Widget _jar(bool connected) {
    final tier = kTiers[_tier];
    return PaperCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // creator identity row
          Row(
            children: [
              _avatar(),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.creator.name,
                      style: Coffee.body(16, weight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('@${widget.creator.handle}',
                      style: Coffee.mono(12.5, color: Coffee.inkSoft)),
                ],
              ),
              const Spacer(),
              if (connected) _connectedChip(),
            ],
          ),
          const SizedBox(height: 18),
          const DashedLine(),
          const SizedBox(height: 18),
          Row(
            children: [
              const Eyebrow('Pick a treat'),
              const Spacer(),
              Text(tier.amountLabel,
                  style: Coffee.mono(13, color: Coffee.terracotta, weight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var i = 0; i < kTiers.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: _TierTile(
                    tier: kTiers[i],
                    selected: _tier == i,
                    onTap: () => setState(() => _tier = i),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          _messageField(),
          const SizedBox(height: 18),
          if (connected)
            CoffeeButton(
              label: 'Send ${tier.near} NEAR',
              icon: Icons.arrow_forward,
              loading: _sending,
              onPressed: _send,
            )
          else
            CoffeeButton(
              label: 'Connect NEAR wallet',
              icon: Icons.account_balance_wallet_outlined,
              loading: _c.busy,
              onPressed: _c.connect,
            ),
          if (!connected) ...[
            const SizedBox(height: 10),
            Text('Connect once — then tips sign locally, no more redirects.',
                textAlign: TextAlign.center,
                style: Coffee.body(12.5, color: Coffee.inkSoft)),
          ],
        ],
      ),
    );
  }

  Widget _avatar() => Container(
        width: 46,
        height: 46,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Coffee.espresso,
          shape: BoxShape.circle,
        ),
        child: Text(widget.creator.initials,
            style: Coffee.display(17, color: Coffee.paper, weight: FontWeight.w600)),
      );

  Widget _connectedChip() {
    final id = _c.account!.accountId.value;
    final short = id.length > 16 ? '${id.substring(0, 13)}…' : id;
    return GestureDetector(
      onTap: _c.disconnect,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Coffee.mint.withValues(alpha: 0.16),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Coffee.mint.withValues(alpha: 0.5)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, size: 13, color: Coffee.mintInk),
            const SizedBox(width: 5),
            Text(short, style: Coffee.mono(11, color: Coffee.mintInk, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }

  Widget _messageField() {
    return Container(
      decoration: BoxDecoration(
        color: Coffee.paperDeep,
        borderRadius: BorderRadius.circular(Coffee.rMd),
        border: Border.all(color: Coffee.line),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      child: TextField(
        controller: _msg,
        maxLength: 140,
        minLines: 1,
        maxLines: 3,
        style: Coffee.body(14.5, color: Coffee.ink),
        cursorColor: Coffee.terracotta,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'leave a message…',
          hintStyle: Coffee.body(14.5, color: Coffee.inkSoft.withValues(alpha: 0.7)),
        ),
      ),
    );
  }

  // ── Supporters wall ────────────────────────────────────────────────────
  Widget _wallHeader() {
    return Row(
      children: [
        const Eyebrow('Recent supporters'),
        const Spacer(),
        GestureDetector(
          onTap: _loadingWall ? null : _loadSupporters,
          child: Icon(Icons.refresh,
              size: 17, color: Coffee.inkSoft.withValues(alpha: 0.8)),
        ),
      ],
    );
  }

  Widget _wall() {
    if (_loadingWall) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 26),
        child: Center(
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.2, color: Coffee.terracotta),
          ),
        ),
      );
    }
    if (_supporters.isEmpty) {
      return PaperCard(
        color: Coffee.paperDeep,
        padding: const EdgeInsets.all(22),
        child: Text('Be the first to leave a tip ☕',
            textAlign: TextAlign.center,
            style: Coffee.body(14, color: Coffee.inkSoft)),
      );
    }
    return Column(
      children: [
        for (final s in _supporters)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SupporterCard(s),
          ),
      ],
    );
  }

  Widget _builtWith() {
    return Column(
      children: [
        const DashedLine(),
        const SizedBox(height: 14),
        Text('BUILT WITH THE NEAR FLUTTER SDK',
            style: Coffee.stamp(10, color: Coffee.inkSoft)),
        const SizedBox(height: 6),
        Text('near_dart · near_wallet_connect',
            style: Coffee.mono(12, color: Coffee.terracotta)),
      ],
    );
  }
}

// ── Tier tile ──────────────────────────────────────────────────────────────
class _TierTile extends StatelessWidget {
  const _TierTile(
      {required this.tier, required this.selected, required this.onTap});
  final Tier tier;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? Coffee.terracotta.withValues(alpha: 0.10) : Coffee.paperDeep,
          borderRadius: BorderRadius.circular(Coffee.rMd),
          border: Border.all(
            color: selected ? Coffee.terracotta : Coffee.line,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Coffee.terracotta.withValues(alpha: 0.16),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Text(tier.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 6),
            Text(tier.label,
                style: Coffee.body(12.5,
                    weight: FontWeight.w700,
                    color: selected ? Coffee.terracottaDeep : Coffee.ink)),
            const SizedBox(height: 2),
            Text(tier.near,
                style: Coffee.mono(12, color: Coffee.inkSoft, weight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── Supporter card ───────────────────────────────────────────────────────
class _SupporterCard extends StatelessWidget {
  const _SupporterCard(this.s);
  final Supporter s;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Coffee.receipt,
        borderRadius: BorderRadius.circular(Coffee.rMd),
        border: Border.all(color: Coffee.lineSoft),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('☕', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.sender,
                    style: Coffee.mono(12.5, color: Coffee.espresso, weight: FontWeight.w700)),
                const SizedBox(height: 3),
                Text(s.text,
                    style: Coffee.body(14, color: Coffee.ink, height: 1.3)),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Coffee.terracotta.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text('${s.amountNear} Ⓝ',
                style: Coffee.mono(11.5,
                    color: Coffee.terracottaDeep, weight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
