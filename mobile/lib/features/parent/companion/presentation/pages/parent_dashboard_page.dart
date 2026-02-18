import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../../../core/theme/app_colors.dart';

class ParentDashboardPage extends StatelessWidget {
  const ParentDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Parent Dashboard',
            style: TextStyle(color: AppColors.parentColor, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: AppColors.error),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              if (context.mounted) context.go('/auth/login');
            },
          ),
        ],
      ),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('👨‍👩‍👧', style: TextStyle(fontSize: 64)),
          SizedBox(height: 16),
          Text('Parent Companion', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
          SizedBox(height: 8),
          Text('Link your player account to get started.',
              style: TextStyle(color: AppColors.textSecondary)),
        ]),
      ),
    );
  }
}
