import 'org_owned.dart';

/// A named giving option (for example, "Zakat", "General Fund") that a kiosk
/// visitor can choose to donate toward.
class DonationCategory implements OrgOwned {
  const DonationCategory({
    required this.organizationId,
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.tagLabel = 'Give Hope',
    this.goalAmount = 10000,
    this.raisedAmount = 0,
  });

  @override
  final String organizationId;
  final String id;
  final String name;

  /// Short campaign copy shown beneath the title on donation list cards.
  final String? description;

  /// Optional hero image URL for list cards.
  final String? imageUrl;

  /// Chip label overlaid on the campaign image (e.g. "Give Hope").
  final String tagLabel;

  /// Fundraising goal in whole currency units.
  final int goalAmount;

  /// Amount raised so far in whole currency units.
  final int raisedAmount;

  /// Progress toward [goalAmount] in the range 0.0–1.0.
  double get fundingProgress {
    if (goalAmount <= 0) {
      return 0;
    }
    return (raisedAmount / goalAmount).clamp(0.0, 1.0);
  }

  /// Human-readable raised amount (e.g. "\$0", "\$1.2 K").
  String get formattedRaised => _formatCurrency(raisedAmount);

  /// Human-readable goal amount (e.g. "\$10 K").
  String get formattedGoal => _formatCurrency(goalAmount);

  /// Description for list cards; falls back to a generic line from [name].
  String get displayDescription =>
      description ?? 'Support $name and help our community thrive.';

  DonationCategory copyWith({
    String? organizationId,
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? tagLabel,
    int? goalAmount,
    int? raisedAmount,
  }) {
    return DonationCategory(
      organizationId: organizationId ?? this.organizationId,
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tagLabel: tagLabel ?? this.tagLabel,
      goalAmount: goalAmount ?? this.goalAmount,
      raisedAmount: raisedAmount ?? this.raisedAmount,
    );
  }

  factory DonationCategory.fromJson(Map<String, dynamic> json) {
    return DonationCategory(
      organizationId: json['organizationId'] as String,
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      tagLabel: json['tagLabel'] as String? ?? 'Give Hope',
      goalAmount: json['goalAmount'] as int? ?? 10000,
      raisedAmount: json['raisedAmount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'organizationId': organizationId,
      'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'tagLabel': tagLabel,
      'goalAmount': goalAmount,
      'raisedAmount': raisedAmount,
    };
  }

  static String _formatCurrency(int amount) {
    if (amount >= 1000) {
      final double k = amount / 1000;
      final String value =
          k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return '\$$value K';
    }
    return '\$$amount';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is DonationCategory &&
            runtimeType == other.runtimeType &&
            organizationId == other.organizationId &&
            id == other.id &&
            name == other.name &&
            description == other.description &&
            tagLabel == other.tagLabel &&
            goalAmount == other.goalAmount &&
            raisedAmount == other.raisedAmount;
  }

  @override
  int get hashCode => Object.hash(
        organizationId,
        id,
        name,
        description,
        tagLabel,
        goalAmount,
        raisedAmount,
      );

  @override
  String toString() =>
      'DonationCategory(organizationId: $organizationId, id: $id, name: $name)';
}
