import 'dart:async';
import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/services.dart';
import 'package:globee/BottomSheets/CommentsBottomSheet.dart';
import 'package:globee/BottomSheets/ItemMoreBottomSheet.dart';
import 'package:globee/BottomSheets/MediaPickerBottomSheet.dart';
import 'package:globee/BottomSheets/CartBottomSheet.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Core/VideoManager.dart';
import 'package:globee/Routes/App_Router.dart';
import 'package:globee/Routes/App_Router.dart' as MyApp;
import 'package:globee/Screens/SearchScreen.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreen extends StatefulWidget {
  final String? productId;
  const HomeScreen({super.key, this.productId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _pageController = PageController();
  final Map<int, Map<int, BetterPlayerController>> videoControllers = {};
  bool showCenterIcon = false;
  IconData centerIcon = Iconsax.play;
  bool showCenterIconLikes = false;
  double likeIconScale = 0.0;
  double likeIconOpacity = 0.0;
  Timer? _activityTimer;
  bool isLoading = false;
  IconData centerIconLikes = Iconsax.like_1;
  Duration? videoDuration;
  Duration? videoPosition;
  int activeItemIndex = 0;
  int activeMediaIndex = 0;
  VoidCallback? videoListener;
  final Map<String, Duration> watchedDurations = {};
  final Map<String, Timer> watchTimers = {};
  String qtt = "";
  String uid = '';
  bool isFollowed = false;
  String lang = "eng";
  List languages = [];
  String followEnb = "0";
  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    setState(() {
      lang = prefx.getString("Lang")!;
      getLangDB();
    });
  }

  Future getCurrentFollowed(buyerID) async {
    String? fcmToken = await FirebaseMessaging.instance.getToken();
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var result = await AppUtils.makeRequests(
      "fetch",
      "SELECT * FROM Followers WHERE buyer_id = '$buyerID' AND user_id = '${prefx.getString("UID")}' ",
    );
    print(
      "SELECT * FROM Followers WHERE buyer_id = '$buyerID' AND user_id = '${prefx.getString("UID")}' ",
    );
    if (result[0] != null) {
      followEnb = result[0]['id'];
    } else {
      followEnb = "0";
    }
    setState(() {});
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

  Future getCartQtt(itemId) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var cartQTT = await AppUtils.makeRequests(
      "fetch",
      "SELECT qtt FROM Cart WHERE ${prefx.getString('UID') != null ? 'user_id = "${prefx.getString("UID")}" AND' : ''}  item_id = '$itemId' ${prefx.getString('OID') != null ? 'AND order_id = "${prefx.getString("OID")}" ' : ''} ",
    );

    setState(() {
      if (cartQTT != null &&
          cartQTT.isNotEmpty &&
          cartQTT[0] != null &&
          cartQTT[0]['qtt'] != null) {
        qtt = cartQTT[0]['qtt'].toString();
      } else {
        qtt = "0";
      }
      if (prefx.getString("UID") != null) {
        uid = prefx.getString("UID")!;
      }
    });
  }

  int cartCount = 0;
  int commentsCount = 0;

  Future getCartCount(merchid) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    if (merchid != null && prefx.getString("OID") != null) {
      var result = await AppUtils.makeRequests(
        "fetch",
        "SELECT qtt FROM Cart WHERE item_id = '$merchid' AND order_id = '${prefx.getString("OID")}'",
      );

      setState(() {
        if (result[0] != null) {
          cartCount = int.parse(result[0]['qtt'].toString());
        } else {
          cartCount = 0;
        }
      });
    }
  }

  Future getCommentsCount(itmid) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    if (itmid != null && prefx.getString("UID") != null) {
      var result = await AppUtils.makeRequests(
        "fetch",
        "SELECT COUNT(id) as commcount FROM Comments WHERE item_id = '$itmid'",
      );

      setState(() {
        if (result[0] != null) {
          commentsCount = int.parse(result[0]['commcount'].toString());
        } else {
          commentsCount = 0;
        }
      });
    }
  }

  void playVideo(int itemIndex, int mediaIndex) {
    // أوقف كل الفيديوهات التانية
    videoControllers.forEach((outerIndex, innerMap) {
      innerMap.forEach((innerIndex, controller) {
        if (!(outerIndex == itemIndex && innerIndex == mediaIndex)) {
          controller.pause();
        }
      });
    });

    // شغّل الفيديو الحالي
    final newController = videoControllers[itemIndex]?[mediaIndex];
    if (newController != null) {
      newController.play();
    }

    activeItemIndex = itemIndex;
    activeMediaIndex = mediaIndex;
  }

  void togglePlayPause(BetterPlayerController? controller) {
    if (controller == null) return;

    final isPlaying =
        controller.videoPlayerController?.value.isPlaying ?? false;

    setState(() {
      showCenterIcon = true;
      centerIcon = isPlaying ? Iconsax.pause : Iconsax.play;
    });

    if (isPlaying) {
      controller.pause();
    } else {
      controller.play();
    }

    // إخفاء الأيقونة بعد 800ms
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          showCenterIcon = false;
        });
      }
    });
  }

  final player = AudioPlayer();
  void toggleLikeUnlikes() async {
    setState(() {
      showCenterIconLikes = true;
      centerIconLikes = Iconsax.like_1;
      likeIconScale = 1.2;
      likeIconOpacity = 1.0;
    });
    await player.play(AssetSource('sounds/like.mp3'));

    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          showCenterIconLikes = false;
          likeIconScale = 0.0;
          likeIconOpacity = 0.0;
        });
      }
    });
  }

  int _currentIndex = 0;
  int currentJndex = 0;
  List currentUsers = [];

  final List<String> videoUrls = [];

  List items = [];
  String countLikes = "";
  String countShares = "";
  String userLIkes = "";
  String userShares = "";

  bool isVideo(String url) {
    return url.toLowerCase().endsWith(".mp4") ||
        url.toLowerCase().endsWith(".mov") ||
        url.toLowerCase().endsWith(".avi") ||
        url.toLowerCase().endsWith(".webm");
  }

  void openSearch() async {
    final selectedItemId = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchScreen()),
    );

    if (selectedItemId != null) {
      setState(() {
        activeItemIndex = items.indexWhere(
          (item) => item['id'] == selectedItemId,
        );
        activeMediaIndex = 0;
        _pageController.jumpToPage(activeItemIndex);
      });
    }
  }

  Future getCountLikes(itmid) async {
    var itemCount = await AppUtils.makeRequests(
      "fetch",
      "SELECT COUNT(id) as likes FROM Likes WHERE item_id = '$itmid'",
    );
    setState(() {
      countLikes = itemCount[0]['likes'];
    });
  }

  Future getCountShares(itmid) async {
    var itemCount = await AppUtils.makeRequests(
      "fetch",
      "SELECT COUNT(id) as shares FROM Shares WHERE item_id = '$itmid'",
    );
    setState(() {
      countShares = itemCount[0]['shares'];
    });
  }

  Future getCurrentMerchant(userId) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    await AppUtils.makeRequests(
      "query",
      "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE id = '${prefx.getString("UID")}' ",
    );
    var currentUser = await AppUtils.makeRequests(
      "fetch",
      "SELECT id, Fullname, urlAvatar, uid, status FROM Users WHERE uid = '$userId'",
    );

    setState(() {
      currentUsers = currentUser;
    });
  }

  Future getUserLike(itmid) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var itemCount = await AppUtils.makeRequests(
      "fetch",
      "SELECT COUNT(id) as likes FROM Likes WHERE user_id = '${prefx.getString("UID")}' AND item_id = '$itmid'",
    );
    setState(() {
      userLIkes = itemCount[0]['likes'];
    });
  }

  Future getUserShare(itmid) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    var itemCount = await AppUtils.makeRequests(
      "fetch",
      "SELECT COUNT(id) as shares FROM Shares WHERE user_id = '${prefx.getString("UID")}' AND item_id = '$itmid'",
    );
    setState(() {
      userShares = itemCount[0]['shares'];
    });
  }

  Future<List<String>> getBlockedUsers(String myUid) async {
    var response = await AppUtils.makeRequests(
      "fetch",
      "SELECT blocked_user_id FROM blocks WHERE user_id = '$myUid'",
    );

    print('Response from makeRequests: $response');

    // لو response Map وبيحتوي على data:
    if (response is Map && response.containsKey('data')) {
      var data = response['data'];
      if (data is List) {
        List<String> blockedList = [];
        for (var item in data) {
          if (item is Map && item.containsKey('blocked_user_id')) {
            blockedList.add(item['blocked_user_id'].toString());
          }
        }
        return blockedList;
      }
    }

    // لو response نفسه List:
    if (response is List) {
      List<String> blockedList = [];
      for (var item in response) {
        if (item is Map && item.containsKey('blocked_user_id')) {
          blockedList.add(item['blocked_user_id'].toString());
        }
      }
      return blockedList;
    }

    // لو response Map لكن بدون data أو شكل غير متوقع:
    return [];
  }

  Future getItems() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? myUid = prefs.getString("UID");

    String blockedCondition = "";

    if (widget.productId == null && myUid != null) {
      List<String> blockedUsers = await getBlockedUsers(myUid);

      if (blockedUsers.isNotEmpty) {
        String blockedIds = blockedUsers.map((id) => "'$id'").join(", ");
        blockedCondition = "AND uid NOT IN ($blockedIds)";
      }
    }

    var itemsx = await AppUtils.makeRequests(
      "fetch",
      "SELECT * FROM Items WHERE visibility = 'Public' AND status = '1' AND name != '' AND description != 'null' $blockedCondition ${widget.productId != null ? "AND id = '${widget.productId}'" : ""}",
    );

    _activityTimer = Timer.periodic(Duration(seconds: 30), (_) async {
      final uid = await SharedPreferences.getInstance().then(
        (prefs) => prefs.getString("UID"),
      );

      await AppUtils.makeRequests(
        "query",
        "UPDATE Users SET last_activity = '${DateTime.now().toUtc().toIso8601String()}' WHERE uid = '$uid'",
      );
    });

    if (itemsx != null && itemsx.isNotEmpty && itemsx is List) {
      itemsx.shuffle();
      if (mounted) {
        setState(() {
          items.addAll(itemsx);
        });
      }

      final firstItem = itemsx.first;

      final mediaList = firstItem['media']
          .toString()
          .split(',')
          .map((e) => e.trim())
          .toList();

      // نتحقق إذا أول media فعليًا هو فيديو
      final firstMedia = mediaList[0];
      if (firstMedia.endsWith('.mp4')) {
        // ✅ أول media هو فيديو، نهيّئ ونشغّل
        initializeVideoController(
          "https://pos7d.site/Globee/sys/uploads/Items/${firstItem['id']}/$firstMedia",
          0,
          0,
        );
        playVideo(0, 0);
      } else {
        // ❌ أول media مش فيديو، ما تعملش حاجة
        print("⛔ أول ميديا مش فيديو، مش هيشتغل تلقائي.");
      }
      Provider.of<AppProvider>(context, listen: false).setPutItems(items);
      Provider.of<AppProvider>(context, listen: false).setCurrentId("0");
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).setItemId(int.parse(firstItem['id']));
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).setCurrentUsers(firstItem['uid']);

      getCurrentMerchant(firstItem['uid']);
      getCartQtt(firstItem['id']);
      getCountLikes(firstItem['id']);
      getUserLike(firstItem['id']);
      getCountShares(firstItem['id']);
      getUserShare(firstItem['id']);
      getCartQtt(firstItem['id']);
      getCartCount(firstItem['id']);
      getCommentsCount(firstItem['id']);
      getCurrentFollowed(firstItem['uid']);
    }
  }

  static const platform = MethodChannel("mazo.channel");
  @override
  void initState() {
    super.initState();
    getLang();
    getItems();

    platform.setMethodCallHandler((call) async {
      if (call.method == "openProduct") {
        final productId = call.arguments.toString();
        final path = '/Globee/product?id=$productId';

        print("🚀 فتح المنتج ID: $productId → المسار: $path");

        GoRouter.of(navigatorKey.currentContext!).go(path);
      }
    });
  }

  void initializeVideoController(
    String path,
    int itemIndex,
    int mediaIndex,
  ) async {
    videoControllers[itemIndex] ??= {};

    if (videoControllers[itemIndex]!.containsKey(mediaIndex)) {
      videoControllers[itemIndex]![mediaIndex]?.dispose();
      videoControllers[itemIndex]!.remove(mediaIndex);
    }

    final dataSource = BetterPlayerDataSource(
      BetterPlayerDataSourceType.network,
      path,
    );

    final controller = BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: true,
        looping: true,
        eventListener: (event) {
          print("EventWool: ${event.betterPlayerEventType.name}");
          if (event.betterPlayerEventType == BetterPlayerEventType.finished) {
            final controller = videoControllers[itemIndex]?[mediaIndex];
            controller?.seekTo(Duration.zero);
            controller?.play();
          }
        },
        aspectRatio: 9 / 16,
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableMute: false,
          showControls: false,
        ),
      ),
      betterPlayerDataSource: dataSource,
    );

    VideoManager().setController(controller);

    videoListener = () {
      final controllerState = controller.videoPlayerController?.value;

      if (!mounted ||
          controllerState == null ||
          controllerState.duration == null ||
          controllerState.position == 0)
        return;

      setState(() {
        videoDuration = controllerState.duration;
        videoPosition = controllerState.position;
      });
    };

    controller.videoPlayerController?.addListener(videoListener!);

    videoControllers[itemIndex]![mediaIndex] = controller;
  }

  void disposeVideoController(int itemIndex, int mediaIndex) async {
    if (videoControllers.containsKey(itemIndex) &&
        videoControllers[itemIndex]!.containsKey(mediaIndex)) {
      final controller = videoControllers[itemIndex]![mediaIndex];

      try {
        controller?.videoPlayerController?.removeListener(
          () {},
        ); // نظف أي listener
        await controller?.pause();
      } catch (_) {}

      await Future.delayed(Duration(milliseconds: 200));
      controller?.dispose();
      videoControllers[itemIndex]!.remove(mediaIndex);
    }
  }

  @override
  void dispose() {
    // videoControllers.forEach((key, controller) => controller.dispose());
    videoControllers.clear();
    _pageController.dispose();
    for (final timer in watchTimers.values) {
      timer.cancel();
    }
    for (final controllerMap in videoControllers.values) {
      for (final controller in controllerMap.values) {
        controller.dispose();
      }
    }
    _activityTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentController =
        videoControllers[activeItemIndex]?[activeMediaIndex];
    final videoDuration =
        currentController?.videoPlayerController?.value.duration;
    final videoPosition =
        currentController?.videoPlayerController?.value.position;
    print(currentUsers);
    return Directionality(
      textDirection: lang == "arb" ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: Colors.black,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          forceMaterialTransparency: true,
          clipBehavior: Clip.none,
          backgroundColor: Colors.transparent,
          title: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  offset: Offset(0, 0),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(
                Iconsax.add_circle,
                color: Colors.white,
                size: 25,
              ),
              onPressed: () async {
                VideoManager().pauseCurrent();
                SharedPreferences prefx = await SharedPreferences.getInstance();
                if (prefx.getString("UID") != null) {
                  print(currentUsers);

                  if (currentUsers.isNotEmpty) {
                    if (currentUsers[0]['status'] == '1') {
                      MediaPickerBottomSheet.showPrimaryOptions(
                        MyApp.navigatorKey.currentContext!,
                        true,
                      );
                    } else if (currentUsers[0]['status'] == '2') {
                      AppUtils.snackBarShowing(context, languages[150][lang]);
                    } else {
                      AppUtils.snackBarShowing(context, languages[149][lang]);
                    }
                  } else {
                    var usrStx = await AppUtils.makeRequests(
                      "fetch",
                      "SELECT status FROM Users WHERE uid = '${prefx.getString("UID")}'",
                    );
                    print(usrStx);
                    if (usrStx[0]['status'] == '1') {
                      MediaPickerBottomSheet.showPrimaryOptions(
                        MyApp.navigatorKey.currentContext!,
                        true,
                      );
                    } else if (usrStx[0]['status'] == '2') {
                      AppUtils.snackBarShowing(context, languages[150][lang]);
                    } else {
                      AppUtils.snackBarShowing(context, languages[149][lang]);
                    }
                  }
                } else {
                  context.go('/login');
                }
              },
            ),
          ),
          actions: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Iconsax.search_normal,
                  color: Colors.white,
                  size: 25,
                ),
                onPressed: () {
                  VideoManager().pauseCurrent();
                  openSearch();
                },
              ),
            ),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 0),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Iconsax.more_circle,
                  color: Colors.white,
                  size: 25,
                ),
                onPressed: () {
                  VideoManager().pauseCurrent();
                  showModalBottomSheet(
                    context: context,
                    backgroundColor: Colors.transparent,
                    builder: (BuildContext ctx) {
                      return Directionality(
                        textDirection: TextDirection.rtl,
                        child: const moreBottomSheet(),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
        body: PageView.builder(
          controller: _pageController,
          scrollDirection: Axis.vertical,
          itemCount: items.length,
          onPageChanged: (index) async {
            SharedPreferences prefx = await SharedPreferences.getInstance();

            // وقف الفيديو اللي فات
            disposeVideoController(_currentIndex, currentJndex);
            if (activeItemIndex != 0 || activeMediaIndex != 0) {
              videoControllers[activeItemIndex]?[activeMediaIndex]?.pause();
            }

            // حدث المؤشرات
            setState(() {
              activeItemIndex = index;
              activeMediaIndex = 0;
              _currentIndex = index;
              currentJndex = 0;
            });

            // لو وصلنا لنهاية القائمة، هات بيانات تانية
            if (index >= items.length - 1) {
              await getItems();
            }

            final item = items[index];
            final mediaList = item['media']
                .toString()
                .split(',')
                .map((e) => e.trim())
                .toList();
            final firstMedia = mediaList[0];

            // شغل الفيديو الأول لو كان فيديو
            if (firstMedia.endsWith('.mp4')) {
              initializeVideoController(
                "https://pos7d.site/Globee/sys/uploads/Items/${item['id']}/$firstMedia",
                index,
                0,
              );
              playVideo(index, 0);
            }

            // باقي الطلبات
            Provider.of<AppProvider>(context, listen: false).setPutItems(items);
            Provider.of<AppProvider>(
              context,
              listen: false,
            ).setItemId(int.parse(item['id']));
            Provider.of<AppProvider>(
              context,
              listen: false,
            ).setCurrentId(index.toString());
            Provider.of<AppProvider>(
              context,
              listen: false,
            ).setCommentSwitch(item['comments']);
            if (item['uid'] != null) {
              Provider.of<AppProvider>(
                context,
                listen: false,
              ).setCurrentUsers(item['uid']);
            }

            await AppUtils.makeRequestsViews(
              "query",
              "UPDATE Items SET Views = Views + 1 WHERE id = '${item['id']}'",
            );
            print(item['id']);
            getCartQtt(item['id']);
            getCountLikes(item['id']);
            getUserLike(item['id']);
            setState(() {
              getCountShares(item['id']);
              getUserShare(item['id']);
              getCartQtt(item['id']);
              getCartCount(item['id']);
              getCommentsCount(item['id']);
              getCurrentFollowed(item['uid']);
            });
            getCurrentMerchant(item['uid']);
            setState(() {
              isFollowed = false;
            });
          },
          itemBuilder: (context, index) {
            return RefreshIndicator(
              onRefresh: () => getItems(),
              child: Stack(
                children: [
                  PageView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: items[index]['media']
                        .toString()
                        .split(',')
                        .length,
                    onPageChanged: (mediaIndex) async {
                      disposeVideoController(index, currentJndex);
                      videoControllers[activeItemIndex]?[activeMediaIndex]
                          ?.pause();

                      final mediaList = items[index]['media']
                          .toString()
                          .split(',')
                          .map((e) => e.trim())
                          .toList();
                      final currentMedia = mediaList[mediaIndex];

                      setState(() {
                        activeMediaIndex = mediaIndex;
                        currentJndex = mediaIndex;
                      });

                      if (currentMedia.endsWith('.mp4')) {
                        initializeVideoController(
                          "https://pos7d.site/Globee/sys/uploads/Items/${items[index]['id']}/$currentMedia",
                          index,
                          mediaIndex,
                        );
                        playVideo(index, mediaIndex);
                      }
                    },
                    itemBuilder: (context, mediaIndex) {
                      final mediaList = items[index]['media']
                          .toString()
                          .split(',')
                          .map((e) => e.trim())
                          .toList();
                      final mediaUrl = mediaList[mediaIndex];
                      final isVideo = mediaUrl.endsWith('.mp4');
                      final isActive =
                          index == activeItemIndex &&
                          mediaIndex == activeMediaIndex;

                      if (isVideo && isActive) {
                        final controller = videoControllers[index]?[mediaIndex];

                        if (controller == null ||
                            !controller.isVideoInitialized()!) {
                          return Center(
                            child: SpinKitChasingDots(
                              color: AppTheme.backgroundColor,
                            ),
                          );
                        }

                        return GestureDetector(
                          onTap: () {
                            if (controller.isPlaying()!) {
                              controller.pause();
                              setState(() {
                                showCenterIcon = true;
                                centerIcon = Iconsax.pause_circle;
                              });
                            } else {
                              controller.play();
                              setState(() {
                                showCenterIcon = true;
                                centerIcon = Iconsax.play_circle;
                              });
                            }

                            // اختفي بعد ثواني
                            Future.delayed(Duration(seconds: 1), () {
                              setState(() {
                                showCenterIcon = false;
                              });
                            });
                          },
                          child: AbsorbPointer(
                            absorbing: true,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                BetterPlayer(controller: controller),
                                if (showCenterIcon)
                                  AnimatedOpacity(
                                    duration: Duration(milliseconds: 300),
                                    opacity: showCenterIcon ? 1.0 : 0.0,
                                    child: AnimatedScale(
                                      duration: Duration(milliseconds: 300),
                                      scale: showCenterIcon ? 1.5 : 0.0,
                                      curve: Curves.easeOutBack,
                                      child: Icon(
                                        centerIcon,
                                        size: 60,
                                        color: Colors.white.withOpacity(0.9),
                                        shadows: [
                                          Shadow(
                                            blurRadius: 12,
                                            color: Colors.black87,
                                            offset: Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        );
                      } else if (isVideo) {
                        return Container(
                          color: Colors.black,
                          child: Center(
                            child: Icon(
                              Icons.play_circle_fill,
                              size: 64,
                              color: Colors.white,
                            ),
                          ),
                        );
                      } else {
                        return Image.network(
                          "https://pos7d.site/Globee/sys/uploads/Items/${items[index]['id']}/$mediaUrl",
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                      }
                    },
                  ),
                  Positioned.fill(
                    child: Center(
                      child: AnimatedOpacity(
                        duration: Duration(milliseconds: 300),
                        opacity: likeIconOpacity,
                        child: AnimatedScale(
                          duration: Duration(milliseconds: 400),
                          scale: likeIconScale,
                          curve: Curves.easeOutBack,
                          child: Icon(
                            centerIconLikes,
                            size: 120,
                            color: Colors.redAccent.withOpacity(0.9),
                            shadows: [
                              Shadow(
                                color: Colors.black.withOpacity(0.4),
                                blurRadius: 12,
                                offset: Offset(0, 4),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  Positioned(
                    left: 0,
                    bottom: videoDuration != null && videoPosition != null
                        ? 30
                        : 0,
                    right: 0, // عشان العرض ما يبقاش محدود
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.5),
                            Colors.black.withOpacity(0.9),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          currentUsers.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    VideoManager().pauseCurrent();
                                    AppUtils.sNavigateToReplace(
                                      context,
                                      '/UserProfile',
                                      {'userId': currentUsers[0]['uid']},
                                    );
                                  },
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundImage: NetworkImage(
                                          "https://pos7d.site/Globee/sys/${currentUsers[0]['urlAvatar']}",
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            currentUsers[0]['Fullname'],
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Visibility(
                                            visible:
                                                uid == currentUsers[0]['uid']
                                                ? false
                                                : true,
                                            child: GestureDetector(
                                              onTap: () async {
                                                VideoManager().pauseCurrent();
                                                SharedPreferences prefx =
                                                    await SharedPreferences.getInstance();
                                                if (uid != "") {
                                                  String? fcmToken =
                                                      await FirebaseMessaging
                                                          .instance
                                                          .getToken();
                                                  print(
                                                    "🔥 FCM Token: $fcmToken",
                                                  );
                                                  var result =
                                                      await AppUtils.makeRequests(
                                                        "fetch",
                                                        "SELECT * FROM Followers WHERE buyer_id = '${currentUsers[0]['uid']}'",
                                                      );

                                                  if (result[0] == null) {
                                                    setState(() {
                                                      followEnb = "1";
                                                    });
                                                    AppUtils.makeRequests(
                                                      "query",
                                                      "INSERT INTO Followers VALUES(NULL, '${currentUsers[0]['uid']}', '${prefx.getString("UID")}','$fcmToken')",
                                                    );
                                                  } else {
                                                    setState(() {
                                                      followEnb = "0";
                                                    });
                                                    AppUtils.makeRequests(
                                                      "query",
                                                      "DELETE FROM Followers WHERE buyer_id = '${currentUsers[0]['uid']}' AND user_token = '$fcmToken' ",
                                                    );
                                                  }
                                                } else {
                                                  context.go('/login');
                                                }
                                              },
                                              child: Container(
                                                padding: EdgeInsets.symmetric(
                                                  horizontal: 10,
                                                  vertical: 5,
                                                ),
                                                decoration: BoxDecoration(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                  color: followEnb == "0"
                                                      ? Colors.red
                                                      : Colors.white,
                                                ),
                                                child: Text(
                                                  followEnb == "0"
                                                      ? languages[51][lang]
                                                      : lang == 'arb'
                                                      ? "تتابع"
                                                      : "Followed",
                                                  style: TextStyle(
                                                    color: followEnb == "0"
                                                        ? Colors.white
                                                        : Colors.red,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                )
                              : Container(),
                          SizedBox(height: 8),
                          Text(
                            items[index]['name'].toString(),
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            "${items[index]['price'].toString()} ${languages[53][lang]}",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            items[index]['description'].toString(),
                            style: TextStyle(color: Colors.white70),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // أزرار التفاعل
                  Positioned(
                    right: lang == 'eng' ? 16 : null,
                    left: lang == 'arb' ? 16 : null,
                    bottom: 130,
                    child: Column(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(
                              userLIkes != "0"
                                  ? Iconsax.like_15
                                  : Iconsax.like_1,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () async {
                              toggleLikeUnlikes();
                              final prefs =
                                  await SharedPreferences.getInstance();
                              final uid = prefs.getString("UID");
                              final itemId = items[index]['id'];

                              if (uid == null) {
                                context.go('/login');
                                return;
                              }

                              /// تفاعل بصري سريع فوري
                              setState(() {
                                userLIkes = userLIkes == "0" ? "1" : "0";
                                showCenterIconLikes = true;
                                centerIconLikes = Iconsax.like_1;
                              });

                              // أخفي الأيقونة بعد شوية
                              Future.delayed(Duration(milliseconds: 800), () {
                                if (mounted) {
                                  setState(() {
                                    showCenterIconLikes = false;
                                  });
                                }
                              });

                              try {
                                /// شوف الحالة القديمة من السيرفر (ممكن تدي null)
                                var likes = await AppUtils.makeRequests(
                                  "fetch",
                                  "SELECT * FROM Likes WHERE user_id = '$uid' AND item_id = '$itemId'",
                                );

                                if (likes is Map &&
                                    likes.containsKey('message')) {
                                  likes = [];
                                }

                                if (likes.isNotEmpty) {
                                  await AppUtils.makeRequests(
                                    "query",
                                    "DELETE FROM Likes WHERE user_id = '$uid' AND item_id = '$itemId'",
                                  );
                                } else {
                                  SharedPreferences prefx =
                                      await SharedPreferences.getInstance();
                                  await AppUtils.makeRequests(
                                    "query",
                                    "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                                  );
                                  await AppUtils.makeRequests(
                                    "query",
                                    "INSERT INTO Likes VALUES(NULL, '$uid', '$itemId', '${DateTime.now()}')",
                                  );
                                }

                                /// حدث العداد فقط بعد تنفيذ العملية
                                getCountLikes(itemId);
                              } catch (e) {
                                debugPrint("Error during like/unlike: $e");
                              }
                            },
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          countLikes,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 10,
                                color: Colors.black, // ظل خفيف وناعم
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: 10),
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Iconsax.message_text_1,
                              color: Colors.white,
                              size: 32,
                            ),
                            onPressed: () async {
                              showCommentsBottomSheet(context);
                            },
                          ),
                        ),

                        SizedBox(height: 10),
                        Text(
                          commentsCount.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 10,
                                color: Colors.black, // ظل خفيف وناعم
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Builder(
                          builder: (context) {
                            return Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 6,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: IconButton(
                                icon: Icon(
                                  userShares != '0'
                                      ? Iconsax.share5
                                      : Iconsax.share,
                                  color: Colors.white,
                                  size: 32,
                                ),
                                onPressed: () async {
                                  final box =
                                      context.findRenderObject() as RenderBox?;

                                  if (box != null) {
                                    await SharePlus.instance
                                        .share(
                                          ShareParams(
                                            text:
                                                'شوف المنتج ده على Globee 👇\nhttps://pos7d.site/Globee/product?id=${items[index]['id']}',
                                            sharePositionOrigin:
                                                box.localToGlobal(Offset.zero) &
                                                box.size,
                                          ),
                                        )
                                        .then((_) async {
                                          // بعد الـ Share، كمل منطق المشاركة
                                          SharedPreferences prefx =
                                              await SharedPreferences.getInstance();
                                          if (prefx.getString("UID") != null) {
                                            var likes = await AppUtils.makeRequests(
                                              "fetch",
                                              "SELECT * FROM Shares WHERE user_id = '${prefx.getString("UID")}' AND item_id = '${items[index]['id']}' ",
                                            );
                                            if (likes[0] != null) {
                                              await AppUtils.makeRequests(
                                                "query",
                                                "DELETE FROM Shares WHERE user_id = '${prefx.getString("UID")}' AND item_id = '${items[index]['id']}'",
                                              );
                                            } else {
                                              SharedPreferences prefx =
                                                  await SharedPreferences.getInstance();
                                              await AppUtils.makeRequests(
                                                "query",
                                                "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                                              );
                                              await AppUtils.makeRequests(
                                                "query",
                                                "INSERT INTO Shares VALUES(NULL, '${prefx.getString("UID")}', '${items[index]['id']}', '${DateTime.now()}')",
                                              );
                                            }
                                            getCountShares(items[index]['id']);
                                            getUserShare(items[index]['id']);
                                          } else {
                                            context.go('/login');
                                          }
                                        });
                                  } else {
                                    // fallback بسيط لو box = null
                                    await SharePlus.instance
                                        .share(
                                          ShareParams(
                                            text:
                                                'شوف المنتج ده على Globee 👇\nhttps://pos7d.site/Globee/product?id=${items[index]['id']}',
                                          ),
                                        )
                                        .then((_) async {
                                          // بعد الـ Share، كمل منطق المشاركة
                                          SharedPreferences prefx =
                                              await SharedPreferences.getInstance();
                                          if (prefx.getString("UID") != null) {
                                            var likes = await AppUtils.makeRequests(
                                              "fetch",
                                              "SELECT * FROM Shares WHERE user_id = '${prefx.getString("UID")}' AND item_id = '${items[index]['id']}' ",
                                            );
                                            if (likes[0] != null) {
                                              await AppUtils.makeRequests(
                                                "query",
                                                "DELETE FROM Shares WHERE user_id = '${prefx.getString("UID")}' AND item_id = '${items[index]['id']}'",
                                              );
                                            } else {
                                              SharedPreferences prefx =
                                                  await SharedPreferences.getInstance();
                                              await AppUtils.makeRequests(
                                                "query",
                                                "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
                                              );
                                              await AppUtils.makeRequests(
                                                "query",
                                                "INSERT INTO Shares VALUES(NULL, '${prefx.getString("UID")}', '${items[index]['id']}', '${DateTime.now()}')",
                                              );
                                            }
                                            getCountShares(items[index]['id']);
                                            getUserShare(items[index]['id']);
                                          } else {
                                            context.go('/login');
                                          }
                                        });
                                  }
                                },
                              ),
                            );
                          },
                        ),

                        SizedBox(height: 10),
                        Text(
                          countShares.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(
                                offset: Offset(0, 1),
                                blurRadius: 10,
                                color: Colors.black, // ظل خفيف وناعم
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 10),
                        Visibility(
                          visible: uid != items[index]['uid'] ? true : false,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 6,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: IconButton(
                              icon: Icon(
                                cartCount != 0
                                    ? Iconsax.shopping_cart5
                                    : Iconsax.shopping_cart,
                                color: Colors.white,
                                size: 32,
                              ),
                              onPressed: () async {
                                // أظهر دايرة تحميل
                                showModalBottomSheet(
                                  context: context,
                                  isDismissible: false,
                                  enableDrag: false,
                                  builder: (context) {
                                    return Container(
                                      height: 200,
                                      alignment: Alignment.center,
                                      child: SpinKitDoubleBounce(
                                        color: AppTheme.primaryColor,
                                        size: 30.0,
                                      ),
                                    );
                                  },
                                );

                                SharedPreferences prefx =
                                    await SharedPreferences.getInstance();

                                if (prefx.getString("OID") != null) {
                                  var notCartAdded = await AppUtils.makeRequests(
                                    "fetch",
                                    "SELECT * FROM Cart WHERE user_id = '${items[index]['uid']}' AND item_id = '${items[index]['id']}' AND order_id = '${prefx.getString("OID")}' ",
                                  );

                                  // لو المنتج مش في السلة، ضيفه
                                  if (notCartAdded[0] == null) {
                                    await AppUtils.makeRequests(
                                      "query",
                                      "INSERT INTO Cart VALUES (NULL, '${items[index]['uid']}', '${items[index]['id']}', '0','${prefx.getString("OID")}')",
                                    );

                                    // بعد الإضافة، نعمل Fetch تاني عشان نجيب الـ ID الجديد
                                    notCartAdded = await AppUtils.makeRequests(
                                      "fetch",
                                      "SELECT * FROM Cart WHERE user_id = '${items[index]['uid']}' AND item_id = '${items[index]['id']}' AND order_id = '${prefx.getString("OID")}' ",
                                    );
                                  }

                                  // بعد التأكد إن فيه عنصر فعلاً
                                  try {
                                    if (notCartAdded[0] != null) {
                                      // أغلق دايرة التحميل قبل عرض الـ BottomSheet
                                      Navigator.of(context).pop();
                                      Future.delayed(
                                        Duration(milliseconds: 100),
                                        () {
                                          CartBottomSheet.showCart(
                                            context,
                                            notCartAdded[0]['id'],
                                            int.parse(items[index]['qtt']),
                                            int.parse(cartCount.toString()),
                                            (newQtt) {
                                              if (newQtt == 0) {
                                                AppUtils.makeRequests(
                                                  "query",
                                                  "DELETE FROM Cart WHERE id = '${notCartAdded[0]['id']}'",
                                                );
                                              }
                                              getCartQtt(items[index]['id']);
                                              getCartCount(items[index]['id']);
                                            },
                                          );
                                        },
                                      );
                                    } else {
                                      Navigator.of(context).pop();
                                      print('لم يتم العثور على عنصر في السلة');
                                    }
                                  } catch (e) {
                                    Navigator.of(context).pop();
                                    print(
                                      'Error in CartBottomSheet.showCart: $e',
                                    );
                                  }
                                } else {
                                  Navigator.of(context).pop();
                                  context.go('/login');
                                }
                              },
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Visibility(
                          visible: uid != items[index]['uid'] ? true : false,
                          child: Text(
                            cartCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: Offset(0, 1),
                                  blurRadius: 10,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                      ],
                    ),
                  ),

                  if (videoDuration != null && videoPosition != null)
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Slider(
                        value: videoPosition.inMilliseconds
                            .clamp(0, videoDuration.inMilliseconds)
                            .toDouble(),
                        min: 0,
                        max: videoDuration.inMilliseconds.toDouble(),
                        thumbColor: Colors.white,
                        activeColor: Colors.white,
                        inactiveColor: Colors.white38,
                        onChanged: (value) {
                          final newPosition = Duration(
                            milliseconds: value.toInt(),
                          );
                          currentController?.videoPlayerController?.seekTo(
                            newPosition,
                          );
                          setState(() {});
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
