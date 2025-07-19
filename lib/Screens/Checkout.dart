// import 'package:globee/Core/Utils.dart';
// import 'package:globee/Routes/App_Router.dart';
// import 'package:globee/Widgets/Button_Widget.dart';
// import 'package:flutter/material.dart';
// import 'package:go_router/go_router.dart';
// import 'package:iconsax/iconsax.dart';
// import 'package:shared_preferences/shared_preferences.dart';

// class CheckoutScreen extends StatefulWidget {
//   const CheckoutScreen({super.key});

//   @override
//   State<CheckoutScreen> createState() => _CheckoutScreenState();
// }

// class _CheckoutScreenState extends State<CheckoutScreen> {
//   int isSelected = 0;

  

//   String lang = "eng";
//   List languages = [];

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

//   @override
//   void initState() {
//     getLang();
//     getCartOrders();
//     super.initState();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return languages.isEmpty
//         ? Scaffold(backgroundColor: Colors.white)
//         : Scaffold(
//           backgroundColor: Colors.white,
//           appBar: AppBar(
//             leading: IconButton(
//               onPressed: () {
//                 context.go('/shippingOrders');
//               },
//               icon: Icon(Iconsax.arrow_circle_left),
//             ),
//             forceMaterialTransparency: true,
//             centerTitle: true,
//             title: Text(
//               languages[69][lang],
//               style: TextStyle(color: Colors.black),
//             ),
//             backgroundColor: Colors.white,
//           ),
//           body: Container(
//             margin: EdgeInsets.all(20),
//             child: Column(
//               children: [
//                 // ListTile(
//                 //   onTap: () {
//                 //     setState(() {
//                 //       isSelected = 1;
//                 //     });
//                 //   },
//                 //   tileColor: Colors.grey.shade200,
//                 //   leading: Icon(Iconsax.wallet_1),
//                 //   shape: RoundedRectangleBorder(
//                 //     borderRadius: BorderRadius.circular(10),
//                 //     side:
//                 //         isSelected == 1
//                 //             ? BorderSide(color: Colors.black, width: 2)
//                 //             : BorderSide.none,
//                 //   ),
//                 //   title: Text(languages[70][lang]),
//                 // ),
//                 // SizedBox(height: 10),
//                 ListTile(
//                   // onTap: () {
//                   //   setState(() {
//                   //     isSelected = 2;
//                   //   });
//                   // },
//                   tileColor: Colors.grey.shade200,
//                   leading: Icon(Iconsax.wallet_1),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(10),
//                     side: BorderSide(color: Colors.black, width: 2),
//                   ),
//                   title: Text(
//                     lang == 'arb' ? "الدفع عن طريق أي باي" : "Pay Using IPay",
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           floatingActionButtonLocation:
//               FloatingActionButtonLocation.centerDocked,
//           floatingActionButton: GestureDetector(
//             onTap: () async {
//               context.go('/payGoogleForm');
              // AppUtils.sNavigateToReplace(
              //   navigatorKey.currentState!.context,
              //   '/payGoogleForm',
              //   {'totalAmount': finalTotalFinish.toString()},
              // );

              
//               // SharedPreferences prefx = await SharedPreferences.getInstance();

//               // if (isSelected == 1) {
//               //   // طريقة الدفع: عند الاستلام
//               //   showDialog(
//               //     context: context,
//               //     barrierDismissible: false,
//               //     builder: (BuildContext context) {
//               //       return AlertDialog(
//               //         shape: RoundedRectangleBorder(
//               //           borderRadius: BorderRadius.circular(15),
//               //         ),
//               //         content: Row(
//               //           children: [
//               //             Container(
//               //               height: 20,
//               //               child: SpinKitDoubleBounce(
//               //                 color: AppTheme.primaryColor,
//               //                 size: 30.0,
//               //               ),
//               //             ),
//               //             SizedBox(width: 20),
//               //             Expanded(
//               //               child: Text(
//               //                 "جارٍ تأكيد الدفع ومعالجة الطلب...",
//               //                 style: TextStyle(fontSize: 16),
//               //               ),
//               //             ),
//               //           ],
//               //         ),
//               //       );
//               //     },
//               //   );

                
//               // } else {
//               //   // طريقة الدفع: كارت
//               //   // String result = await PaymentManager.makePayment(
//               //   //   (finalTotalFinish * 100).toInt(),
//               //   //   "qar",
//               //   // );

//               //   //

//               //   if (result == 'Succeeded') {
//               //     print("حالة الدفع: $result");

//               //     showDialog(
//               //       context: context,
//               //       barrierDismissible: false,
//               //       builder: (BuildContext context) {
//               //         return AlertDialog(
//               //           shape: RoundedRectangleBorder(
//               //             borderRadius: BorderRadius.circular(15),
//               //           ),
//               //           content: Row(
//               //             children: [
//               //               SpinKitDoubleBounce(
//               //                 color: AppTheme.primaryColor,
//               //                 size: 30.0,
//               //               ),
//               //               SizedBox(width: 20),
//               //               Expanded(
//               //                 child: Text(
//               //                   languages[74][lang],
//               //                   style: TextStyle(fontSize: 16),
//               //                 ),
//               //               ),
//               //             ],
//               //           ),
//               //         );
//               //       },
//               //     );

//               //     // هات البائعين الفريدين

//               //     context.go('/paymentSuccess');
//               //   } else {
//               //     print("حالة الدفع: $result");
//               //   }
//               // }
//             },

//             child: SizedBox(
//               height: 60,
//               child: ButtonWidget(btnText: languages[72][lang]),
//             ),
//           ),
//         );
//   }
// }
