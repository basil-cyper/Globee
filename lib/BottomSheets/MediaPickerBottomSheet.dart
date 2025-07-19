import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Routes/App_Router.dart' as MyApp;
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MediaPickerBottomSheet {
  static final ImagePicker _picker = ImagePicker();

  // Method to open Camera for Image or Video
  static Future<XFile?> openCamera(BuildContext context, bool isVideo) async {
    XFile? file;
    print("📸 فتح الكاميرا عشان ${isVideo ? 'فيديو' : 'صورة'}");

    if (isVideo) {
      file = await _picker.pickVideo(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: Duration(
          seconds: Provider.of<AppProvider>(
            context,
            listen: false,
          ).videoDuration,
        ),
      );
    } else {
      file = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
      );
    }
    return file;
  }

  static Future<XFile?> openGallery(BuildContext context, bool isVideo) async {
    XFile? file;
    if (isVideo) {
      file = await _picker.pickVideo(
        source: ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: Duration(
          seconds: Provider.of<AppProvider>(
            context,
            listen: false,
          ).videoDuration,
        ),
      );
    } else {
      file = await _picker.pickImage(
        source: ImageSource.gallery,
        preferredCameraDevice: CameraDevice.rear,
      );
    }
    return file;
  }

  static void showPrimaryOptions(BuildContext context, bool navigate) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return MediaPickerPrimaryOptions(navigate: navigate);
      },
    );
  }

  static void showSecondaryOptions(
    BuildContext context, {
    required bool isVideo,
    bool navigate = true,
    String? lang,
  }) {
    // أول حاجة نفتح البوتوم شيت فاضي
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return FutureBuilder(
          future: AppUtils.makeRequests("fetch", "SELECT $lang FROM Languages"),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Container(
                height: 150,
                alignment: Alignment.center,
                child: SpinKitDoubleBounce(
                  color: AppTheme.primaryColor,
                  size: 30.0,
                ),
              );
            }

            if (snapshot.hasError) {
              return Container(
                height: 150,
                alignment: Alignment.center,
                child: Text('حصل خطأ في تحميل اللغة'),
              );
            }

            var results = snapshot.data as List;

            return Directionality(
              textDirection: lang == 'arb'
                  ? TextDirection.rtl
                  : TextDirection.ltr,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      leading: const Icon(Iconsax.camera),
                      title: Text(
                        isVideo ? results[13][lang] : results[9][lang],
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        openCamera(context, isVideo).then((value) {
                          if (value != null) {
                            Provider.of<AppProvider>(
                              MyApp.navigatorKey.currentContext!,
                              listen: false,
                            ).addNewMedia(value.path);

                            if (navigate) {
                              setItemData();
                              MyApp.navigatorKey.currentContext!.go(
                                '/addDetails',
                              );
                            }
                          }
                        });
                      },
                    ),
                    ListTile(
                      leading: const Icon(Iconsax.gallery),
                      title: Text(
                        isVideo ? results[14][lang] : results[10][lang],
                      ),
                      onTap: () {
                        Navigator.pop(context);

                        openGallery(context, isVideo).then((value) async {
                          if (value != null) {
                            Provider.of<AppProvider>(
                              MyApp.navigatorKey.currentContext!,
                              listen: false,
                            ).addNewMedia(value.path);

                            if (navigate) {
                              setItemData();
                              MyApp.navigatorKey.currentContext!.go(
                                '/addDetails',
                              );
                            }
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class MediaPickerPrimaryOptions extends StatefulWidget {
  final bool navigate;
  const MediaPickerPrimaryOptions({Key? key, required this.navigate})
    : super(key: key);

  @override
  State<MediaPickerPrimaryOptions> createState() =>
      _MediaPickerPrimaryOptionsState();
}

class _MediaPickerPrimaryOptionsState extends State<MediaPickerPrimaryOptions> {
  bool isLoading = true;
  List? results;
  String lang = 'arb';

  @override
  void initState() {
    super.initState();
    _loadLanguageData();
  }

  Future<void> _loadLanguageData() async {
    final prefx = await SharedPreferences.getInstance();
    lang = prefx.getString("Lang") ?? 'arb';

    var res = await AppUtils.makeRequests(
      "fetch",
      "SELECT $lang FROM Languages",
    );

    if (mounted) {
      setState(() {
        results = res;
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading || results == null) {
      return Container(
        height: 150,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Center(
          child: SpinKitDoubleBounce(color: AppTheme.primaryColor, size: 30.0),
        ),
      );
    }

    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Iconsax.camera),
              title: Text(results![11][lang]),
              onTap: () {
                Navigator.pop(context);
                MediaPickerBottomSheet.showSecondaryOptions(
                  context,
                  isVideo: false,
                  navigate: widget.navigate,
                  lang: lang,
                );
              },
            ),
            ListTile(
              leading: const Icon(Iconsax.video),
              title: Text(results![12][lang]),
              trailing: GestureDetector(
                onTap: () {
                  var appProvider = Provider.of<AppProvider>(
                    context,
                    listen: false,
                  );
                  appProvider.setViduration(
                    appProvider.videoDuration == 60 ? 15 : 60,
                  );
                  setState(() {}); // لتحديث الرقم الظاهر
                },
                child: Text(
                  Provider.of<AppProvider>(context).videoDuration == 60
                      ? '1m'
                      : '15s',
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                MediaPickerBottomSheet.showSecondaryOptions(
                  context,
                  isVideo: true,
                  navigate: widget.navigate,
                  lang: lang,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

setItemData() async {
  final response = await AppUtils.makeRequests(
    "query",
    "INSERT INTO Items (id) VALUES (NULL)",
  );

  if (response.containsKey('id')) {
    final itemId = response['id'];
    print("آخر ID تم إدخاله هو: $itemId");

    final currentContext = MyApp.navigatorKey.currentContext;
    if (currentContext != null && currentContext.mounted) {
      Provider.of<AppProvider>(currentContext, listen: false).setItemId(itemId);
    } else {
      print("Navigator Context مش موجود أو مش شغال دلوقتي.");
    }
  } else {
    print("في مشكلة حصلت: ${response['error']}");
  }
}
