import 'dart:io';

import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globee/BottomSheets/MediaPickerBottomSheet.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Input_Widget.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EditItems extends StatefulWidget {
  final String itemId;
  const EditItems({super.key, required this.itemId});

  @override
  State<EditItems> createState() => _EditItemsState();
}

class _EditItemsState extends State<EditItems> {
  TextEditingController itemController = TextEditingController();
  TextEditingController priceController = TextEditingController();
  TextEditingController descController = TextEditingController();

  Future getItem() async {
    var items = await AppUtils.makeRequests(
      "fetch",
      "SELECT id, name, price, description, visibility, comments, media FROM Items WHERE id = '${widget.itemId}'",
    );

    setState(() {
      itemController.text = items[0]['name'];
      priceController.text = items[0]['price'];
      descController.text = items[0]['description'];
      Provider.of<AppProvider>(context, listen: false).isVisibility =
          items[0]['visibility'] == "Public";
      Provider.of<AppProvider>(context, listen: false).isComments =
          items[0]['comments'] == "ON";
    });

    // تفريغ الميديا القديمة
    Provider.of<AppProvider>(context, listen: false).media.clear();

    List<String> mediaUrls = [];

    try {
      final rawMedia = items[0]['media'];
      if (rawMedia is String && rawMedia.isNotEmpty) {
        List<String> filenames = rawMedia
            .split(',')
            .map((e) => e.trim())
            .toList();
        mediaUrls = filenames
            .map(
              (file) =>
                  "https://pos7d.site/Globee/sys/uploads/Items/${widget.itemId}/$file",
            )
            .toList();
      }
    } catch (e) {
      print("Error parsing media: $e");
    }

    Dio dio = Dio();
    for (String url in mediaUrls) {
      try {
        final tempDir = await getTemporaryDirectory();
        final fileName = url.split("/").last;
        final filePath = "${tempDir.path}/$fileName";

        await dio.download(
          url,
          filePath,
          options: Options(
            responseType: ResponseType.bytes,
            followRedirects: false,
            receiveTimeout: Duration(seconds: 15),
          ),
        );

        Provider.of<AppProvider>(context, listen: false).addMedia(filePath);
        print(Provider.of<AppProvider>(context, listen: false).media);
      } catch (e) {
        print("Download error with Dio: $e");
      }
    }
    setState(() {});
  }

  final Map<int, BetterPlayerController> _videoControllers = {};
  int currentPage = 0;

  void initializeVideoController(String path, int index) {
    if (_videoControllers.containsKey(index)) {
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.file,
      path,
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

  void disposeVideoController(int index) async {
    if (_videoControllers.containsKey(index)) {
      await Future.delayed(Duration(milliseconds: 300)); // تأخير صغير
      _videoControllers[index]?.dispose();
      _videoControllers.remove(index);
    }
  }

  @override
  void initState() {
    getItem();
    super.initState();
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
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          forceMaterialTransparency: true,
          title: Text("Edit Item", style: TextStyle(color: Colors.black)),
          centerTitle: true,
          actions: [
            IconButton(
              onPressed: () async {
                SharedPreferences prefx = await SharedPreferences.getInstance();
                String visibility = provx.isVisibility ? "Public" : "Private";
                String comments = provx.isComments ? "On" : "Off";
                final filesToUpload = List<String>.from(provx.newMedia);
                mediaList.clear();
                provx.clearNewMedia();

                final itemId = widget.itemId;
                context.go('/home');
                Future.delayed(Duration(milliseconds: 500), () async {
                  mediaList.clear();
                  AppUtils.makeRequests(
                    "query",
                    "UPDATE Items SET name = '${itemController.text}', price = '${priceController.text}', description = '${descController.text}', visibility = '$visibility', comments = '$comments',uid = '${prefx.getString("UID")}', created_at = '${DateTime.now()}' WHERE id = '$itemId'",
                  );
                  for (var file in filesToUpload) {
                    await AppUtils().uploadItems(
                      file,
                      itemId,
                      itemController.text,
                      false,
                    );
                  }
                });
              },
              icon: Icon(Iconsax.send_1),
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
                              borderRadius: BorderRadius.circular(10),
                              child: PageView.builder(
                                itemCount: mediaList.length,
                                onPageChanged: (newPage) {
                                  // لما الصفحة تتغير، نوقف الفيديو القديم
                                  disposeVideoController(currentPage);
                                  currentPage = newPage;
                                  // لو فيديو جديد، نهيئ الكنترولر
                                  final path = mediaList[currentPage];
                                  if (path.endsWith('.mp4')) {
                                    initializeVideoController(
                                      path,
                                      currentPage,
                                    );
                                    setState(() {});
                                  }
                                },
                                itemBuilder: (context, index) {
                                  final path = mediaList[index];

                                  if (path.endsWith('.mp4')) {
                                    if (!_videoControllers.containsKey(index)) {
                                      initializeVideoController(path, index);
                                    }
                                    final controller = _videoControllers[index];
                                    if (controller == null) {
                                      return Center(
                                        child: SpinKitDoubleBounce(
                                          color: AppTheme.primaryColor,
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
                                  color: Colors.black.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
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
                                    _videoControllers.isNotEmpty &&
                                    _videoControllers[currentPage] != null,
                                child: Container(
                                  margin: const EdgeInsets.all(5),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                  padding: const EdgeInsets.symmetric(
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

                                        final minutes = duration.inMinutes
                                            .remainder(60)
                                            .toString()
                                            .padLeft(2, '0');
                                        final seconds = duration.inSeconds
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
                      child: SizedBox(
                        width: 200,
                        height: 150,
                        child: TextFormField(
                          controller: itemController,
                          decoration: InputDecoration(
                            hintText: "Enter title",
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
                  ],
                ),
                Divider(thickness: 0.4),
                InputWidget(
                  icontroller: priceController,
                  iHint: "Enter Item Price",
                  ikeyboardType: TextInputType.number,
                ),
                SizedBox(height: 20),
                InputWidget(
                  icontroller: descController,
                  iHint: "Enter Description",
                ),
                Consumer<AppProvider>(
                  builder: (context, appProvider, _) {
                    return ListTile(
                      onTap: () {
                        appProvider.setVisibility(!appProvider.isVisibility);
                      },
                      tileColor: Colors.transparent,
                      leading: Icon(Iconsax.global),
                      title: Text("Visibility"),
                      subtitle: Text(
                        appProvider.isVisibility ? "Public" : "Private",
                        style: TextStyle(
                          color: appProvider.isVisibility
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      trailing: Icon(Iconsax.arrow_circle_right, size: 30),
                    );
                  },
                ),
                Consumer<AppProvider>(
                  builder: (context, appProvider, _) {
                    return ListTile(
                      onTap: () {
                        appProvider.setComments(!appProvider.isComments);
                      },
                      tileColor: Colors.transparent,
                      leading: Icon(Iconsax.message_text_1),
                      title: Text("Comments"),
                      subtitle: Text(
                        appProvider.isComments ? "ON" : "OFF",
                        style: TextStyle(
                          color: appProvider.isComments
                              ? Colors.green
                              : Colors.red,
                        ),
                      ),
                      trailing: Icon(Iconsax.arrow_circle_right, size: 30),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
