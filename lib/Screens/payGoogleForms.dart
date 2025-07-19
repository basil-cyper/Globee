// import 'dart:io';

// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:globee/Core/PushNotificationsServiceOrders.dart';
// import 'package:globee/Core/Utils.dart';
// import 'package:globee/provider/App_Provider.dart';
// import 'package:provider/provider.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:url_launcher/url_launcher.dart';
// import 'package:webview_flutter/webview_flutter.dart';

// class PayGoogleForms extends StatefulWidget {
//   final String totalAmount;
//   const PayGoogleForms({super.key, required this.totalAmount});

//   @override
//   State<PayGoogleForms> createState() => _PayGoogleFormsState();
// }

// class _PayGoogleFormsState extends State<PayGoogleForms> {
//   WebViewController? _controller;
//   String? paymentSessionUrl;

//   String lang = "eng";
//   List languages = [];

//   double shippingFee = 10.0;
//   List cartOrders = [];
//   double totalPrices = 0.0;
//   double finalTotalFinish = 0.0;

//   Future getLang() async {
//     SharedPreferences prefx = await SharedPreferences.getInstance();

//     setState(() {
//       lang = prefx.getString("Lang")!;
//       getLangDB();
//     });
//   }

//   Future getLangDB() async {
//     var results = await AppUtils.makeRequests(
//       "fetch",
//       "SELECT $lang FROM Languages ",
//     );
//     setState(() {
//       languages = results;
//     });
//   }

//   Future getCartOrders() async {
//     SharedPreferences prefx = await SharedPreferences.getInstance();
//     var orders = await AppUtils.makeRequests(
//       "fetch",
//       "SELECT Cart.id AS id, Items.`name`, Items.id AS itmid,Items.price, Items.media,Items.uid, Cart.qtt FROM Cart LEFT JOIN Items ON Cart.item_id = Items.id WHERE Cart.order_id = '${prefx.getString("OID")}'",
//     );

//     setState(() {
//       cartOrders = orders;
//       totalPrices = 0.0; // لازم تصفره قبل التكرار
//       for (var cartOrder in cartOrders) {
//         totalPrices +=
//             double.parse(cartOrder['price'].toString()) *
//             double.parse(cartOrder['qtt'].toString());
//       }
//       finalTotalFinish = totalPrices + shippingFee;
//     });
//   }

//   Future<void> getInvoiceScreen() async {
//     setState(() {
//       _controller =
//           WebViewController()
//             ..loadRequest(
//               Uri.parse(
//                 "https://docs.google.com/forms/d/e/1FAIpQLScD-ENv4QuUJINzjdf-nnDagWDdZ5EXtDlTjS4fRWXCpbOAZw/viewform?usp=pp_url&entry.1109870145=${widget.totalAmount}",
//               ),
//             )
//             ..setNavigationDelegate(
//               NavigationDelegate(
//                 onUrlChange: (change) async {

//                 },
//               ),
//             )
//             ..setJavaScriptMode(JavaScriptMode.unrestricted);
//     });
//   }

//   @override
//   void initState() {
//     super.initState();
//     getLang();
//     getCartOrders();
//     getInvoiceScreen();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: WebViewWidget(controller: _controller!),
//     );
//   }
// }
