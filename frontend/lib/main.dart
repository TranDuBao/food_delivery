import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:food_delivery/common/color_extension.dart';
import 'package:food_delivery/common/locator.dart';
import 'package:food_delivery/common/service_call.dart';
import 'package:food_delivery/view/shared/login/welcome_view.dart';
import 'package:food_delivery/view/customer/main_tabview/main_tabview.dart';
import 'package:food_delivery/view/shared/on_boarding/startup_view.dart';
import 'package:food_delivery/view/staff/staff_main_tab_view.dart';
import 'package:food_delivery/view/admin/admin_main_view.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:food_delivery/view/customer/group/group_service.dart';
import 'package:food_delivery/view/customer/more/dine_in_menu_view.dart';

import 'common/globs.dart';
import 'common/my_http_overrides.dart';

SharedPreferences? prefs;

bool isCanteenStaffUser(Map<String, dynamic> userPayload) {
  final role = userPayload['role']?.toString().trim().toLowerCase();
  if (role == 'canteen_staff') return true;
  final maVaiTro = userPayload['maVaiTro'];
  if (maVaiTro != null && maVaiTro.toString() == '2') return true;
  return false;
}

bool isAdminUser(Map<String, dynamic> userPayload) {
  final maVaiTro = userPayload['maVaiTro'];
  return maVaiTro != null && maVaiTro.toString() == '3';
}

Widget resolveHomeByRole() {
  final user =
      Map<String, dynamic>.from(Globs.udValue(Globs.userPayload) as Map? ?? {});
  if (isAdminUser(user)) return const AdminMainView();
  if (isCanteenStaffUser(user)) return const StaffMainTabView();
  return const MainTabView();
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  setUpLocator();
  HttpOverrides.global = MyHttpOverrides();
  prefs = await SharedPreferences.getInstance();

  if (Globs.udValueBool(Globs.userLogin)) {
    final storedPayload = Map<String, dynamic>.from(
        Globs.udValue(Globs.userPayload) as Map? ?? {});
    storedPayload.putIfAbsent(KKey.name, () => storedPayload["fullName"] ?? "");
    ServiceCall.userPayload = storedPayload;

    // Load nhóm của đúng user đã đăng nhập sẵn
    final uid = storedPayload['id']?.toString() ??
        storedPayload['_id']?.toString() ??
        storedPayload['maTaiKhoan']?.toString() ?? '';
    GroupService.instance.initForUser(uid).catchError((e) {
      debugPrint("GroupService init error during startup: $e");
    });
  }

  configLoading();

  runApp(const MyApp(
    defaultHome: StartupView(),
  ));
}

void configLoading() {
  EasyLoading.instance
    ..indicatorType = EasyLoadingIndicatorType.ring
    ..loadingStyle = EasyLoadingStyle.custom
    ..indicatorSize = 45.0
    ..radius = 5.0
    ..progressColor = TColor.primaryText
    ..backgroundColor = TColor.primary
    ..indicatorColor = Colors.yellow
    ..textColor = TColor.primaryText
    ..userInteractions = false
    ..dismissOnTap = false;
}

class MyApp extends StatefulWidget {
  final Widget defaultHome;
  const MyApp({super.key, required this.defaultHome});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  static const _deepLinkChannel = MethodChannel('app.channel.shared.data');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _listenDeepLink();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // ── Deep link: shipfood://canteen/{id} ─────────────────────────────────────
  void _listenDeepLink() {
    // Nhận deep link khi app đang mở
    _deepLinkChannel.setMethodCallHandler((call) async {
      if (call.method == 'canteen') {
        final canteenId = int.tryParse(call.arguments?.toString() ?? '');
        if (canteenId != null) _openDineInMenu(canteenId);
      }
    });
  }

  void _openDineInMenu(int canteenId) {
    final nav = locator<NavigationService>().navigatorKey.currentState;
    if (nav == null) return;
    nav.push(MaterialPageRoute(
      builder: (_) => DineInMenuView(canteenId: canteenId),
    ));
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      _clearSessionOnTaskKilled();
    }
  }

  void _clearSessionOnTaskKilled() {
    Globs.udBoolSet(false, Globs.userLogin);
    Globs.udRemove(KKey.authToken);
    Globs.udRemove(Globs.userPayload);
    ServiceCall.userPayload = {};
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food Delivery',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: "Metropolis",
        // This is the theme of your application.
        //
        // TRY THIS: Try running your application with "flutter run". You'll see
        // the application has a blue toolbar. Then, without quitting the app,
        // try changing the seedColor in the colorScheme below to Colors.green
        // and then invoke "hot reload" (save your changes or press the "hot
        // reload" button in a Flutter-supported IDE, or press "r" if you used
        // the command line to start the app).
        //
        // Notice that the counter didn't reset back to zero; the application
        // state is not lost during the reload. To reset the state, use hot
        // restart instead.
        //
        // This works for code too, not just values: Most code changes can be
        // tested with just a hot reload.
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        // useMaterial3: true,
      ),
      home: widget.defaultHome,
      navigatorKey: locator<NavigationService>().navigatorKey,
      onGenerateRoute: (routeSettings) {
        switch (routeSettings.name) {
          case "welcome":
            return MaterialPageRoute(builder: (context) => const WelcomeView());
          case "Home":
            return MaterialPageRoute(builder: (context) => resolveHomeByRole());
          default:
            return MaterialPageRoute(
                builder: (context) => Scaffold(
                      body: Center(
                          child: Text("No path for ${routeSettings.name}")),
                    ));
        }
      },
      builder: EasyLoading.init(),
    );
  }
}
