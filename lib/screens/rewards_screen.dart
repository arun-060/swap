import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/rewards.dart';
import '../services/rewards_service.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardsService _rewardsService = RewardsService();
  late Future<UserRewards> _userRewardsFuture;
  late String _userId;

  @override
  void initState() {
    super.initState();
    _userId = Supabase.instance.client.auth.currentUser!.id;
    _userRewardsFuture = _rewardsService.getUserRewards(_userId);
  }

  Future<void> _shareApp() async {
    final referralCode = await _rewardsService.generateReferralCode(_userId);
    await Share.share(
      'Check out this amazing product comparison app! Use my referral code: $referralCode to get started and earn rewards! Download now: [App Link]',
      subject: 'Join me on Product Comparison App',
    );
  }

  Future<void> _redeemCoins(int coins) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Redeem Coins'),
        content: Text('Would you like to redeem $coins coins for ₹${(coins / 10).toStringAsFixed(2)}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _rewardsService.redeemCoins(_userId, coins, 'cash');
        setState(() {
          _userRewardsFuture = _rewardsService.getUserRewards(_userId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Coins redeemed successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Rewards'),
      ),
      body: FutureBuilder<UserRewards>(
        future: _userRewardsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }

          final rewards = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              children: [
                // Coins Card
                Card(
                  margin: const EdgeInsets.all(16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'Available Coins',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${rewards.coins}',
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Worth ₹${(rewards.coins / 10).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: rewards.coins >= 100
                                ? () => _redeemCoins(rewards.coins)
                                : null,
                            child: const Text('Redeem Coins'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Share Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListTile(
                    leading: const Icon(Icons.share, color: Colors.blue),
                    title: const Text('Share & Earn'),
                    subtitle: const Text('Share the app with friends and earn 100 coins'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _shareApp,
                  ),
                ),

                // Transactions
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Transaction History',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: rewards.transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = rewards.transactions[index];
                    return ListTile(
                      leading: Icon(
                        transaction.type == 'referral'
                            ? Icons.person_add
                            : transaction.type == 'purchase'
                                ? Icons.shopping_bag
                                : Icons.redeem,
                        color: transaction.coins > 0 ? Colors.green : Colors.red,
                      ),
                      title: Text(transaction.description),
                      subtitle: Text(
                        transaction.createdAt.toString().split('.')[0],
                      ),
                      trailing: Text(
                        '${transaction.coins > 0 ? '+' : ''}${transaction.coins}',
                        style: TextStyle(
                          color: transaction.coins > 0 ? Colors.green : Colors.red,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
} 