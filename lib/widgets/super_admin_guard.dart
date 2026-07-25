import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/routes/app_router.dart';
import '../core/utils/secure_logger.dart';

/// SuperAdminGuard restricts access to super-admin-only screens.
/// If a non-super-admin tries to navigate here, it redirects them and logs a security event.
class SuperAdminGuard extends StatelessWidget {
  final Widget child;

  const SuperAdminGuard({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;

        if (user == null || !user.isSuperAdmin) {
          SecureLogger.logError(
            'SECURITY VIOLATION',
            'Unauthorized access attempt to Super Admin route by user: ${user?.id ?? "Guest"}',
          );

          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Access Denied. Super Admin privileges required.'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRoutes.login);
            }
          });

          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return child;
      },
    );
  }
}
