# ☕ NearCoffee — buy a NEAR builder a coffee

A tip jar for the NEAR ecosystem, built entirely on the published **NEAR Flutter
stack**. Connect a wallet, pick a treat, leave a message — the tip settles
on-chain and prints you a receipt.

One Dart codebase → **iOS · Android · Web · Desktop**.

> **Why a platform and not "just paste your wallet"?** Sending NEAR to an address
> is a commodity. The product is the layer around it: a trusted identity page, a
> two-tap flow with preset amounts, an on-chain supporters wall, and the little
> hit of delight when your receipt prints. That's what turns a transfer into a tip.

## Built with

| Package | Role |
|---|---|
| [`near_dart`](https://pub.dev/packages/near_dart) | local ed25519 signing, Borsh, `send_tx` |
| [`near_wallet_connect`](https://pub.dev/packages/near_wallet_connect) | drop-in wallet connect → sign locally |

This whole app is ~8 files. The NEAR parts are two calls:

```dart
// read the supporters wall (a view call)
final list = await client.callFunction(
  accountId: AccountId('guestbook.near-examples.testnet'),
  methodName: 'get_messages',
  args: {'from_index': '$from', 'limit': '12'},
  blockReference: BlockReference.finality(Finality.final_),
);

// send a tip — signs locally with the connected function-call key
await signer.callFunction(
  contractId: AccountId('guestbook.near-examples.testnet'),
  methodName: 'add_message',
  args: {'text': message},
  deposit: NearToken.parse('1'), // 1 NEAR ≈ a coffee
);
```

## How tips settle

On **testnet**, tips are recorded through the canonical NEAR guestbook contract:
`add_message{ text }` carries the tip as its attached deposit, and `get_messages`
is the public supporters wall. For mainnet you'd point `contractId` at a dedicated
tip contract that forwards the deposit to the creator — same SDK calls, different
address.

## Run it

```bash
flutter pub get
flutter run -d chrome        # or any connected device
```

Edit [`lib/creator.dart`](lib/creator.dart) to make the jar yours (name, handle,
bio, tip tiers).

## Design

A warm paper receipt: cream canvas, espresso ink, a terracotta call to action, and
NEAR mint reserved for the single *settled on-chain* moment. Fraunces for display,
DM Sans for UI, Space Mono for the receipt. Deliberately the opposite of the dark
SDK demo — this is a product, with its own identity.

## License

MIT
