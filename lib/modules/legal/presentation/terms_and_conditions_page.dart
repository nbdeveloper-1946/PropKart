import 'package:flutter/material.dart';
import '../../../core/design_system/tokens/app_colors.dart';
import '../../../core/design_system/tokens/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

class TermsAndConditionsPage extends StatelessWidget {
  const TermsAndConditionsPage({super.key});

  Widget _buildMarkdown(BuildContext context, String text) {
    final lines = text.split('\n');
    final List<Widget> children = [];
    for (final line in lines) {
      if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 8),
          child: Text(
            line.substring(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ));
      } else if (line.startsWith('## ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 14, bottom: 6),
          child: Text(
            line.substring(3),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
          ),
        ));
      } else if (line.startsWith('**') && line.endsWith('**')) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line.replaceAll('**', ''),
            style: TextStyle(
              color: AppColors.brandGreenHighlight,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              fontFamily: 'Inter',
            ),
          ),
        ));
      } else if (line.trim().isNotEmpty) {
        children.add(Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Text(
            line,
            style: TextStyle(
              color: AppColors.textMuted,
              fontSize: 13,
              height: 1.5,
              fontFamily: 'Inter',
            ),
          ),
        ));
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: children,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Terms & Conditions', style: TextStyle(fontFamily: 'Inter', fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.darkSlate,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FutureBuilder<String>(
        future: DefaultAssetBundle.of(context).loadString('assets/legal/terms_v1.md'),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.brandGreen));
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(child: Text('Failed to load Terms & Conditions.', style: TextStyle(color: Colors.white)));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.l),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: AppColors.darkSlate,
                borderRadius: BorderRadius.circular(CRMBorderRadius.card),
                border: Border.all(color: AppColors.brandGreen.withOpacity(0.1)),
              ),
              child: _buildMarkdown(context, snapshot.data!),
            ),
          );
        },
      ),
    );
  }
}
