// Pieces shared by the sign-in and registration screens.

import 'package:flutter/material.dart';

import '../../theme/palette.dart';
import '../../widgets/panel.dart';
import '../../widgets/part_plate.dart';

/// The logo plate with the tagline.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Column(
      children: <Widget>[
        const BrandMark(size: 28),
        const SizedBox(height: 14),
        Text(
          'منصة قطع الصيانة للورشات',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

/// Two tiles that choose between a workshop account and a marketer account.
class RoleSelector extends StatelessWidget {
  const RoleSelector({
    super.key,
    required this.role,
    required this.onChanged,
    required this.registering,
  });

  final String role;
  final ValueChanged<String> onChanged;
  final bool registering;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _RoleTile(
            icon: Icons.build_rounded,
            title: 'حساب ورشة / شركة',
            subtitle: registering ? 'يتطلب موافقة الإدارة' : 'تسجيل دخول الورش',
            selected: role == 'workshop',
            onTap: () => onChanged('workshop'),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _RoleTile(
            icon: Icons.campaign_rounded,
            title: 'حساب عميل / مسوّق',
            subtitle: registering ? 'تفعيل فوري' : 'تسجيل دخول المسوقين',
            selected: role == 'marketer',
            onTap: () => onChanged('marketer'),
          ),
        ),
      ],
    );
  }
}

class _RoleTile extends StatelessWidget {
  const _RoleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final Color accent = selected ? p.primary : p.muted;
    return Semantics(
      button: true,
      selected: selected,
      label: '$title، $subtitle',
      child: Material(
        color: selected ? p.primary.withValues(alpha: 0.12) : p.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? p.primary : p.line, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
            child: Column(
              children: <Widget>[
                Icon(icon, color: accent, size: 24),
                const SizedBox(height: 8),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.text, fontSize: 14, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown after a workshop signs in or registers before an admin approved the account.
class PendingApprovalCard extends StatelessWidget {
  const PendingApprovalCard({super.key, required this.message, this.title, this.onBack});

  final String message;
  final String? title;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final VoidCallback? back = onBack;
    return Panel(
      color: p.warn.withValues(alpha: 0.1),
      borderColor: p.warn.withValues(alpha: 0.45),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: <Widget>[
          Icon(Icons.hourglass_top_rounded, color: p.warn, size: 40),
          const SizedBox(height: 12),
          Text(
            title ?? 'حسابك قيد المراجعة',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.warn, fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.text, fontSize: 14, height: 1.7),
          ),
          if (back != null) ...<Widget>[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: back, child: const Text('العودة لتسجيل الدخول')),
          ],
        ],
      ),
    );
  }
}
