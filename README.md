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
  accountId: AccountId('nearcoffee-jar.testnet'),
  methodName: 'get_tips',
  args: {'from_index': from, 'limit': 12},
  blockReference: BlockReference.finality(Finality.final_),
);

// send a tip — signs locally with the connected function-call key
await signer.callFunction(
  contractId: AccountId('nearcoffee-jar.testnet'),
  methodName: 'tip',
  args: {'message': message},
  deposit: NearToken.parse('1'), // 1 NEAR ≈ a coffee
);
```

## The smart contract

Tips settle through **our own tip-jar contract** (in [`contract/`](contract/), ~70
lines of Rust / near-sdk 5). `tip(message)` is payable: it records the supporter +
message + amount on-chain **and forwards the attached deposit straight to the
creator** — so a tip actually reaches them, instead of leaving NEAR in a stranger's
contract. `get_tips` is the public supporters wall.

```rust
#[payable]
pub fn tip(&mut self, message: String) -> U128 {
    let amount = env::attached_deposit();
    self.tips.push(Tip { account_id: env::predecessor_account_id(), /* … */ });
    Promise::new(self.beneficiary.clone()).transfer(amount); // → the creator
    U128(self.tips.len() as u128)
}
```

**Deployed & verified on testnet:**
- Contract: [`nearcoffee-jar.testnet`](https://testnet.nearblocks.io/address/nearcoffee-jar.testnet)
  · beneficiary `nearcoffee-creator.testnet`
- A real tip forwarded 1 NEAR to the creator:
  [`DBWiaED…EJo7`](https://testnet.nearblocks.io/txns/DBWiaEDsHidWeLKfr8vWPjLEc2xwZWRHrnERXZYfEJo7)

Build & deploy your own:

```bash
cd contract
rustup target add wasm32-unknown-unknown
cargo build --target wasm32-unknown-unknown --release
near deploy <your-account>.testnet \
  target/wasm32-unknown-unknown/release/tip_jar.wasm \
  --initFunction new --initArgs '{"beneficiary":"<creator>.testnet"}'
```

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
