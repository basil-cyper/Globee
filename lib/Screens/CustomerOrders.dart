import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/Core/PushNotificationsService.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Routes/App_Router.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CustomersOrders extends StatefulWidget {
  final String? custId;
  const CustomersOrders({super.key, this.custId});

  @override
  State<CustomersOrders> createState() => _CustomersOrdersState();
}

class _CustomersOrdersState extends State<CustomersOrders> {
  List orders = [];
  String onStatusChanged = "";
  String orderStatus = "Pending";
  IconData orderIcon = Iconsax.document_text;
  List<String> orderStatusAr = [
    'قيد المراجعة',
    'جاري التحضير',
    'جاهز للشحن',
    'جاري التوصيل',
    'تم التوصيل',
  ];
  List<String> orderStatusEn = [
    "Pending",
    "Preparing",
    "ReadyToShip",
    "Shipping",
    "Delivered",
  ];

  bool showDropdown = false;

  void showOrderStatusMenu(
    BuildContext context,
    List<String> statuses,
    Function(String) onSelected,
  ) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: "Select Status",
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, anim1, anim2) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(bottom: 60),
              padding: const EdgeInsets.all(16),
              width: MediaQuery.of(context).size.width * 0.9,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: statuses.map((status) {
                  return ListTile(
                    title: Center(child: Text(status)),
                    onTap: () {
                      Navigator.pop(context);
                      onSelected(status);
                    },
                  );
                }).toList(),
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, anim1, anim2, child) {
        return SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0, 1),
            end: Offset.zero,
          ).animate(anim1),
          child: child,
        );
      },
    );
  }

  Future getOrdersByMerchant() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT * FROM Orders WHERE ${widget.custId != '' ? "cust_id = '${widget.custId}'" : "uid = '${prefx.getString("UID")}'"} ",
    );
    print(widget.custId);
    print(
      "SELECT * FROM Orders WHERE ${widget.custId != '' ? "cust_id = '${widget.custId}'" : "uid = '${prefx.getString("UID")}'"} ",
    );
    setState(() {
      orders = results;
    });
  }

  IconData getOrderStatusIcon(String status) {
    switch (status) {
      case 'Pending':
        return Iconsax.document_text;
      case 'Preparing':
        return Iconsax.setting_2;
      case 'ReadyToShip':
        return Iconsax.box;
      case 'Shipping':
        return Iconsax.truck_fast;
      case 'Delivered':
        return Iconsax.tick_circle;
      default:
        return Iconsax.document_text; // حالة غير معروفة
    }
  }

  @override
  void initState() {
    getOrdersByMerchant();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    getOrdersByMerchant();
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () {
            context.go('/home');
          },
          icon: Icon(Iconsax.arrow_circle_left),
        ),
        forceMaterialTransparency: true,
        centerTitle: true,
        title: Text("Shipping Details", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: List.generate(orders.length, (i) {
            return ListTile(
              onTap: () async {
                SharedPreferences prefx = await SharedPreferences.getInstance();
                String custId = "";
                if (widget.custId != null) {
                  custId = prefx.getString("UID")!;
                }
                AppUtils.sNavigateToReplace(
                  navigatorKey.currentState!.context,
                  '/invoice',
                  {
                    'orderId': orders[i]['oid'],
                    'shipId': orders[i]['ship_id'],
                    'custId': custId,
                  },
                );
              },
              leading: Icon(Iconsax.document_text),
              title: Text("Order No: #${orders[i]['id']}"),
              trailing: IconButton(
                icon: Icon(getOrderStatusIcon(orders[i]['status'])),
                onPressed: () {
                  if (widget.custId == "") {
                    showOrderStatusMenu(context, orderStatusEn, (
                      selectedStatus,
                    ) async {
                      await AppUtils.makeRequests(
                        "query",
                        "UPDATE Orders SET status = '$selectedStatus' WHERE id = '${orders[i]['id']}' ",
                      );
                      var customer_id = await AppUtils.makeRequests(
                        "fetch",
                        "SELECT uid FROM Shipping_Orders WHERE id = '${orders[i]['ship_id']}' ",
                      );
                      var user_fcmToken = await AppUtils.makeRequests(
                        "fetch",
                        "SELECT fcm_token FROM Users WHERE uid = '${customer_id[0]['uid']}' ",
                      );
                      switch (selectedStatus) {
                        case "Pending":
                          PushNotificationService.sendNotificationToUser(
                            user_fcmToken[0]['fcm_token'].toString(),
                            "Your order is under review",
                            "Your order is being reviewed by the seller. We'll notify you once it's confirmed.",
                          );
                          var requestEmp = await AppUtils.makeRequests(
                            "fetch",
                            "SELECT * FROM employees",
                          );
                          for (var reqx in requestEmp) {
                            PushNotificationService.sendNotificationToUser(
                              reqx['fcm_token'].toString(),
                              "Your order is under review",
                              "Your order is being reviewed by the seller. We'll notify you once it's confirmed.",
                            );
                          }
                          await AppUtils.makeRequests(
                            "query",
                            "INSERT INTO Notifications VALUES(NULL, 'Your order is under review', 'Your order is being reviewed by the seller. We will notify you once it is confirmed.', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                          );
                        case "Preparing":
                          PushNotificationService.sendNotificationToUser(
                            user_fcmToken[0]['fcm_token'].toString(),
                            "We're preparing your order!",
                            "Your order is being carefully prepared. Get ready!",
                          );
                          var requestEmp = await AppUtils.makeRequests(
                            "fetch",
                            "SELECT * FROM employees",
                          );
                          for (var reqx in requestEmp) {
                            PushNotificationService.sendNotificationToUser(
                              reqx['fcm_token'].toString(),
                              "We're preparing your order!",
                              "Your order is being carefully prepared. Get ready!",
                            );
                          }
                          await AppUtils.makeRequests(
                            "query",
                            "INSERT INTO Notifications VALUES(NULL, 'We are preparing your order!', 'Your order is being carefully prepared. Get ready!', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                          );
                        case "ReadyToShip":
                          PushNotificationService.sendNotificationToUser(
                            user_fcmToken[0]['fcm_token'].toString(),
                            "Your order is ready to ship",
                            "The seller finished preparing your order. It’ll be shipped shortly.",
                          );
                          var requestEmp = await AppUtils.makeRequests(
                            "fetch",
                            "SELECT * FROM employees",
                          );
                          for (var reqx in requestEmp) {
                            PushNotificationService.sendNotificationToUser(
                              reqx['fcm_token'].toString(),
                              "Your order is ready to ship",
                              "The seller finished preparing your order. It’ll be shipped shortly.",
                            );
                          }
                          await AppUtils.makeRequests(
                            "query",
                            "INSERT INTO Notifications VALUES(NULL, 'Your order is ready to ship', 'The seller finished preparing your order. It’ll be shipped shortly.', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                          );
                        case "Shipping":
                          PushNotificationService.sendNotificationToUser(
                            user_fcmToken[0]['fcm_token'].toString(),
                            "Your order is on the way",
                            "The delivery driver has picked up your order. It’s on the way!",
                          );
                          var requestEmp = await AppUtils.makeRequests(
                            "fetch",
                            "SELECT * FROM employees",
                          );
                          for (var reqx in requestEmp) {
                            PushNotificationService.sendNotificationToUser(
                              reqx['fcm_token'].toString(),
                              "Your order is on the way",
                              "The delivery driver has picked up your order. It’s on the way!",
                            );
                          }
                          await AppUtils.makeRequests(
                            "query",
                            "INSERT INTO Notifications VALUES(NULL, 'Your order is on the way', 'The delivery driver has picked up your order. It’s on the way!', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                          );
                        case "Delivered":
                          PushNotificationService.sendNotificationToUser(
                            user_fcmToken[0]['fcm_token'].toString(),
                            "Order delivered successfully",
                            "Your order has been delivered. Hope you enjoy it!",
                          );
                          var requestEmp = await AppUtils.makeRequests(
                            "fetch",
                            "SELECT * FROM employees",
                          );
                          for (var reqx in requestEmp) {
                            PushNotificationService.sendNotificationToUser(
                              reqx['fcm_token'].toString(),
                              "Order delivered successfully",
                              "Your order has been delivered. Hope you enjoy it!",
                            );
                          }
                          await AppUtils.makeRequests(
                            "query",
                            "INSERT INTO Notifications VALUES(NULL, 'Order delivered successfully', 'Your order has been delivered. Hope you enjoy it!', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                          );
                          break;
                        default:
                      }
                    });
                  }
                },
              ),
            );
          }),
        ),
      ),
    );
  }
}
