import 'dart:io';

import 'package:globee/Core/PushNotificationsServiceOrders.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Button_Widget.dart';
import 'package:globee/Widgets/DropdownFormField.dart';
import 'package:globee/Widgets/Input_Widget.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ShippingOrders extends StatefulWidget {
  const ShippingOrders({super.key});

  @override
  State<ShippingOrders> createState() => _ShippingOrdersState();
}

class _ShippingOrdersState extends State<ShippingOrders> {
  TextEditingController fullName = TextEditingController();
  TextEditingController mobileNumber = TextEditingController();
  TextEditingController email = TextEditingController();
  TextEditingController zoneNo = TextEditingController();
  TextEditingController streetNo = TextEditingController();
  TextEditingController buildNo = TextEditingController();
  String? selectedCountry;
  String? selectedCity;
  bool saveAddress = false;
  bool openAddressForm = false;
  int isActive = -1;

  List<String> arabCountries = [
    "Algeria",
    "Bahrain",
    "Comoros",
    "Djibouti",
    "Egypt",
    "Iraq",
    "Jordan",
    "Kuwait",
    "Lebanon",
    "Libya",
    "Mauritania",
    "Morocco",
    "Oman",
    "Palestine",
    "Qatar",
    "Saudi Arabia",
    "Somalia",
    "Sudan",
    "Syria",
    "Tunisia",
    "United Arab Emirates",
    "Yemen",
  ];

  double shippingFee = 10.0;
  List cartOrders = [];
  double totalPrices = 0.0;
  double finalTotalFinish = 0.0;
  List arabCities = [];
  List addressesList = [];

  Future getCartOrders() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var orders = await AppUtils.makeRequests(
      "fetch",
      "SELECT Cart.id AS id, Items.`name`, Items.id AS itmid,Items.price, Items.media,Items.uid, Cart.qtt FROM Cart LEFT JOIN Items ON Cart.item_id = Items.id WHERE Cart.order_id = '${prefx.getString("OID")}'",
    );

    setState(() {
      cartOrders = orders;
      totalPrices = 0.0; // لازم تصفره قبل التكرار
      for (var cartOrder in cartOrders) {
        totalPrices +=
            double.parse(cartOrder['price'].toString()) *
            double.parse(cartOrder['qtt'].toString());
      }
      finalTotalFinish = totalPrices + shippingFee;
    });
  }

  Future getCurrentUser() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var user = await AppUtils.makeRequests(
      "fetch",
      "SELECT Fullname, PhoneNumber FROM Users WHERE uid = '${prefx.getString("UID")}' ",
    );
    setState(() {
      fullName.text = user[0]['Fullname'];
      mobileNumber.text = user[0]['PhoneNumber'];
    });
  }

  Future getShippingAddresses() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var addresses = await AppUtils.makeRequests(
      "fetch",
      "SELECT * FROM Shipping_Orders WHERE uid = '${prefx.getString("UID")}' ",
    );
    setState(() {
      addressesList = addresses;
    });
  }

  Future getArabCities() async {
    var request = await Dio().get(
      "https://countriesnow.space/api/v0.1/countries",
    );
    var response = request.data;
    for (var i = 0; i < response['data'].length; i++) {
      if (response['data'][i]['country'] == selectedCountry) {
        setState(() {
          arabCities = response['data'][i]['cities'];
        });
      }
    }
  }

  String lang = "eng";
  List languages = [];

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    setState(() {
      lang = prefx.getString("Lang") ?? "eng";
      getLangDB();
    });
  }

  Future getLangDB() async {
    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT $lang FROM Languages ",
    );
    setState(() {
      languages = results;
    });
  }

  @override
  void initState() {
    getLang();
    getCurrentUser();
    getShippingAddresses();
    getCartOrders();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    if (languages.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    getArabCities();
    final isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom != 0;
    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: GestureDetector(
        onTap: () {
          FocusScope.of(context).unfocus();
        },
        child: Scaffold(
          resizeToAvoidBottomInset: true,
          backgroundColor: Colors.white,
          appBar: AppBar(
            leading: IconButton(
              onPressed: () {
                context.go('/CheckoutSummary');
              },
              icon: Icon(Iconsax.arrow_circle_left),
            ),
            forceMaterialTransparency: true,
            centerTitle: true,
            title: Text(
              languages[58][lang],
              style: TextStyle(color: Colors.black),
            ),
            backgroundColor: Colors.white,
          ),
          body: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    children: [
                      ...List.generate(addressesList.length, (i) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              isActive = i;
                              Provider.of<AppProvider>(
                                context,
                                listen: false,
                              ).setSelectedAddress(addressesList[i]);
                              Provider.of<AppProvider>(
                                context,
                                listen: false,
                              ).setShipId(addressesList[i]['id']);
                              print(
                                Provider.of<AppProvider>(
                                  context,
                                  listen: false,
                                ).shipId,
                              );
                            });
                          },
                          child: Directionality(
                            textDirection: TextDirection.ltr,
                            child: SizedBox(
                              width: double.maxFinite,
                              height: 80,
                              child: Card(
                                shape: RoundedRectangleBorder(
                                  side: isActive == i
                                      ? BorderSide(
                                          color: Colors.black,
                                          width: 2,
                                        )
                                      : BorderSide.none,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                color: Colors.grey.shade100,
                                elevation: 0,
                                child: Row(
                                  children: [
                                    SizedBox(width: 10),
                                    Icon(Iconsax.location),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "${addressesList[i]['City']}, ${addressesList[i]['Country']}",
                                          ),
                                          Text(
                                            "Zone: ${addressesList[i]['Zone Number']}, Street: ${addressesList[i]['Street Number']}, Building: ${addressesList[i]['Building Number']}",
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                      SizedBox(height: 10),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            openAddressForm = !openAddressForm;
                          });
                        },
                        child: ButtonWidget(
                          btnText: openAddressForm
                              ? languages[60][lang]
                              : languages[59][lang],
                        ),
                      ),
                      SizedBox(height: 10),
                    ],
                  ),
                ),
              ),

              if (openAddressForm)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Column(
                      children: [
                        InputWidget(
                          icontroller: fullName,
                          iHint: languages[7][lang],
                        ),
                        SizedBox(height: 15),
                        InputWidget(
                          icontroller: mobileNumber,
                          iHint: languages[2][lang],
                          ikeyboardType: TextInputType.phone,
                        ),
                        SizedBox(height: 15),
                        InputWidget(
                          icontroller: email,
                          iHint: languages[61][lang],
                        ),
                        SizedBox(height: 15),
                        DropdownFormMenuField(
                          iHint: languages[62][lang],
                          dItems: arabCountries.map((country) {
                            return DropdownMenuItem<String>(
                              value: country,
                              child: Text(country),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedCountry = val!;
                              getArabCities();
                            });
                          },
                        ),
                        SizedBox(height: 15),
                        DropdownFormMenuField(
                          iHint: languages[63][lang],
                          dItems: arabCities.map((city) {
                            return DropdownMenuItem<String>(
                              value: city,
                              child: Text(city),
                            );
                          }).toList(),
                          onChanged: (val) {
                            setState(() {
                              selectedCity = val!;
                            });
                          },
                        ),
                        SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: InputWidget(
                                icontroller: zoneNo,
                                iHint: languages[64][lang],
                                ikeyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 15),
                            Expanded(
                              child: InputWidget(
                                icontroller: streetNo,
                                iHint: languages[65][lang],
                                ikeyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 15),
                        InputWidget(
                          icontroller: buildNo,
                          iHint: languages[66][lang],
                          ikeyboardType: TextInputType.number,
                        ),
                        Container(
                          alignment: Alignment.centerLeft,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Checkbox(
                                value: saveAddress,
                                onChanged: (value) {
                                  setState(() {
                                    saveAddress = value!;
                                    isActive = 0;
                                  });
                                },
                              ),
                              SizedBox(width: 8),
                              Text(
                                languages[67][lang],
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 70),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          floatingActionButtonLocation:
              FloatingActionButtonLocation.centerDocked,
          floatingActionButton: isKeyboardOpen
              ? null
              : GestureDetector(
                  onTap: () async {
                    if (isActive != -1) {
                      SharedPreferences prefx =
                          await SharedPreferences.getInstance();

                      if (saveAddress == true) {
                        // 1. Add the record
                        await AppUtils.makeRequests(
                          "query",
                          "INSERT INTO Shipping_Orders VALUES(NULL, '${fullName.text}', '${mobileNumber.text}', '${email.text}', '$selectedCountry', '$selectedCity', '${zoneNo.text}', '${streetNo.text}', '${buildNo.text}', '${prefx.getString("UID")}','${prefx.getString("OID")}')",
                        );

                        // 2. Get the latest inserted record for this user and order
                        var latestAddress = await AppUtils.makeRequests(
                          "fetch",
                          "SELECT * FROM Shipping_Orders WHERE uid = '${prefx.getString("UID")}' AND oid = '${prefx.getString("OID")}' ORDER BY id DESC LIMIT 1",
                        );

                        print("Latest address added:");
                        Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).setSelectedAddress(latestAddress[0]);
                        Provider.of<AppProvider>(
                          context,
                          listen: false,
                        ).setShipId(latestAddress[0]['id']);
                      }
                      // هات البائعين الفريدين
                      final Set<dynamic> sellerUids = cartOrders
                          .map((order) => order['uid'])
                          .toSet();

                      // هات اسم العميل
                      print(
                        "SELECT Fullname FROM Users WHERE uid = '${prefx.getString("UID")}'",
                      );
                      var customerName = await AppUtils.makeRequests(
                        "fetch",
                        "SELECT Fullname FROM Users WHERE uid = '${prefx.getString("UID")}'",
                      );
                      if (customerName is Map<String, dynamic>) {
                        customerName = [customerName];
                      }
                      List results = [];
                      for (var sellerUid in sellerUids) {
                        // فلترة المنتجات الخاصة بالبائع ده فقط
                        final sellerProducts = cartOrders
                            .where((e) => e['uid'] == sellerUid)
                            .toList();

                        // إضافة Order جديد للبائع
                        print(
                          "INSERT INTO Orders VALUES (NULL, '$sellerUid', '${prefx.getString("UID")}', '${prefx.getString("OID")}', '${Provider.of<AppProvider>(context, listen: false).shipId}', '${DateTime.now().toString()}', 'pending')",
                        );
                        await AppUtils.makeRequests(
                          "query",
                          "INSERT INTO Orders VALUES (NULL, '$sellerUid', '${prefx.getString("UID")}', '${prefx.getString("OID")}', '${Provider.of<AppProvider>(context, listen: false).shipId}', '${DateTime.now().toString()}', 'pending')",
                        );
                        // ابعت إشعار للبائع
                        results = await AppUtils.makeRequests(
                          "fetch",
                          "SELECT fcm_token FROM Users WHERE uid = '$sellerUid'",
                        );
                      }

                      if (results is Map<String, dynamic>) {
                        results = [results];
                      }
                      print("RESSSSS $results");
                      for (var result in results) {
                        print(result['fcm_token']);
                        PushNotificationServiceOrders.sendNotificationToUser(
                          result['fcm_token'],
                          "${languages[74][lang]} (${customerName[0]['Fullname']})",
                          "${languages[75][lang]} ${languages[76][lang]}",
                          prefx.getString("OID").toString(),
                          Provider.of<AppProvider>(
                            context,
                            listen: false,
                          ).shipId,
                        );
                      }

                      var requestEmp = await AppUtils.makeRequests(
                        "fetch",
                        "SELECT * FROM employees",
                      );
                      for (var reqx in requestEmp) {
                        print(reqx['fcm_token']);
                        PushNotificationServiceOrders.sendNotificationToUser(
                          reqx['fcm_token'].toString(),
                          "${languages[74][lang]} (${customerName[0]['Fullname']})",
                          "${languages[75][lang]} ${languages[76][lang]}",
                          prefx.getString("OID").toString(),
                          Provider.of<AppProvider>(
                            context,
                            listen: false,
                          ).shipId,
                        );
                      }

                      await AppUtils.makeRequests(
                        "query",
                        "INSERT INTO Notifications VALUES(NULL, '${languages[74][lang]} (${customerName[0]['Fullname']})', '${languages[75][lang]} ${languages[76][lang]}', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                      );
                      if (mounted) {
                        context.go('/paymentSuccess');
                      }
                    } else {
                      AppUtils.snackBarShowing(context, languages[122][lang]);
                    }
                  },

                  child: SizedBox(
                    height: 60,
                    child: ButtonWidget(
                      btnText: lang == "arb" ? "تأكيد الطلب" : "Place Order",
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
