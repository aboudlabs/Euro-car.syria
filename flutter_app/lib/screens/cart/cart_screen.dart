// Cart tab and checkout (POST /api/orders): payment choice, Sham Cash receipt and order confirmation.
//
// Only part ids and quantities are sent; the server recomputes prices, stock and the total.

import 'dart:typed_data';

import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../core/cart.dart';
import '../../core/format.dart';
import '../../core/models.dart';
import '../../state/app_state.dart';
import '../../theme/palette.dart';
import '../../widgets/feedback.dart';
import '../../widgets/inputs.dart';
import '../../widgets/panel.dart';
import '../../widgets/part_plate.dart';
import '../../widgets/pickers.dart';
import '../home/tab_header.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _PayOption {
  const _PayOption(this.key, this.icon, this.title, this.subtitle);

  final String key;
  final IconData icon;
  final String title;
  final String subtitle;
}

const List<_PayOption> _payOptions = <_PayOption>[
  _PayOption('cod', Icons.payments_outlined, 'كاش عند الاستلام', 'ادفع نقدًا للمندوب'),
  _PayOption('sham', Icons.account_balance_outlined, 'شام كاش', 'حوّل المبلغ وأرفق إشعار التحويل'),
  _PayOption(
    'debt',
    Icons.menu_book_outlined,
    'دفتر الدين (للورشات)',
    'بعد موافقة الأدمن يبدأ عدّاد 30 يومًا',
  ),
];

class _CartScreenState extends State<CartScreen> {
  String _pay = 'cod';
  Uint8List? _receipt;
  bool _busy = false;
  String? _error;

  Future<void> _pickReceipt() async {
    final ImagePickResult result = await pickPhoto(context, maxSide: 2000);
    if (!mounted) {
      return;
    }
    final Uint8List? bytes = result.bytes;
    final String? failure = result.error;
    setState(() {
      if (bytes != null) {
        _receipt = bytes;
        _error = null;
      } else if (failure != null) {
        _error = failure;
      }
    });
  }

  Future<void> _confirmClear() async {
    final bool? clear = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('تفريغ السلة'),
        content: const Text('هل تريد إزالة جميع القطع من السلة؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('تفريغ'),
          ),
        ],
      ),
    );
    if (clear == true && mounted) {
      AppScope.read(context).clearCart();
    }
  }

  Future<void> _submit(String pay) async {
    if (_busy) {
      return;
    }
    if (pay == 'sham' && _receipt == null) {
      setState(() => _error = 'يرجى إرفاق إشعار تحويل شام كاش لإتمام الطلب.');
      return;
    }
    final AppState state = AppScope.read(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final PlacedOrder placed = await state.placeOrder(
        pay: pay,
        receipt: pay == 'sham' ? _receipt : null,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _receipt = null;
        _pay = 'cod';
      });
      await _showSuccess(placed, pay);
    } on ApiException catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = error.message;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _busy = false;
        _error = unexpectedMessage;
      });
    }
  }

  Future<void> _showSuccess(PlacedOrder placed, String pay) async {
    final Palette p = Palette.of(context);
    final int? number = placed.orderNumber;
    await showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        icon: Icon(Icons.check_circle_rounded, color: p.ok, size: 54),
        title: const Text('تم إرسال الطلب', textAlign: TextAlign.center),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (number != null)
              Text(
                'رقم الطلب: #$number',
                style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w800),
              ),
            if (number != null) const SizedBox(height: 8),
            Text(
              pay == 'debt'
                  ? 'طلبك بانتظار موافقة الأدمن على الدين.'
                  : 'سنتواصل معك لتأكيد التوصيل.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 14.5, height: 1.6),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: <Widget>[
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('عرض طلباتي'),
          ),
        ],
      ),
    );
    if (!mounted) {
      return;
    }
    AppScope.read(context).selectTab(tabOrders);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final AppUser? user = state.user;
    if (user == null) {
      return const SizedBox.shrink();
    }
    final List<CartLine> lines = state.cartLines;

    return Column(
      children: <Widget>[
        TabHeader(
          title: 'السلة',
          subtitle: 'توصيل وشحن لكافة المحافظات السورية',
          actions: <Widget>[
            if (lines.isNotEmpty)
              IconButton(
                onPressed: _busy ? null : _confirmClear,
                tooltip: 'تفريغ السلة',
                icon: const Icon(Icons.delete_sweep_outlined),
              ),
          ],
        ),
        Expanded(child: _body(context, state, user, lines)),
      ],
    );
  }

  Widget _body(BuildContext context, AppState state, AppUser user, List<CartLine> lines) {
    final String? notice = state.cartNotice;

    if (lines.isEmpty) {
      final bool waitingForCatalog = state.cartItems.isNotEmpty && !state.partsLoaded;
      if (waitingForCatalog) {
        final String? error = state.partsError;
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            if (error != null)
              NoticeBanner(
                message: error,
                kind: NoticeKind.error,
                onRetry: () => state.loadParts(),
              )
            else
              const LoadingBlock(message: 'جارٍ تحميل السلة...'),
          ],
        );
      }
      return ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: <Widget>[
          if (notice != null) ...<Widget>[
            NoticeBanner(
              message: notice,
              kind: NoticeKind.warning,
              onDismiss: state.dismissCartNotice,
            ),
            const SizedBox(height: 10),
          ],
          EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: 'السلة فارغة',
            message: 'أضف قطعاً من الكتالوج لتبدأ طلبك.',
            actionLabel: 'تصفّح الكتالوج',
            onAction: () => state.selectTab(tabCatalog),
          ),
        ],
      );
    }

    final Palette p = Palette.of(context);
    final double total = state.cartTotalAmount;
    final List<String> methods = payMethodsFor(user);
    final DebtCheck debt = checkDebtPayment(user: user, total: total);
    String pay = _pay;
    if (!methods.contains(pay) || (pay == 'debt' && !debt.allowed)) {
      pay = 'cod';
    }
    final String? error = _error;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      children: <Widget>[
        if (notice != null) ...<Widget>[
          NoticeBanner(
            message: notice,
            kind: NoticeKind.warning,
            onDismiss: state.dismissCartNotice,
          ),
          const SizedBox(height: 10),
        ],
        for (final CartLine line in lines)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _CartLineTile(
              key: ValueKey<String>(line.part.id),
              line: line,
              enabled: !_busy,
            ),
          ),
        Panel(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: <Widget>[
              InfoRow(label: 'عدد القطع', value: '${state.cartItemCount}'),
              const SizedBox(height: 4),
              Row(
                children: <Widget>[
                  Text(
                    'إجمالي الطلب',
                    style: TextStyle(color: p.text, fontSize: 16, fontWeight: FontWeight.w800),
                  ),
                  const Spacer(),
                  Text(
                    formatUsd(total),
                    style: TextStyle(color: p.primary, fontSize: 24, fontWeight: FontWeight.w900),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SectionTitle('طريقة الدفع'),
        for (final _PayOption option in _payOptions)
          if (methods.contains(option.key))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PayTile(
                option: option,
                selected: pay == option.key,
                problem: option.key == 'debt' && !debt.allowed ? debt.message : null,
                onTap: _busy || (option.key == 'debt' && !debt.allowed)
                    ? null
                    : () => setState(() {
                          _pay = option.key;
                          _error = null;
                        }),
              ),
            ),
        if (!user.isWorkshop)
          Padding(
            padding: const EdgeInsets.only(top: 2, bottom: 6),
            child: Text(
              'الدفع بالدين متاح حصريًا لحسابات الورشات.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 12.5),
            ),
          ),
        if (pay == 'sham') ...<Widget>[
          const SizedBox(height: 4),
          _receiptPanel(p),
        ],
        if (pay == 'debt') ...<Widget>[
          const SizedBox(height: 4),
          NoticeBanner(
            kind: NoticeKind.warning,
            message: 'عدّاد 30 يومًا يبدأ من أول قطعة دين. عند تجاوزه يتوقف السحب الآجل حتى التسديد. '
                'الكاش باك والعمولة يُصرفان بعد التسديد.\n'
                'المتاح من سقفك: ${debt.available == null ? 'غير محدد' : formatUsd(debt.available ?? 0)}',
          ),
        ],
        if (error != null) ...<Widget>[
          const SizedBox(height: 14),
          NoticeBanner(message: error, kind: NoticeKind.error),
        ],
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'تأكيد الطلب · ${formatUsd(total)}',
          icon: Icons.check_rounded,
          busy: _busy,
          onPressed: () => _submit(pay),
        ),
        if (_busy)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Text(
              'جارٍ إرسال الطلب، قد يستغرق ذلك لحظات إذا كان الخادم في وضع السكون. لا تغلق التطبيق.',
              textAlign: TextAlign.center,
              style: TextStyle(color: p.muted, fontSize: 13, height: 1.5),
            ),
          ),
      ],
    );
  }

  Widget _receiptPanel(Palette p) {
    final Uint8List? receipt = _receipt;
    return Panel(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'إشعار التحويل',
            style: TextStyle(color: p.text, fontSize: 15.5, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'حوّل المبلغ عبر شام كاش ثم أرفق صورة الإشعار (JPG أو PNG أو WebP، حتى 5 ميغابايت).',
            style: TextStyle(color: p.muted, fontSize: 13, height: 1.6),
          ),
          const SizedBox(height: 12),
          if (receipt == null)
            SecondaryButton(
              label: 'ارفع إشعار التحويل',
              icon: Icons.upload_rounded,
              onPressed: _busy ? null : _pickReceipt,
            )
          else ...<Widget>[
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                height: 190,
                child: Image.memory(receipt, fit: BoxFit.contain),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                TextButton.icon(
                  onPressed: _busy ? null : _pickReceipt,
                  icon: const Icon(Icons.swap_horiz_rounded),
                  label: const Text('تغيير الصورة'),
                ),
                TextButton.icon(
                  onPressed: _busy ? null : () => setState(() => _receipt = null),
                  icon: Icon(Icons.delete_outline_rounded, color: p.err),
                  label: Text('إزالة', style: TextStyle(color: p.err)),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// One cart entry with its quantity stepper and remove button.
class _CartLineTile extends StatelessWidget {
  const _CartLineTile({super.key, required this.line, required this.enabled});

  final CartLine line;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final AppState state = AppScope.of(context);
    final Part part = line.part;
    final bool atLimit = line.qty >= part.maxOrderQty;

    return Panel(
      padding: const EdgeInsetsDirectional.fromSTEB(14, 10, 6, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        part.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.text,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(part.brand, style: TextStyle(color: p.muted, fontSize: 12.5)),
                      const SizedBox(height: 6),
                      PartNumberPlate(number: part.pn),
                    ],
                  ),
                ),
              ),
              IconButton(
                onPressed: enabled ? () => state.removeFromCart(part.id) : null,
                tooltip: 'حذف من السلة',
                icon: Icon(Icons.delete_outline_rounded, color: p.muted),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsetsDirectional.only(end: 8),
            child: Row(
              children: <Widget>[
                QuantityStepper(
                  quantity: line.qty,
                  onIncrement: enabled && !atLimit
                      ? () {
                          final String? problem = state.addToCart(part);
                          if (problem != null) {
                            showSnack(context, problem);
                          }
                        }
                      : null,
                  onDecrement: enabled ? () => state.decrementCart(part.id) : null,
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Text(
                        formatUsd(line.total),
                        style: TextStyle(color: p.text, fontSize: 17, fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${formatUsd(part.price)} للقطعة',
                        style: TextStyle(color: p.muted, fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (atLimit)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'وصلت إلى أقصى كمية متاحة من هذه القطعة.',
                style: TextStyle(color: p.warn, fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }
}

/// A selectable payment method. A disabled tile explains why it cannot be used.
class _PayTile extends StatelessWidget {
  const _PayTile({
    required this.option,
    required this.selected,
    required this.onTap,
    this.problem,
  });

  final _PayOption option;
  final bool selected;
  final VoidCallback? onTap;
  final String? problem;

  @override
  Widget build(BuildContext context) {
    final Palette p = Palette.of(context);
    final bool enabled = onTap != null;
    final Color accent = selected ? p.primary : p.muted;
    final String? reason = problem;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: '${option.title}، ${option.subtitle}',
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        color: selected ? p.primary.withValues(alpha: 0.12) : p.panel,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: selected ? p.primary : p.line, width: selected ? 1.6 : 1),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Opacity(
            opacity: (enabled || selected) ? 1.0 : 0.6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: <Widget>[
                  Icon(option.icon, color: accent, size: 26),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          option.title,
                          style: TextStyle(color: p.text, fontSize: 15, fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          option.subtitle,
                          style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.4),
                        ),
                        if (reason != null) ...<Widget>[
                          const SizedBox(height: 4),
                          Text(
                            reason,
                            style: TextStyle(color: p.warn, fontSize: 12.5, height: 1.4),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Icon(
                    selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                    color: accent,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
