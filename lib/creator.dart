/// Who this jar belongs to, and the tip tiers. Editing this one file
/// re-skins the whole app for a different builder.
class Creator {
  const Creator({
    required this.name,
    required this.handle,
    required this.bio,
    required this.initials,
  });

  final String name; // display name, e.g. "Jesús"
  final String handle; // NEAR-ish handle shown on the page
  final String bio;
  final String initials; // avatar monogram

  static const jesus = Creator(
    name: 'Jesús',
    handle: 'jesus.near',
    bio: 'Building the NEAR × Flutter mobile stack — open source, for the community.',
    initials: 'JB',
  );
}

/// A tip tier. The amount is a NEAR decimal string (parsed with NearToken).
class Tier {
  const Tier(this.emoji, this.label, this.near);
  final String emoji;
  final String label;
  final String near;

  String get amountLabel => '$near NEAR';
}

const kTiers = <Tier>[
  Tier('☕', 'Coffee', '0.1'),
  Tier('🍕', 'Slice', '1'),
  Tier('🚀', 'Rocket', '5'),
];
