// Registration for workshops (needs admin approval) and marketers (active immediately).
// Same fields and rules as the web sign-up: POST /api/auth with mode "register".

import 'package:flutter/material.dart';

import '../../core/config.dart';
import '../../core/models.dart';
import '../../core/referral.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/panel.dart';
import '../../widgets/pickers.dart';
import '../../widgets/select_field.dart';
import 'auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key, required this.onBack});

  final VoidCallback onBack;

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController _name = TextEditingController();
  final TextEditingController _phone = TextEditingController();
  final TextEditingController _password = TextEditingController();
  final TextEditingController _license = TextEditingController();
  final TextEditingController _otherBrand = TextEditingController();
  final TextEditingController _referral = TextEditingController();

  String _role = 'workshop';
  String _city = defaultGovernorate;
  final List<String> _specs = <String>['Mercedes-Benz'];
  ReferralInput? _signedReferral;
  bool _busy = false;
  String? _error;
  String? _pendingMessage;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _password.dispose();
    _license.dispose();
    _otherBrand.dispose();
    _referral.dispose();
    super.dispose();
  }

  bool get _isWorkshop => _role == 'workshop';

  void _onReferralChanged(String value) {
    final ReferralInput parsed = parseReferral(value);
    if (parsed.isSigned) {
      // A pasted invitation link: lock the code so it cannot be edited (the server checks the signature).
      setState(() {
        _signedReferral = parsed;
        _referral.text = parsed.code;
      });
    }
  }

  void _clearReferral() {
    setState(() {
      _signedReferral = null;
      _referral.clear();
    });
  }

  Future<void> _pickCity() async {
    final String? picked = await showChoiceSheet<String>(
      context: context,
      title: 'اختر المحافظة',
      options: governorates,
      labelOf: (String value) => value,
      selected: _city,
    );
    if (picked != null && mounted) {
      setState(() => _city = picked);
    }
  }

  String _specsText() {
    final List<String> items = <String>[];
    for (final String brand in _specs) {
      items.add(brand == otherLabel ? '$otherLabel (${_otherBrand.text.trim()})' : brand);
    }
    return items.join(', ');
  }

  String? _validate() {
    if (_name.text.trim().isEmpty) {
      return 'الاسم مطلوب لإنشاء الحساب';
    }
    if (_phone.text.trim().isEmpty || _password.text.length < 4) {
      return 'يرجى إدخال رقم الموبايل وكلمة مرور من 4 أحرف على الأقل';
    }
    if (_isWorkshop) {
      if (_license.text.trim().isEmpty) {
        return 'يرجى إدخال رقم الترخيص أو السجل التجاري للورشة';
      }
      if (_specs.isEmpty) {
        return 'يرجى اختيار ماركة واحدة على الأقل لاختصاص الورشة';
      }
      if (_specs.contains(otherLabel) && _otherBrand.text.trim().isEmpty) {
        return 'يرجى كتابة اسم الماركة الإضافية في حقل (أخرى)';
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (_busy) {
      return;
    }
    final String? problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    final AppState state = AppScope.read(context);
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    final ReferralInput referral = _signedReferral ?? parseReferral(_referral.text);
    final AuthResult result = await state.register(
      role: _role,
      name: _name.text,
      phone: _phone.text,
      password: _password.text,
      license: _license.text,
      city: _city,
      specs: _specsText(),
      refCode: referral.code,
      refSignature: referral.signature,
    );
    if (!mounted) {
      return;
    }
    setState(() {
      _busy = false;
      if (result.isPending) {
        _pendingMessage = result.message;
      } else if (!result.isSignedIn) {
        _error = result.message;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final String? pending = _pendingMessage;
    final String? error = _error;
    final ReferralInput? signed = _signedReferral;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: TextButton.icon(
                      onPressed: _busy ? null : widget.onBack,
                      icon: const Icon(Icons.arrow_back_rounded),
                      label: const Text('تسجيل الدخول'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const AuthHeader(),
                  const SizedBox(height: 22),
                  if (pending != null)
                    PendingApprovalCard(
                      title: 'تم إرسال طلبك للمراجعة بنجاح!',
                      message: pending,
                      onBack: widget.onBack,
                    )
                  else
                    ..._form(p, error, signed),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _form(Palette p, String? error, ReferralInput? signed) {
    return <Widget>[
      Text(
        'إنشاء حساب جديد',
        style: TextStyle(color: p.text, fontSize: 22, fontWeight: FontWeight.w900),
      ),
      const SizedBox(height: 14),
      RoleSelector(
        role: _role,
        registering: true,
        onChanged: (String value) => setState(() {
          _role = value;
          _error = null;
        }),
      ),
      const SizedBox(height: 20),
      Text(
        _isWorkshop ? 'بيانات اعتماد الورشة الجديدة' : 'بيانات حساب المسوّق الجديد',
        style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w800),
      ),
      const SizedBox(height: 12),
      AppTextField(
        controller: _name,
        label: _isWorkshop ? 'اسم الورشة أو الشركة الرسمي' : 'الاسم الكامل',
        icon: Icons.badge_outlined,
        textInputAction: TextInputAction.next,
        maxLength: 100,
      ),
      const SizedBox(height: 14),
      AppTextField(
        controller: _phone,
        label: 'رقم الموبايل',
        hint: '09XXXXXXXX',
        icon: Icons.phone_iphone_rounded,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        ltr: true,
      ),
      const SizedBox(height: 14),
      PasswordField(
        controller: _password,
        label: 'كلمة المرور (4 أحرف على الأقل)',
        textInputAction: _isWorkshop ? TextInputAction.next : TextInputAction.done,
        onSubmitted: (String _) {
          if (!_isWorkshop) {
            _submit();
          }
        },
      ),
      if (_isWorkshop) ...<Widget>[
        const SizedBox(height: 14),
        AppTextField(
          controller: _license,
          label: 'رقم السجل التجاري / ترخيص الورشة',
          icon: Icons.verified_outlined,
          textInputAction: TextInputAction.next,
          maxLength: 80,
        ),
        const SizedBox(height: 14),
        SelectField(
          label: 'المحافظة',
          value: _city,
          icon: Icons.location_on_outlined,
          onTap: _pickCity,
        ),
        const SizedBox(height: 14),
        Text(
          'اختصاص الورشة (الماركات)',
          style: TextStyle(color: p.muted, fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: <Widget>[
            for (final String brand in specialtyBrands)
              FilterChip(
                label: Text(brand),
                selected: _specs.contains(brand),
                onSelected: (bool on) => setState(() {
                  if (on) {
                    _specs.add(brand);
                  } else {
                    _specs.remove(brand);
                  }
                }),
              ),
          ],
        ),
        if (_specs.contains(otherLabel)) ...<Widget>[
          const SizedBox(height: 12),
          AppTextField(
            controller: _otherBrand,
            label: 'اسم الماركة الإضافية',
            textInputAction: TextInputAction.next,
            maxLength: 60,
          ),
        ],
        const SizedBox(height: 14),
        if (signed != null) ...<Widget>[
          AppTextField(
            controller: _referral,
            label: 'كود المسوّق',
            icon: Icons.link_rounded,
            ltr: true,
            readOnly: true,
            suffix: IconButton(
              onPressed: _busy ? null : _clearReferral,
              tooltip: 'إزالة رابط الدعوة',
              icon: Icon(Icons.link_off_rounded, color: p.muted),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'كود الإحالة مثبت من رابط المسوّق ولا يمكن تغييره.',
            style: TextStyle(color: p.ok, fontSize: 12.5),
          ),
        ] else
          AppTextField(
            controller: _referral,
            label: 'كود المسوّق أو رابط الدعوة (اختياري)',
            hint: 'MK-XXXXXX',
            icon: Icons.link_rounded,
            ltr: true,
            textInputAction: TextInputAction.done,
            onChanged: _onReferralChanged,
          ),
        const SizedBox(height: 14),
        Panel(
          color: p.primary.withValues(alpha: 0.1),
          borderColor: p.primary.withValues(alpha: 0.35),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: <Widget>[
              Icon(Icons.shield_outlined, color: p.primary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'حسابات الورشات تتطلب مراجعة وموافقة الإدارة قبل التفعيل.',
                  style: TextStyle(color: p.text, fontSize: 13, height: 1.5),
                ),
              ),
            ],
          ),
        ),
      ],
      if (error != null) ...<Widget>[
        const SizedBox(height: 16),
        NoticeBanner(message: error, kind: NoticeKind.error),
      ],
      const SizedBox(height: 18),
      PrimaryButton(
        label: _isWorkshop ? 'إرسال طلب اعتماد الورشة' : 'إنشاء الحساب فوراً',
        busy: _busy,
        onPressed: _submit,
      ),
      if (_busy) ...<Widget>[
        const SizedBox(height: 10),
        Text(
          'قد يستغرق الاتصال الأول حتى دقيقة إذا كان الخادم في وضع السكون.',
          textAlign: TextAlign.center,
          style: TextStyle(color: p.muted, fontSize: 13, height: 1.5),
        ),
      ],
    ];
  }
}
