class LoyaltyProgram {
  final String? id;
  final String name;
  final String description;
  final int pointsPerDollar;
  final int pointsForReward;
  final double rewardValue;
  final bool isActive;

  LoyaltyProgram({
    this.id,
    required this.name,
    required this.description,
    required this.pointsPerDollar,
    required this.pointsForReward,
    required this.rewardValue,
    this.isActive = true,
  });

  factory LoyaltyProgram.fromJson(Map<String, dynamic> json) {
    return LoyaltyProgram(
      id: json['id']?.toString(),
      name: json['name'],
      description: json['description'],
      pointsPerDollar: int.parse(json['points_per_dollar'].toString()),
      pointsForReward: int.parse(json['points_for_reward'].toString()),
      rewardValue: double.parse(json['reward_value'].toString()),
      isActive: json['is_active'] == 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'description': description,
      'points_per_dollar': pointsPerDollar,
      'points_for_reward': pointsForReward,
      'reward_value': rewardValue,
      'is_active': isActive ? 1 : 0,
    };
  }
}

class CustomerLoyalty {
  final String customerId;
  final int points;
  final String tier;
  final DateTime? lastPurchase;

  CustomerLoyalty({
    required this.customerId,
    required this.points,
    required this.tier,
    this.lastPurchase,
  });

  factory CustomerLoyalty.fromJson(Map<String, dynamic> json) {
    return CustomerLoyalty(
      customerId: json['customer_id'].toString(),
      points: int.parse(json['points'].toString()),
      tier: json['tier'],
      lastPurchase: json['last_purchase'] != null 
          ? DateTime.parse(json['last_purchase']) 
          : null,
    );
  }

  String getTierName() {
    switch (tier) {
      case 'bronze':
        return 'Bronze';
      case 'silver':
        return 'Silver';
      case 'gold':
        return 'Gold';
      case 'platinum':
        return 'Platinum';
      default:
        return 'Member';
    }
  }

  int getPointsToNextTier() {
    switch (tier) {
      case 'bronze':
        return 500 - points;
      case 'silver':
        return 1000 - points;
      case 'gold':
        return 2000 - points;
      default:
        return 0;
    }
  }
}
