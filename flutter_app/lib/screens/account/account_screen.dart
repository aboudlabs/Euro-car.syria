// Account tab: profile photo, profile editing (PUT /api/auth), appearance, support and sign-out.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';
import '../../core/config.dart';
import '../../core/format.dart';
import '../../core/labels.dart';
import '../../core/models.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/panel.dart';
import '../../widgets/pickers.dart';
import '../../widgets/select_field.dart';
import '../home/tab_header.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _password = TextEditingController();
  String _city = '';

  bool _saving = false;
  bool _avatarBusy = false;
  String? _notice;
  String? _error;

  @override
  void initState() {
    super.initState();
    final AppUser? user = AppScope.read(context).user;
    if (user != null) {
      _name.text = user.name;
      _city = user.city ?? '';
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _pickCity() async {
    final String? picked = await showChoiceSheet<String>(
      context: context,
      title: 'اختر المحافظة',
      options: governorates,
      labelOf: (String value) => value,
      selected: _city.isEmpty ? null : _city,
    );
    if (picked != null && mounted) {
      setState(() => _city = picked);
    }
  }

  Future<void> _save() async {
    if (_saving) {
      return;
    }
    final String name = _name.text.trim();
    final String password = _password.text;
    if (name.length < 2) {
      setState(() {
        _error = 'الاسم يجب أن يكون حرفين على الأقل.';
        _notice = null;
      });
      return;
    }
    if (password.isNotEmpty && password.length < 4) {
      setState(() {
        _error = 'كلمة المرور الجديدة يجب أن تكون 4 أحرف على الأقل.';
        _notice = null;
      });
      return;
    }
    final AppState state = AppScope.read(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _saving = true;
      _error = null;
      _notice = null;
    });
    try {
      await state.updateProfile(name: name, city: _city, newPassword: password);
      if (!mounted) {
        return;
      }
      final AppUser? fresh = state.user;
      setState(() {
        _saving = false;
        _password.clear();
        if (fresh != null) {
          _name.text = fresh.name;
          _city = fresh.city ?? _city;
        }
        _notice = 'تم حفظ بيانات حسابك بنجاح.';
      });
    } on ApiException catch (error) {
      // The form keeps everything the user typed so they can try again.
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _error = unexpectedMessage;
      });
    }
  }

  Future<void> _changePhoto() async {
    if (_avatarBusy) {
      return;
    }
    final AppState state = AppScope.read(context);
    final ImagePickResult result = await pickPhoto(context, maxSide: 800);
    if (!mounted) {
      return;
    }
    final Uint8List? bytes = result.bytes;
    if (bytes == null) {
      final String? failure = result.error;
      if (failure != null) {
        setState(() {
          _error = failure;
          _notice = null;
        });
      }
      return;
    }
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('معاينة صورة الحساب'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            UserAvatar(name: '', bytes: bytes, size: 160),
            const SizedBox(height: 12),
            const Text(
              'ستظهر الصورة بهذا الشكل في حسابك.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('اعتماد الصورة'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    setState(() {
      _avatarBusy = true;
      _error = null;
      _notice = null;
    });
    try {
      await state.uploadAvatar(bytes);
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarBusy = false;
        _notice = 'تم تحديث صورة الحساب.';
      });
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarBusy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _avatarBusy = false;
        _error = unexpectedMessage;
      });
    }
  }

  Future<void> _openSupport() async {
    final bool opened = await openExternalUrl(supportUrl());
    if (!opened && mounted) {
      showSnack(context, 'تعذر فتح واتساب. تأكد من تثبيته على الجهاز.');
    }
  }

  Future<void> _openDeveloper() async {
    final bool opened = await openExternalUrl(developerUrl);
    if (!opened && mounted) {
      showSnack(context, 'تعذر فتح الرابط.');
    }
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (mounted) {
      showSnack(context, 'تم نسخ كود المسوّق');
    }
  }

  Future<void> _confirmLogout() async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text(
          'هل تريد تسجيل الخروج من حسابك؟ سيتم تفريغ السلة المحفوظة على هذا الجهاز.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await AppScope.read(context).logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final AppState state = AppScope.of(context);
    final AppUser? user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final String? notice = _notice;
    final String? error = _error;

    return Column(
      children: <Widget>[
        const TabHeader(
          title: 'حسابي',
          subtitle: 'إدارة بيانات حسابك وإعدادات التطبيق',
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            children: <Widget>[
              _profileCard(p, state, user),
              const SizedBox(height: 12),
              _statTiles(p, user),
              const SizedBox(height: 12),
              _editForm(p, notice, error),
              const SectionTitle('المظهر'),
              _themeSelector(state),
              const SectionTitle('المساعدة'),
              SecondaryButton(
                label: 'التواصل مع الدعم عبر واتساب',
                icon: Icons.support_agent_rounded,
                color: p.ok,
                onPressed: _openSupport,
              ),
              const SizedBox(height: 10),
              SecondaryButton(
                label: 'تسجيل الخروج',
                icon: Icons.logout_rounded,
                color: p.err,
                onPressed: _confirmLogout,
              ),
              const SizedBox(height: 10),
              Center(
                child: TextButton.icon(
                  onPressed: _openDeveloper,
                  icon: Icon(Icons.open_in_new_rounded, size: 15, color: p.muted),
                  label: Text(
                    'تطوير $developerName',
                    style: TextStyle(color: p.muted, fontSize: 12.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _profileCard(Palette p, AppState state, AppUser user) {
    final DateTime? since = user.createdAt;
    final String? city = user.city;
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 84,
            height: 84,
            child: Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                UserAvatar(name: user.name, bytes: state.avatarBytes, size: 84),
                PositionedDirectional(
                  bottom: -6,
                  end: -6,
                  child: Material(
                    color: p.primary,
                    shape: CircleBorder(side: BorderSide(color: p.bg, width: 2)),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _avatarBusy ? null : _changePhoto,
                      child: SizedBox(
                        width: 36,
                        height: 36,
                        child: _avatarBusy
                            ? const Padding(
                                padding: EdgeInsets.all(9),
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.photo_camera_rounded, size: 18, color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  user.name,
                  style: TextStyle(color: p.text, fontSize: 19, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                StatusChip(
                  label: user.isWorkshop ? 'حساب ورشة معتمد' : 'حساب مسوّق',
                  tone: StatusTone.success,
                ),
                const SizedBox(height: 8),
                Text(
                  user.phone,
                  textDirection: TextDirection.ltr,
                  style: TextStyle(color: p.muted, fontSize: 13.5),
                ),
                if (city != null && city.isNotEmpty)
                  Text(city, style: TextStyle(color: p.muted, fontSize: 13.5)),
                if (since != null)
                  Text(
                    'عضو منذ ${formatDate(since)}',
                    style: TextStyle(color: p.muted, fontSize: 12.5),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTiles(Palette p, AppUser user) {
    if (user.isMarketer) {
      final String? code = user.myRefCode;
      return Panel(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: <Widget>[
            Icon(Icons.verified_user_outlined, color: p.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('كود المسوّق', style: TextStyle(color: p.muted, fontSize: 13)),
                  Text(
                    code ?? 'غير متوفر',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(color: p.primary, fontSize: 20, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'يُستخدم هذا الكود عند تسجيل ورشة جديدة.',
                    style: TextStyle(color: p.muted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
            if (code != null)
              IconButton(
                onPressed: () => _copyCode(code),
                tooltip: 'نسخ الكود',
                icon: Icon(Icons.copy_rounded, color: p.muted),
              ),
          ],
        ),
      );
    }

    final double? limit = user.debtLimit;
    final double? used = user.debtBalance;
    final String? tier = user.tier;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: _StatTile(
              label: 'سقف دفتر الدين',
              value: limit == null ? 'غير محدد' : formatUsd(limit),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              label: 'الرصيد المستخدم',
              value: used == null ? 'غير متوفر' : formatUsd(used),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _StatTile(
              label: 'تصنيف الحساب',
              value: tier == null ? '—' : tierLabel(tier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _editForm(Palette p, String? notice, String? error) {
    return Panel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.edit_outlined, color: p.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'تعديل البيانات',
                style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          AppTextField(
            controller: _name,
            label: 'الاسم',
            icon: Icons.badge_outlined,
            maxLength: 100,
            textInputAction: TextInputAction.next,
          ),
          const SizedBox(height: 14),
          SelectField(
            label: 'المحافظة',
            value: _city,
            placeholder: 'اختر المحافظة',
            icon: Icons.location_on_outlined,
            onTap: _pickCity,
          ),
          const SizedBox(height: 14),
          PasswordField(
            controller: _password,
            label: 'كلمة مرور جديدة (اختياري)',
            hint: 'اتركها فارغة دون تغيير',
            textInputAction: TextInputAction.done,
            onSubmitted: (String value) => _save(),
          ),
          if (notice != null) ...<Widget>[
            const SizedBox(height: 14),
            NoticeBanner(message: notice, kind: NoticeKind.success),
          ],
          if (error != null) ...<Widget>[
            const SizedBox(height: 14),
            NoticeBanner(message: error, kind: NoticeKind.error),
          ],
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'حفظ التعديلات',
            icon: Icons.save_outlined,
            busy: _saving,
            onPressed: _save,
          ),
        ],
      ),
    );
  }

  Widget _themeSelector(AppState state) {
    return SegmentedButton<ThemeMode>(
      segments: const <ButtonSegment<ThemeMode>>[
        ButtonSegment<ThemeMode>(
          value: ThemeMode.dark,
          label: Text('داكن'),
          icon: Icon(Icons.dark_mode_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.light,
          label: Text('فاتح'),
          icon: Icon(Icons.light_mode_outlined),
        ),
        ButtonSegment<ThemeMode>(
          value: ThemeMode.system,
          label: Text('النظام'),
          icon: Icon(Icons.brightness_auto_outlined),
        ),
      ],
      selected: <ThemeMode>{state.themeMode},
      showSelectedIcon: false,
      expandedInsets: EdgeInsets.zero,
      onSelectionChanged: (Set<ThemeMode> selection) => state.setThemeMode(selection.first),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      child: Column(
        children: <Widget>[
          Text(
            value,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.primary, fontSize: 17, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.4),
          ),
        ],
      ),
    );
  }
}
