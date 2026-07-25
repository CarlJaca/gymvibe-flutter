import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../core/routes/app_router.dart';
import '../core/utils/secure_logger.dart';

/// RoleGuard restricts access to owner-only screens.
/// If a non-owner tries to navigate here, it redirects them and logs a security event.
class RoleGuard extends StatelessWidget {
  final Widget child;
  final String routeName;

  const RoleGuard({
    super.key,
    required this.child,
    required this.routeName,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.currentUser;
        
        // Check if the user exists and is actually an owner
        if (user == null || !user.isOwner) {
          SecureLogger.logError(
            'SECURITY VIOLATION', 
            'Unauthorized access attempt to owner route ($routeName) by user: ${user?.id ?? "Guest"}'
          );
          
          // Redirect to the customer main screen in the next frame to avoid build-phase navigation errors
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Unauthorized access.'),
                  backgroundColor: Colors.red,
                ),
              );
              Navigator.pushReplacementNamed(context, AppRoutes.main);
            }
          });
          
          // Return an empty/loading screen while the redirect happens
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // If they are an owner, render the requested screen
        return child;
      },
    );
  }
}
