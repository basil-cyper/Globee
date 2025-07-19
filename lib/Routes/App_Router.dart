import 'package:globee/Screens/AddItemsDetails/Add_Items.dart';
import 'package:globee/Screens/AddItemsDetails/Edit_Items.dart';
import 'package:globee/Screens/Auth/CompleteProfile.dart';
import 'package:globee/Screens/Auth/LoginScreen.dart';
import 'package:globee/Screens/Auth/OTPScreen.dart';
import 'package:globee/Screens/CartScreen.dart';
import 'package:globee/Screens/ChangeLanguage.dart';
import 'package:globee/Screens/ChatScreen.dart';
import 'package:globee/Screens/Checkout.dart';
import 'package:globee/Screens/Checkout_Summary.dart';
import 'package:globee/Screens/CustomerOrders.dart';
import 'package:globee/Screens/ForceUpdateScreen.dart';
import 'package:globee/Screens/Home/Home_Screen_Profile.dart';
import 'package:globee/Screens/InvoiceWebView.dart';
import 'package:globee/Screens/PaymentSuccess.dart';
import 'package:globee/Screens/Profile/User_Profile.dart';
import 'package:globee/Screens/SearchScreen.dart';
import 'package:globee/Screens/Shipping_Orders.dart';
import 'package:flutter/material.dart';
import 'package:globee/Terms/Privacy_Terms.dart';
import 'package:go_router/go_router.dart';
import 'package:globee/Screens/Home/Home_Screen.dart';
import 'package:globee/Screens/Splash/SplashScreen.dart';
import 'package:globee/Screens/accessBlock.dart';
import 'package:globee/Screens/payGoogleForms.dart';
import 'package:globee/test.dart';
import 'package:shared_preferences/shared_preferences.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GoRouter router = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/splash',
  redirect: (context, state) async {
    final prefs = await SharedPreferences.getInstance();
    final lang = prefs.getString('Lang');

    if (lang == null && state.matchedLocation != '/changeLanguage') {
      return '/changeLanguage';
    }

    return null;
  },
  routes: [
    GoRoute(path: '/splash', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/block', builder: (context, state) => const AccessBlock()),
    GoRoute(
      path: '/changeLanguage',
      builder: (context, state) => const ChangeLangScreen(),
    ),
    GoRoute(path: '/home', builder: (context, state) => HomeScreen()),
    GoRoute(path: '/test', builder: (context, state) => TestScreen()),
    GoRoute(path: '/login', builder: (context, state) => LoginScreen()),
    GoRoute(path: '/search', builder: (context, state) => SearchScreen()),
    GoRoute(
      path: '/force-update',
      builder: (context, state) {
        final data = state.extra as Map<String, dynamic>;
        return ForceUpdateScreen(
          message: data['message'],
          storeUrl: data['storeUrl'],
        );
      },
    ),

    GoRoute(
      path: '/customersOrders',
      builder: (context, state) {
        final custId = (state.extra as Map?)?['custId'] ?? '';
        return CustomersOrders(custId: custId);
      },
    ),
    GoRoute(
      path: '/privacyterms',
      builder: (context, state) {
        final termsPage = (state.extra as Map?)?['termsPage'] ?? '';
        return PrivacyTerms(termsPage: termsPage);
      },
    ),

    // GoRoute(
    //   path: '/payGoogleForm',
    //   builder: (context, state) {
    //     final totalAmount = (state.extra as Map?)?['totalAmount'] ?? '';
    //     return PayGoogleForms(totalAmount: totalAmount);
    //   },
    // ),
    GoRoute(
      path: '/invoice',
      builder: (context, state) {
        final orderId = (state.extra as Map?)?['orderId'] ?? '';
        final payment = (state.extra as Map?)?['payment'] ?? '';
        final shipId = (state.extra as Map?)?['shipId'] ?? '';
        final custId = (state.extra as Map?)?['custId'] ?? '';
        return InvoiceWebView(
          orderId: orderId,
          payment: payment,
          shipId: shipId,
          custId: custId,
        );
      },
    ),

    GoRoute(
      path: '/otp',
      builder: (context, state) {
        final params = state.extra as Map<String, String>;
        return OTPScreen(
          mobile: params['mobile']!,
          otp: int.parse(params['otp'].toString()),
        );
      },
    ),

    GoRoute(
      path: '/Globee/product',
      builder: (context, state) {
        final id = state.uri.queryParameters['id'];
        print('وصل للـ Route بتاع المنتج، ID = $id');
        return HomeScreen(productId: id);
      },
    ),

    GoRoute(
      path: '/createUser',
      builder: (context, state) {
        final params = state.extra as Map<String, String>;
        return CreateUser(phonenumber: params['phonenumber']!);
      },
    ),
    GoRoute(
      path: '/UserProfile',
      builder: (context, state) {
        final params = state.extra as Map<String, String>;
        return UserProfile(userId: params['userId']!);
      },
    ),
    GoRoute(
      path: '/UserProfileHome',
      builder: (context, state) {
        final params = state.extra as Map<String, String>;
        return HomeScreenProfile(
          userProfileId: params['userProfileId']!,
          itemId: params['item_id']!,
        );
      },
    ),

    GoRoute(
      path: '/chatSeller',
      builder: (context, state) {
        final params = state.extra as Map<String, String>;
        return ChatScreen(chatId: params['chatId']!);
      },
    ),

    GoRoute(
      path: '/EditDetailsItem',
      builder: (context, state) {
        final params = state.extra as Map<String, String>;
        return EditItems(itemId: params['item_id']!);
      },
    ),
    GoRoute(
      path: '/CheckoutSummary',
      builder: (context, state) => OrderSummary(),
    ),
    GoRoute(
      path: '/paymentSuccess',
      builder: (context, state) => const PaymentSuccess(),
    ),

    // GoRoute(path: '/checkout', builder: (context, state) => CheckoutScreen()),
    GoRoute(
      path: '/shippingOrders',
      builder: (context, state) => ShippingOrders(),
    ),
    GoRoute(path: '/addDetails', builder: (context, state) => AddItems()),
    GoRoute(path: '/cart', builder: (context, state) => CartScreen()),
  ],
);
