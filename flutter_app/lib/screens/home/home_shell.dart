// The signed-in area: five tabs behind a bottom navigation bar.
//
// Tabs are built the first time they are opened, so the orders and dashboard requests are only made when the
// user actually looks at them. The tab index lives in AppState, so any screen can switch tabs.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/palette.dart';

import '../../state/app_state.dart';
import '../account/account_screen.dart';
import '../cart/cart_screen.dart';
import '../catalog/catalog_screen.dart';
import '../dashboard/dashboard_screen.dart';
import '../orders/orders_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  static const List<Widget> _screens = <Widget>[
    CatalogScreen(),
    CartScreen(),
    OrdersScreen(),
    DashboardScreen(),
    AccountScreen(),
  ];

  /// Tabs that were opened at least once; the others are not built until they are needed.
  final Set<int> _opened = <int>{tabCatalog};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      AppScope.read(context).refreshOnResume();
    }
  }

  void _selectTab(AppState state, int index) {
    FocusManager.instance.primaryFocus?.unfocus();
    state.selectTab(index);
  }

  @override
  Widget build(BuildContext context) {
    final AppState state = AppScope.of(context);
    final int tab = state.selectedTab;
    _opened.add(tab);
    final bool keyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;
    final int cartCount = state.cartItemCount;

    return PopScope(
      canPop: tab == tabCatalog,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (!didPop) {
          state.selectTab(tabCatalog);
        }
      },
      child: Scaffold(
        body: SafeArea(
          bottom: false,
          child: IndexedStack(
            index: tab,
            children: <Widget>[
              for (int i = 0; i < _screens.length; i++)
                TickerMode(
                  enabled: i == tab,
                  child: _opened.contains(i) ? _screens[i] : const SizedBox.shrink(),
                ),
            ],
          ),
        ),
        bottomNavigationBar: keyboardOpen
            ? null
            : ClipRect(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Palette.of(context).bg.withValues(alpha: 0.78),
                      border: Border(
                        top: BorderSide(color: Palette.of(context).line),
                      ),
                      boxShadow: const <BoxShadow>[
                        BoxShadow(color: Color(0x33000000), blurRadius: 24, offset: Offset(0, -6)),
                      ],
                    ),
                    child: NavigationBar(
                selectedIndex: tab,
                onDestinationSelected: (int index) => _selectTab(state, index),
                destinations: <Widget>[
                  const NavigationDestination(
                    icon: Icon(Icons.storefront_outlined),
                    selectedIcon: Icon(Icons.storefront_rounded),
                    label: 'الكتالوج',
                  ),
                  NavigationDestination(
                    icon: _CartIcon(count: cartCount, selected: false),
                    selectedIcon: _CartIcon(count: cartCount, selected: true),
                    label: 'السلة',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.receipt_long_outlined),
                    selectedIcon: Icon(Icons.receipt_long_rounded),
                    label: 'طلباتي',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.insights_outlined),
                    selectedIcon: Icon(Icons.insights_rounded),
                    label: 'لوحتي',
                  ),
                  const NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded),
                    selectedIcon: Icon(Icons.person_rounded),
                    label: 'حسابي',
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

/// The cart icon with the number of units in the cart.
class _CartIcon extends StatelessWidget {
  const _CartIcon({required this.count, required this.selected});

  final int count;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final Icon icon = Icon(selected ? Icons.shopping_bag_rounded : Icons.shopping_bag_outlined);
    if (count <= 0) {
      return icon;
    }
    return Badge(
      label: Text(count > 99 ? '99+' : '$count'),
      child: icon,
    );
  }
}
