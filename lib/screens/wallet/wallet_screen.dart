import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:manong_application/api/manong_wallet_api_service.dart';
import 'package:manong_application/main.dart';
import 'package:manong_application/models/manong_wallet.dart';
import 'package:manong_application/theme/colors.dart';
import 'package:manong_application/utils/snackbar_utils.dart';
import 'package:manong_application/widgets/error_state_widget.dart';
import 'package:manong_application/widgets/manong_wallet_card.dart';
import 'package:manong_application/widgets/my_app_bar.dart';

class WalletScreen extends StatefulWidget {
  const WalletScreen({super.key});

  @override
  State<WalletScreen> createState() => _WalletScreenState();
}

class _WalletScreenState extends State<WalletScreen> {
  final Logger logger = Logger('WalletScreen');
  bool _isLoading = false;
  bool _isButtonLoading = false;
  String? _error;
  final String _selectedCurrency = "PHP";
  ManongWallet? _wallet;

  @override
  void initState() {
    super.initState();
    _fetchManongWallet();
  }

  void _showCreateManongWalletDialog() {
    showDialog(
      context: context,
      builder: (context) => _buildCreateManongWalletDialog(),
    );
  }

  Future<void> _createManongWallet() async {
    setState(() {
      _isButtonLoading = true;
      _error = null;
    });

    try {
      final response = await ManongWalletApiService()
          .createManongWalletService();

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('ManongWallet'),
          content: Text(response?['message'] ?? 'Wallet created successfully!'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      // Show error in a dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text('Error'),
          content: Text(_error ?? 'Something went wrong'),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );

      logger.severe('Unable to create manong wallet $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isButtonLoading = false;
        });
      }
    }
  }

  Widget _buildCreateManongWalletDialog() {
    // If nothing selected yet, default to PHP
    final displayedCurrency = _selectedCurrency;

    return AlertDialog(
      backgroundColor: Colors.white,
      title: Text('Create Your ManongWallet'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create your ManongWallet now to start taking requests!',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColorScheme.primaryDark,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              ElevatedButton(
                onPressed: () {
                  // Do nothing, or show a message
                },
                child: Text('Currency: PHP'),
              );
            },
            child: Text('Currency: $displayedCurrency'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            'Cancel',
            style: TextStyle(color: AppColorScheme.primaryColor),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColorScheme.primaryColor,
            foregroundColor: Colors.white,
          ),
          onPressed: () async {
            Navigator.pop(navigatorKey.currentContext!);
            await _createManongWallet();
          },
          child: Text('Create Wallet'),
        ),
      ],
    );
  }

  Future<void> _fetchManongWallet() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    logger.info('_fetchManongWallet started');

    try {
      final response = await ManongWalletApiService()
          .fetchManongWalletService();

      logger.info('_fetchManongWallet $response');

      if (response != null) {
        if (response['data'] != null) {
          final data = ManongWallet.fromJson(response['data']);
          logger.info('_fetchManongWallet $data');
          setState(() {
            _wallet = data;
          });
        } else {
          SnackBarUtils.showWarning(
            navigatorKey.currentContext!,
            response['message'],
          );

          if (response['message'].toString().contains('Wallet not found')) {
            _showCreateManongWalletDialog();
          }
        }
      } else {
        SnackBarUtils.showWarning(
          navigatorKey.currentContext!,
          response?['message'] ?? 'No wallet',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });

      logger.severe('Error to fetch manong wallet $_error');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Widget _buildCard() {
    return ManongWalletCard(wallet: _wallet);
  }

  Widget _buildButtonChip({
    required String title,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColorScheme.primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildCashActionButtons() {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        children: [
          _buildButtonChip(
            title: 'Cash In',
            onPressed: () {
              // open cash in dialog / page
            },
          ),
          _buildButtonChip(
            title: 'Cash Out',
            onPressed: () {
              // open cash out dialog / page
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWallet() {
    return Column(
      children: [
        _buildCard(),
        const SizedBox(height: 16),
        _buildCashActionButtons(),
      ],
    );
  }

  Widget _buildState() {
    if (_error != null) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight,
        child: const Center(child: ErrorStateWidget()),
      );
    }

    if (_isLoading) {
      return SizedBox(
        height: MediaQuery.of(context).size.height - kToolbarHeight,
        child: const Center(
          child: CircularProgressIndicator(color: AppColorScheme.primaryColor),
        ),
      );
    }

    return Padding(padding: const EdgeInsets.all(12), child: _buildWallet());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColorScheme.backgroundGrey,
      appBar: myAppBar(title: 'Wallet'),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColorScheme.primaryColor,
          backgroundColor: AppColorScheme.backgroundGrey,
          onRefresh: _fetchManongWallet,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: MediaQuery.of(context).size.height - kToolbarHeight,
              ),
              child: _buildState(),
            ),
          ),
        ),
      ),
    );
  }
}
