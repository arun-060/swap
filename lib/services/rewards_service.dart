import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rewards.dart';

class RewardsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<UserRewards> getUserRewards(String userId) async {
    final response = await _supabase
        .from('user_rewards')
        .select('''
          *,
          transactions:reward_transactions(*)
        ''')
        .eq('user_id', userId)
        .single();
    return UserRewards.fromJson(response);
  }

  Future<void> addReferralReward(String userId, String referralCode) async {
    const int referralCoins = 100; // Reward coins for referral
    
    await _supabase.from('reward_transactions').insert({
      'user_id': userId,
      'coins': referralCoins,
      'type': 'referral',
      'description': 'Referral bonus for sharing the app',
    });

    await _updateUserCoins(userId, referralCoins);
  }

  Future<void> addPurchaseReward(String userId, double purchaseAmount) async {
    final int purchaseCoins = (purchaseAmount / 2).round(); // Half of purchase amount as coins
    
    await _supabase.from('reward_transactions').insert({
      'user_id': userId,
      'coins': purchaseCoins,
      'type': 'purchase',
      'description': 'Reward for purchase of ₹${purchaseAmount.toStringAsFixed(2)}',
    });

    await _updateUserCoins(userId, purchaseCoins);
  }

  Future<void> redeemCoins(String userId, int coins, String rewardType) async {
    await _supabase.from('reward_transactions').insert({
      'user_id': userId,
      'coins': -coins,
      'type': 'redemption',
      'description': 'Redeemed coins for $rewardType',
    });

    await _updateUserCoins(userId, -coins);
  }

  Future<void> _updateUserCoins(String userId, int coinsChange) async {
    await _supabase.rpc(
      'update_user_coins',
      params: {
        'user_id_param': userId,
        'coins_change': coinsChange,
      },
    );
  }

  Future<String> generateReferralCode(String userId) async {
    final response = await _supabase.rpc(
      'generate_referral_code',
      params: {'user_id_param': userId},
    );
    return response as String;
  }

  Future<List<RewardTransaction>> getTransactionHistory(String userId) async {
    final response = await _supabase
        .from('reward_transactions')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);
    
    return (response as List)
        .map((tx) => RewardTransaction.fromJson(tx))
        .toList();
  }
} 