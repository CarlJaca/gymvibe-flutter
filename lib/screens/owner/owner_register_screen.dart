import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/routes/app_router.dart';
import '../../providers/auth_provider.dart';
import '../../providers/gym_provider.dart';
import '../../models/gym_model.dart';

class OwnerRegisterScreen extends StatefulWidget {
  const OwnerRegisterScreen({super.key});

  @override
  State<OwnerRegisterScreen> createState() => _OwnerRegisterScreenState();
}

class _OwnerRegisterScreenState extends State<OwnerRegisterScreen> {
  final _gymNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscureText = true;
  bool _obscureConfirmText = true;

  @override
  void dispose() {
    _gymNameCtrl.dispose();
    _ownerNameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final gymName = _gymNameCtrl.text.trim();
    final ownerName = _ownerNameCtrl.text.trim();
    final email = _emailCtrl.text.trim();
    final pass = _passCtrl.text.trim();
    final confirmPass = _confirmPassCtrl.text.trim();

    if (gymName.isEmpty || ownerName.isEmpty || email.isEmpty || pass.isEmpty) return;

    if (pass != confirmPass) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final provider = context.read<AuthProvider>();
    final success = await provider.register(
      name: ownerName,
      email: email,
      password: pass,
      isOwner: true,
      gymName: gymName,
    );

    if (success) {
      if (!mounted) return;
      // Get the registered user's ID to link the gym to this account
      final userId = provider.currentUser?.id ?? '';
      
      // Create a new gym linked to this owner's account
      final newGym = GymModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        ownerId: userId,
        name: gymName,
        imageUrl: 'https://images.unsplash.com/photo-1534438327276-14e5300c3a48?w=800&q=80',
        address: 'New Location, Davao City',
        city: 'Davao',
        hours: '6:00 AM - 10:00 PM',
        rating: 5.0,
        reviewCount: 0,
        isOpen: true,
        description: 'A brand new gym registered by $ownerName.',
        facilities: ['Cardio', 'Weights'],
        monthlyPrice: '',
        sessionPrice: '',
        socials: {'Email': email},
      );
      context.read<GymProvider>().addGym(newGym);

      // Sign out immediately so owner must log in manually
      await provider.signOut();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gym Account created! Please sign in to continue.'),
          backgroundColor: Color(0xFF4CAF50),
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.ownerLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pushReplacementNamed(context, AppRoutes.ownerLogin),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppPadding.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Register Gym',
              style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Partner with Gym Vibe Davao today!',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
            ),
            const SizedBox(height: 48),

            // Gym Name
            TextField(
              controller: _gymNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Gym Name',
                prefixIcon: Icon(Icons.storefront_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Owner Full Name
            TextField(
              controller: _ownerNameCtrl,
              decoration: const InputDecoration(
                hintText: 'Owner Full Name',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
            ),
            const SizedBox(height: 16),

            // Email
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'Owner Email',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // Password
            TextField(
              controller: _passCtrl,
              obscureText: _obscureText,
              decoration: InputDecoration(
                hintText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                      _obscureText ? Icons.visibility_off : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Confirm Password
            TextField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirmText,
              decoration: InputDecoration(
                hintText: 'Confirm Password',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmText
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () =>
                      setState(() => _obscureConfirmText = !_obscureConfirmText),
                ),
              ),
            ),

            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                if (auth.errorMessage != null) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      auth.errorMessage!,
                      style: const TextStyle(
                          color: AppColors.error, fontSize: 14),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),

            const SizedBox(height: 48),
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.isLoading ? null : _handleRegister,
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Create Owner Account'),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Already have an owner account?',
                    style: TextStyle(color: AppColors.textSecondary)),
                TextButton(
                  onPressed: () =>
                      Navigator.pushReplacementNamed(context, AppRoutes.ownerLogin),
                  child: const Text('Log in'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
