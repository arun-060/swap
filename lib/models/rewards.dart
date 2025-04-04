class UserRewards {
  final String userId;
  final int coins;
  final List<RewardTransaction> transactions;

  UserRewards({
    required this.userId,
    required this.coins,
    required this.transactions,
  });

  factory UserRewards.fromJson(Map<String, dynamic> json) {
    return UserRewards(
      userId: json['user_id'],
      coins: json['coins'] ?? 0,
      transactions: (json['transactions'] as List?)
          ?.map((tx) => RewardTransaction.fromJson(tx))
          .toList() ?? [],
    );
  }
}

class RewardTransaction {
  final String id;
  final String userId;
  final int coins;
  final String type; // 'referral', 'purchase', 'redemption'
  final String description;
  final DateTime createdAt;

  RewardTransaction({
    required this.id,
    required this.userId,
    required this.coins,
    required this.type,
    required this.description,
    required this.createdAt,
  });

  factory RewardTransaction.fromJson(Map<String, dynamic> json) {
    return RewardTransaction(
      id: json['id'],
      userId: json['user_id'],
      coins: json['coins'],
      type: json['type'],
      description: json['description'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
} 