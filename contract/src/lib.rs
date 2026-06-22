//! NearCoffee tip jar.
//!
//! A minimal "buy me a coffee" contract: `tip(message)` is payable — it records
//! the supporter + message + amount on-chain, then forwards the attached deposit
//! straight to the creator (the beneficiary). `get_tips` is the public
//! supporters wall. This is the piece that makes a tip *actually reach* the
//! creator, instead of just leaving NEAR in a stranger's contract.

use near_sdk::json_types::U128;
use near_sdk::store::Vector;
use near_sdk::{env, near, AccountId, NearToken, PanicOnDefault, Promise};

/// One on-chain tip, returned to the supporters wall.
#[near(serializers = [json, borsh])]
#[derive(Clone)]
pub struct Tip {
    pub account_id: AccountId,
    pub amount: U128,
    pub message: String,
    pub timestamp_ms: u64,
}

#[near(contract_state)]
#[derive(PanicOnDefault)]
pub struct Contract {
    /// Who receives the tips (the creator).
    beneficiary: AccountId,
    /// Every tip, oldest first.
    tips: Vector<Tip>,
    /// Running total forwarded to the beneficiary, in yoctoNEAR.
    total_raised: NearToken,
}

#[near]
impl Contract {
    #[init]
    pub fn new(beneficiary: AccountId) -> Self {
        Self {
            beneficiary,
            tips: Vector::new(b"t"),
            total_raised: NearToken::from_yoctonear(0),
        }
    }

    /// Leave a tip. The attached deposit is forwarded to the beneficiary and the
    /// supporter + message are recorded on the wall. Returns the new tip count.
    #[payable]
    pub fn tip(&mut self, message: String) -> U128 {
        let amount = env::attached_deposit();
        assert!(
            amount.as_yoctonear() > 0,
            "Attach some NEAR to buy a coffee"
        );
        assert!(message.len() <= 256, "Message too long (max 256 chars)");

        self.tips.push(Tip {
            account_id: env::predecessor_account_id(),
            amount: U128(amount.as_yoctonear()),
            message,
            timestamp_ms: env::block_timestamp_ms(),
        });
        self.total_raised = self.total_raised.saturating_add(amount);

        // Forward the coffee straight to the creator (scheduled on drop).
        let _ = Promise::new(self.beneficiary.clone()).transfer(amount);

        U128(self.tips.len() as u128)
    }

    /// Supporters wall, oldest first. `from_index`/`limit` paginate.
    pub fn get_tips(&self, from_index: Option<u32>, limit: Option<u32>) -> Vec<Tip> {
        let from = from_index.unwrap_or(0);
        let to = from
            .saturating_add(limit.unwrap_or(20))
            .min(self.tips.len());
        (from..to)
            .filter_map(|i| self.tips.get(i).cloned())
            .collect()
    }

    pub fn total_tips(&self) -> u32 {
        self.tips.len()
    }

    pub fn total_raised(&self) -> U128 {
        U128(self.total_raised.as_yoctonear())
    }

    pub fn get_beneficiary(&self) -> AccountId {
        self.beneficiary.clone()
    }
}
