import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;
import '../models/rewards.dart';
import '../services/rewards_service.dart';
import '../providers/language_provider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen> {
  final RewardsService _rewardsService = RewardsService();
  late Future<UserRewards> _userRewardsFuture;
  late String _userId;
  int _swapCoinsBalance = 0;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = supabase.Supabase.instance.client.auth.currentUser!.id;
    _userRewardsFuture = _rewardsService.getUserRewards(_userId);
    _loadRewardsData();
  }

  Future<void> _loadRewardsData() async {
    try {
      final supabaseClient = supabase.Supabase.instance.client;
      final user = supabaseClient.auth.currentUser;

      if (user != null) {
        // Get wallet balance
        final walletResponse = await supabaseClient
            .from('user_wallets')
            .select('swap_coins_balance')
            .eq('user_id', user.id)
            .single();

        // Get transaction history
        final transactionsResponse = await supabaseClient
            .from('wallet_transactions')
            .select()
            .eq('user_id', user.id)
            .order('created_at', ascending: false);

        setState(() {
          _swapCoinsBalance = walletResponse['swap_coins_balance'] ?? 0;
          _transactions = List<Map<String, dynamic>>.from(transactionsResponse);
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading rewards data: $e');
      setState(() {
        _isLoading = false;
      });
    }
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
    final languageProvider = Provider.of<LanguageProvider>(context);

    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(languageProvider.getTranslatedText('rewards')),
      ),
      body: RefreshIndicator(
        onRefresh: _loadRewardsData,
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Swap Coins Balance Card
              Card(
                margin: const EdgeInsets.all(16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.stars,
                        size: 48,
                        color: Colors.amber,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$_swapCoinsBalance',
                        style: Theme.of(context).textTheme.headlineLarge,
                      ),
                      const Text('Swap Coins'),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _shareApp,
                        icon: const Icon(Icons.share),
                        label: const Text('Share & Earn 100 Coins'),
                      ),
                    ],
                  ),
                ),
              ),

              // Transaction History
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transaction History',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _transactions.length,
                      itemBuilder: (context, index) {
                        final transaction = _transactions[index];
                        return Card(
                          child: ListTile(
                            leading: Icon(
                              transaction['type'] == 'earn'
                                  ? Icons.add_circle
                                  : Icons.remove_circle,
                              color: transaction['type'] == 'earn'
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            title: Text(transaction['description']),
                            subtitle: Text(
                              DateTime.parse(transaction['created_at'])
                                  .toLocal()
                                  .toString()
                                  .split('.')[0],
                            ),
                            trailing: Text(
                              '${transaction['type'] == 'earn' ? '+' : '-'}${transaction['amount']}',
                              style: TextStyle(
                                color: transaction['type'] == 'earn'
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 