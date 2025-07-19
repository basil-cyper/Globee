import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:globee/BottomSheets/MediaPickerBottomSheet.dart';
import 'package:globee/Core/PushNotificationsService.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Back_Button.dart';
import 'package:globee/Widgets/Input_Widget.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path/path.dart' as p;

class AddItems extends StatefulWidget {
  const AddItems({super.key});

  @override
  State<AddItems> createState() => _AddItemsState();
}

class _AddItemsState extends State<AddItems> {
  TextEditingController itemController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController qttController = TextEditingController();
  TextEditingController sellerController = TextEditingController();
  TextEditingController mazoController = TextEditingController();
  TextEditingController descController = TextEditingController();
  final Map<int, BetterPlayerController> _videoControllers = {};
  String lang = "eng";
  List languages = [];
  List currentUser = [];
  List<String> uploadedFiles = [];

  double mazoPercentage = 0.30; // أو أي نسبة تانية

  void onPriceChanged(String value) {
    double totalPrice = double.tryParse(value) ?? 0;
    mazoController.text = (totalPrice * mazoPercentage).toString();
    sellerController.text = (totalPrice - double.parse(mazoController.text))
        .toString();
    setState(() {});
  }

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    setState(() {
      lang = prefx.getString("Lang")!;
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

  Future getCurrentUser() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT Fullname FROM Users WHERE uid = '${prefx.getString("UID")}'",
    );
    setState(() {
      currentUser = results;
    });
  }

  @override
  void initState() {
    getLang();
    getCurrentUser();
    super.initState();
  }

  int currentPage = 0;

  void initializeVideoController(String path, int index) {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      "file://$path",
    );
    final controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        aspectRatio: 9 / 16,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableMute: true,
          showControls: false,
        ),
      ),
      betterPlayerDataSource: dataSource,
    );
    controller.setVolume(0);

    // هنا هنضيف الـ Listener اللي هيعمل تحديث لحظي
    controller.videoPlayerController?.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });

    _videoControllers[index] = controller;
  }

  String merchant = "";

  void disposeVideoController(int index) async {
    if (_videoControllers.containsKey(index)) {
      await Future.delayed(Duration(milliseconds: 300)); // تأخير صغير
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }
  }

  GlobalKey<FormState> addItemsFormKey = GlobalKey<FormState>();
  double uploadProgress = 0.0;
  bool isUploading = false;

  Future<void> uploadAll(
    List<String> filesToUpload,
    String itemId,
    String itemTxt,
  ) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    for (int i = 0; i < filesToUpload.length; i++) {
      final file = filesToUpload[i];
      final formData = FormData.fromMap({
        "file": await MultipartFile.fromFile(
          file,
          filename: file.split('/').last,
        ),
        "itemId": itemId,
        "k": DateTime.now().millisecondsSinceEpoch,
      });

      await Dio().post(
        'https://pos7d.site/Globee/Upload.php',
        data: formData,
        onSendProgress: (int sent, int total) {
          setState(() {
            uploadProgress =
                (sent / total) * ((1 / filesToUpload.length) * (i + 1));
          });
        },
      );
    }
  }

  @override
  void dispose() {
    _videoControllers.forEach((key, controller) => controller.dispose());
    _videoControllers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaList = Provider.of<AppProvider>(context).media;
    final provx = Provider.of<AppProvider>(context);
    return Form(
      key: addItemsFormKey,
      child: languages.isEmpty
          ? Scaffold()
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Directionality(
                textDirection: lang == 'arb'
                    ? TextDirection.rtl
                    : TextDirection.ltr,
                child: Stack(
                  children: [
                    Scaffold(
                      resizeToAvoidBottomInset: false,
                      backgroundColor: Colors.white,
                      appBar: AppBar(
                        backgroundColor: Colors.transparent,
                        forceMaterialTransparency: true,
                        title: Text(
                          languages[15][lang],
                          style: TextStyle(color: Colors.black),
                        ),
                        centerTitle: true,
                        actions: [
                          IconButton(
                            onPressed: () async {
                              if (addItemsFormKey.currentState!.validate()) {
                                setState(() {
                                  isUploading = true;
                                  uploadProgress = 0.0;
                                });
                                SharedPreferences prefx =
                                    await SharedPreferences.getInstance();
                                String visibility = provx.isVisibility
                                    ? "Public"
                                    : "Private";
                                String comments = provx.isComments
                                    ? "On"
                                    : "Off";
                                final filesToUpload = List<String>.from(
                                  mediaList,
                                );
                                final itemId = provx.itemId;

                                // حفظ بيانات العنصر أولًا
                                await AppUtils.makeRequests(
                                  "query",
                                  "UPDATE Items SET name = '${itemController.text}', price = '${priceController.text}', qtt = '${qttController.text}', description = '${descController.text}', visibility = '$visibility', comments = '$comments', uid = '${prefx.getString("UID")}', created_at = '${DateTime.now()}' WHERE id = '$itemId'",
                                );

                                await uploadAll(
                                  filesToUpload,
                                  itemId.toString(),
                                  itemController.text,
                                );

                                // ارسال اشعارات المتابعين
                                var resultsPush = await AppUtils.makeRequests(
                                  "fetch",
                                  "SELECT * FROM Followers WHERE buyer_id = '${prefx.getString("UID")}'",
                                );
                                if (resultsPush[0] != null) {
                                  for (var resultPo in resultsPush) {
                                    PushNotificationService.sendNotificationToUser(
                                      resultPo['user_token'],
                                      "${languages[117][lang]} ${currentUser[0]['Fullname']}",
                                      itemController.text.toString(),
                                    );
                                  }
                                }

                                // ارسال اشعارات الموظفين
                                var requestEmp = await AppUtils.makeRequests(
                                  "fetch",
                                  "SELECT * FROM employees",
                                );
                                if (requestEmp[0] != null) {
                                  for (var reqx in requestEmp) {
                                    PushNotificationService.sendNotificationToUser(
                                      reqx['fcm_token'].toString(),
                                      "${languages[117][lang]} ${currentUser[0]['Fullname']}",
                                      itemController.text.toString(),
                                    );
                                  }
                                }

                                // تحديث آخر نشاط
                                await AppUtils.makeRequests(
                                  "query",
                                  "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}'",
                                );

                                // اضافة اشعار جديد
                                await AppUtils.makeRequests(
                                  "query",
                                  "INSERT INTO Notifications VALUES(NULL, '${languages[117][lang]} ${currentUser[0]['Fullname']}', '${itemController.text.toString()}', '${DateTime.now().toString().split(' ')[0]}', 'false')",
                                );

                                // تنظيف القائمة واعادة الحالة
                                mediaList.clear();
                                setState(() {
                                  isUploading = false;
                                  uploadProgress = 0.0;
                                });

                                // اذهب للصفحة الرئيسية
                                context.go('/home');
                              }
                            },
                            icon: Transform.flip(
                              flipX: lang == 'arb' ? true : false,
                              child: Icon(Iconsax.send_1),
                            ),
                          ),
                        ],
                      ),
                      body: SingleChildScrollView(
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      width: 200,
                                      height: 150,
                                      child: Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              10,
                                            ),
                                            child: PageView.builder(
                                              itemCount: mediaList.length,
                                              onPageChanged: (newPage) {
                                                // لما الصفحة تتغير، نوقف الفيديو القديم
                                                disposeVideoController(
                                                  currentPage,
                                                );
                                                currentPage = newPage;
                                                // لو فيديو جديد، نهيئ الكنترولر
                                                final path =
                                                    mediaList[currentPage];
                                                if (path.endsWith('.mp4') ||
                                                    path.endsWith('.MOV')) {
                                                  initializeVideoController(
                                                    path,
                                                    currentPage,
                                                  );
                                                  setState(() {});
                                                }
                                              },
                                              itemBuilder: (context, index) {
                                                final path = mediaList[index];

                                                final lowerPath = path
                                                    .toLowerCase();

                                                if (lowerPath.endsWith(
                                                      '.mp4',
                                                    ) ||
                                                    lowerPath.endsWith(
                                                      '.mov',
                                                    )) {
                                                  if (!_videoControllers
                                                      .containsKey(index)) {
                                                    initializeVideoController(
                                                      path,
                                                      index,
                                                    );
                                                  }
                                                  final controller =
                                                      _videoControllers[index];
                                                  if (controller == null) {
                                                    return Center(
                                                      child:
                                                          SpinKitDoubleBounce(
                                                            color: AppTheme
                                                                .primaryColor,
                                                            size: 30.0,
                                                          ),
                                                    );
                                                  }
                                                  return AspectRatio(
                                                    aspectRatio: 9 / 16,
                                                    child: BetterPlayer(
                                                      controller: controller,
                                                    ),
                                                  );
                                                } else {
                                                  return Image.file(
                                                    File(path),
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                              },
                                            ),
                                          ),

                                          GestureDetector(
                                            onTap: () {
                                              MediaPickerBottomSheet.showPrimaryOptions(
                                                context,
                                                false,
                                              );
                                            },
                                            child: Container(
                                              margin: EdgeInsets.all(5),
                                              width: 30,
                                              height: 30,
                                              decoration: BoxDecoration(
                                                color: Colors.black.withOpacity(
                                                  0.5,
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                              child: Icon(
                                                Iconsax.add_circle,
                                                color: Colors.white,
                                                size: 22,
                                              ),
                                            ),
                                          ),
                                          Align(
                                            alignment: Alignment.bottomRight,
                                            child: Visibility(
                                              visible:
                                                  _videoControllers
                                                      .isNotEmpty &&
                                                  _videoControllers[currentPage] !=
                                                      null,
                                              child: Container(
                                                margin: const EdgeInsets.all(5),
                                                decoration: BoxDecoration(
                                                  color: Colors.black
                                                      .withOpacity(0.5),
                                                  borderRadius:
                                                      BorderRadius.circular(5),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 10,
                                                    ),
                                                child: Builder(
                                                  builder: (context) {
                                                    final controller =
                                                        _videoControllers[currentPage];
                                                    if (controller != null) {
                                                      final duration =
                                                          controller
                                                              .videoPlayerController
                                                              ?.value
                                                              .position ??
                                                          Duration.zero;

                                                      final minutes = duration
                                                          .inMinutes
                                                          .remainder(60)
                                                          .toString()
                                                          .padLeft(2, '0');
                                                      final seconds = duration
                                                          .inSeconds
                                                          .remainder(60)
                                                          .toString()
                                                          .padLeft(2, '0');

                                                      return Text(
                                                        "$minutes:$seconds",
                                                        style: const TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                      );
                                                    } else {
                                                      return const Text(
                                                        "Loading...",
                                                        style: TextStyle(
                                                          color: Colors.white,
                                                          fontSize: 14,
                                                        ),
                                                      );
                                                    }
                                                  },
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Container(
                                      margin: EdgeInsets.symmetric(
                                        horizontal: 10,
                                      ),
                                      child: SizedBox(
                                        width: 200,
                                        height: 150,
                                        child: TextFormField(
                                          validator: (val) {
                                            if (val!.isEmpty) {
                                              return languages[17][lang];
                                            }
                                            return null;
                                          },
                                          controller: itemController,
                                          decoration: InputDecoration(
                                            hintText: languages[16][lang],
                                            enabledBorder: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderSide: BorderSide.none,
                                            ),
                                          ),
                                          maxLines: null,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Divider(thickness: 0.4),
                              InputWidget(
                                icontroller: priceController,
                                iHint: languages[18][lang],
                                ikeyboardType: TextInputType.number,
                                ichanged: (val) {
                                  onPriceChanged(val);
                                },
                                iValid: (val) {
                                  if (val!.isEmpty) {
                                    return languages[19][lang];
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              Row(
                                children: [
                                  // زرار الإضافة
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        int current =
                                            int.tryParse(qttController.text) ??
                                            0;
                                        current++;
                                        qttController.text = current.toString();
                                      },
                                      child: RectButtonWidget(
                                        bicon: Iconsax.add,
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // حقل الرقم
                                  Expanded(
                                    flex: 3,
                                    child: InputWidget(
                                      icontroller: qttController,
                                      iHint: languages[125][lang],
                                      ikeyboardType: TextInputType.number,
                                      ichanged: (val) {},
                                      iValid: (val) {
                                        if (val!.isEmpty) {
                                          return languages[126][lang];
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  // زرار التنقيص
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        int current =
                                            int.tryParse(qttController.text) ??
                                            0;
                                        if (current > 0) {
                                          current--;
                                          qttController.text = current
                                              .toString();
                                        }
                                      },
                                      child: RectButtonWidget(
                                        bicon: Iconsax.minus,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              // SizedBox(height: 20),
                              // Row(
                              //   children: [
                              //     Expanded(
                              //       child: InputWidget(
                              //         icontroller: sellerController,
                              //         iHint: languages[123][lang],
                              //         ikeyboardType: TextInputType.number,
                              //         isRead: true,
                              //       ),
                              //     ),
                              //     SizedBox(width: 20),
                              //     Expanded(
                              //       child: InputWidget(
                              //         icontroller: mazoController,
                              //         iHint: languages[124][lang],
                              //         ikeyboardType: TextInputType.number,
                              //         isRead: true,
                              //       ),
                              //     ),
                              //   ],
                              // ),
                              SizedBox(height: 20),
                              InputWidget(
                                icontroller: descController,
                                iHint: languages[20][lang],
                                iValid: (val) {
                                  if (val!.isEmpty) {
                                    return languages[21][lang];
                                  }
                                  return null;
                                },
                              ),
                              Consumer<AppProvider>(
                                builder: (context, appProvider, _) {
                                  return ListTile(
                                    onTap: () {
                                      appProvider.setVisibility(
                                        !appProvider.isVisibility,
                                      );
                                    },
                                    tileColor: Colors.transparent,
                                    leading: Icon(Iconsax.global),
                                    title: Text(languages[22][lang]),
                                    subtitle: Text(
                                      appProvider.isVisibility
                                          ? languages[24][lang]
                                          : languages[23][lang],
                                      style: TextStyle(
                                        color: appProvider.isVisibility
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    trailing: Icon(
                                      lang == 'arb'
                                          ? Iconsax.arrow_circle_left
                                          : Iconsax.arrow_circle_right,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                              Consumer<AppProvider>(
                                builder: (context, appProvider, _) {
                                  return ListTile(
                                    onTap: () {
                                      appProvider.setComments(
                                        !appProvider.isComments,
                                      );
                                    },
                                    tileColor: Colors.transparent,
                                    leading: Icon(Iconsax.message_text_1),
                                    title: Text(languages[25][lang]),
                                    subtitle: Text(
                                      appProvider.isComments
                                          ? languages[27][lang]
                                          : languages[26][lang],
                                      style: TextStyle(
                                        color: appProvider.isComments
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                    trailing: Icon(
                                      lang == 'arb'
                                          ? Iconsax.arrow_circle_left
                                          : Iconsax.arrow_circle_right,
                                      size: 30,
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      floatingActionButtonLocation:
                          FloatingActionButtonLocation.centerFloat,
                      floatingActionButton: Container(
                        margin: EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          languages[166][lang],
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    ),
                    if (isUploading)
                      Scaffold(
                        backgroundColor: Colors.transparent,
                        body: Container(
                          color: Colors.black.withOpacity(0.5),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircularProgressIndicator(
                                  value: uploadProgress,
                                  strokeWidth: 6,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.blue,
                                  ),
                                ),

                                SizedBox(height: 12),
                                Text(
                                  "${(uploadProgress * 100).toStringAsFixed(0)}%",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 8),
                                Text(
                                  languages[28][lang],
                                  style: TextStyle(color: Colors.white),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
