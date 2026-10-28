import 'package:flutter/material.dart';
import '../../core/constants/app_constants.dart';

class MembershipHistoryScreen extends StatelessWidget {
  const MembershipHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> dummyHistory = [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Membership History'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: dummyHistory.isEmpty
          ? const Center(
              child: Text(
                'No membership history found.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(AppPadding.md),
              itemCount: dummyHistory.length,
              itemBuilder: (context, index) {
                final history = dummyHistory[index];
                final isActive = history['status'] == 'Active';
                
                return Container(
                  margin: const EdgeInsets.only(bottom: AppPadding.md),
                  padding: const EdgeInsets.all(AppPadding.md),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: isActive ? AppColors.primary : AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              history['gymName'],
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isActive ? AppColors.success.withValues(alpha: 0.2) : AppColors.surfaceElevated,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: Text(
                              history['status'],
                              style: TextStyle(
                                color: isActive ? AppColors.success : AppColors.textSecondary,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        history['type'],
                        style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            history['date'],
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          Text(
                            history['price'],
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
