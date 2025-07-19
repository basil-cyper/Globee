import 'dart:async';

import 'package:globee/BottomSheets/CommentsBottomSheet.dart';
import 'package:globee/BottomSheets/ItemMoreBottomSheet.dart';
import 'package:globee/BottomSheets/MediaPickerBottomSheet.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/Screens/SearchScreen.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeScreenProfile extends StatefulWidget {
  final String userProfileId;
  final String itemId;
  const HomeScreenProfile({
    super.key,
    required this.userProfileId,
    required this.itemId,
  });

  @override
  State<HomeScreenProfile> createState() => _HomeScreenProfileState();
}

class _HomeScreenProfileState extends State<HomeScreenProfile> {
  final PageController _pageController = PageController();
  final Map<int, Map<int, BetterPlayerController>> videoControllers = {};
  bool showCenterIcon = false;
  IconData centerIcon = Iconsax.play;
  bool showCenterIconLikes = false;
  IconData centerIconLikes = Iconsax.like_1;
  Duration? videoDuration;
  Duration? videoPosition;
  int activeItemIndex = 0;
  int activeMediaIndex = 0;
  VoidCallback? videoListener;
  final Map<String, Duration> watchedDurations = {};
  final Map<String, Timer> watchTimers = {};

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

  void toggleLikeUnlikes() {
    setState(() {
      showCenterIconLikes = true;
      centerIconLikes = Iconsax.like_1;
    });

    // إخفاء الأيقونة بعد 800ms
    Future.delayed(Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          showCenterIconLikes = false;
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
  String userLIkes = "";

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

  Future getCurrentMerchant(userId) async {
    var currentUser = await AppUtils.makeRequests(
      "fetch",
      "SELECT id, Fullname, urlAvatar, uid FROM Users WHERE uid = '$userId'",
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

  Future getItems() async {
    var itemsx = await AppUtils.makeRequests(
      "fetch",
      "SELECT * FROM Items WHERE visibility = 'Public' AND status = '1' AND id = '${widget.itemId}'",
    );

    // getCurrentMerchant();

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
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).setItemId(int.parse(firstItem['id']));
      Provider.of<AppProvider>(
        context,
        listen: false,
      ).setCurrentUsers(firstItem['uid']);
      getCurrentMerchant(
        Provider.of<AppProvider>(context, listen: false).currentUser,
      );
      getCountLikes(firstItem['id']);
      getUserLike(firstItem['id']);
    }
  }

  @override
  void initState() {
    super.initState();
    getItems();
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

  void disposeVideoController(int itemIndex, int mediaIndex) {
    if (videoControllers.containsKey(itemIndex) &&
        videoControllers[itemIndex]!.containsKey(mediaIndex)) {
      videoControllers[itemIndex]![mediaIndex]?.dispose();
      videoControllers[itemIndex]!.remove(mediaIndex);
      // Remove item entry if empty
      if (videoControllers[itemIndex]!.isEmpty) {
        videoControllers.remove(itemIndex);
      }
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

    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        clipBehavior: Clip.none,
        backgroundColor: Colors.transparent,
        title: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                offset: Offset(0, 0),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(
              Iconsax.arrow_circle_left,
              color: Colors.white,
              size: 25,
            ),
            onPressed: () async {
              AppUtils.sNavigateToReplace(context, '/UserProfile', {
                'userId': widget.userProfileId,
              });
            },
          ),
        ),
        actions: [
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
                openSearch();
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
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
          disposeVideoController(_currentIndex, currentJndex);
          if (activeItemIndex != 0 && activeMediaIndex != 0) {
            videoControllers[activeItemIndex]?[activeMediaIndex]?.pause();
          }
          setState(() {
            activeItemIndex = index;
            activeMediaIndex = 0;
          });

          _currentIndex = index;
          currentJndex = 0; // دايما نرجع لأول ميديا لما ندخل عنصر جديد

          if (index >= items.length - 1) {
            await getItems();
          }

          Provider.of<AppProvider>(context, listen: false).setPutItems(items);
          // بتحط اي دي العناصر
          Provider.of<AppProvider>(
            context,
            listen: false,
          ).setItemId(int.parse(items[_currentIndex]['id']));

          Provider.of<AppProvider>(
            context,
            listen: false,
          ).setCurrentId(_currentIndex.toString());

          Provider.of<AppProvider>(
            context,
            listen: false,
          ).setCommentSwitch(items[_currentIndex]['comments']);
          Provider.of<AppProvider>(
            context,
            listen: false,
          ).setCurrentUsers(items[_currentIndex]['uid']);

          final path = items[_currentIndex];
          final mediaList = path['media']
              .toString()
              .split(',')
              .map((e) => e.trim())
              .toList();
          final firstMedia = mediaList[0];

          if (firstMedia.endsWith('.mp4')) {
            if (!videoControllers.containsKey(index) ||
                !videoControllers[index]!.containsKey(0)) {
              initializeVideoController(
                "https://pos7d.site/Globee/sys/uploads/Items/${path['id']}/$firstMedia",
                index,
                0,
              );
            }

            playVideo(index, 0); // ← دا لازم يكون بعد التهيئة أو لو كان موجود
          }
          await AppUtils.makeRequestsViews(
            "query",
            "UPDATE Items SET Views = Views + 1 WHERE id = '${path['id']}'",
          );
          getCountLikes(items[_currentIndex]['id']);
          getUserLike(items[_currentIndex]['id']);
          getCurrentMerchant(items[_currentIndex]['uid']);

          setState(() {});
        },
        itemBuilder: (context, index) {
          if (_currentIndex != index) {
            return Container(color: Colors.black);
          }
          return Stack(
            children: [
              PageView.builder(
                onPageChanged: (jndexChange) async {
                  if (activeItemIndex == 0) return;
                  disposeVideoController(index, currentJndex);
                  // أوقف الفيديو السابق
                  videoControllers[activeItemIndex]?[activeMediaIndex]?.pause();
                  setState(() {
                    activeMediaIndex = jndexChange;
                  });
                  disposeVideoController(index, currentJndex);
                  currentJndex = jndexChange;

                  final mediaList = items[index]['media']
                      .toString()
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                  final mediaFile = mediaList[jndexChange];

                  if (mediaFile.endsWith('.mp4')) {
                    if (!videoControllers.containsKey(index) ||
                        !videoControllers[index]!.containsKey(0)) {
                      initializeVideoController(
                        "https://pos7d.site/Globee/sys/uploads/Items/${items[index]['id']}/$mediaFile",
                        index,
                        jndexChange,
                      );
                    }

                    playVideo(
                      activeItemIndex,
                      jndexChange,
                    ); // ← دا لازم يكون بعد التهيئة أو لو كان موجود
                  }

                  setState(() {});
                },

                scrollDirection: Axis.horizontal,
                itemCount: items[index]['media'].toString().split(',').length,
                itemBuilder: (context, jndex) {
                  final mediaList = items[index]['media']
                      .toString()
                      .split(',')
                      .map((e) => e.trim())
                      .toList();
                  final mediaUrl = mediaList[jndex];
                  final isVideoFile = mediaUrl.toLowerCase().endsWith('.mp4');

                  if (isVideoFile) {
                    // Check if controller exists and is not disposed
                    if (!videoControllers.containsKey(index) ||
                        !videoControllers[index]!.containsKey(jndex) ||
                        videoControllers[index]![jndex]?.isVideoInitialized() !=
                            true) {
                      initializeVideoController(
                        "https://pos7d.site/Globee/sys/uploads/Items/${items[index]['id']}/$mediaUrl",
                        index,
                        jndex,
                      );
                    }
                  }

                  return Stack(
                    children: [
                      SizedBox(
                        height: MediaQuery.of(context).size.height,
                        width: MediaQuery.of(context).size.width,
                        child: isVideoFile
                            ? (videoControllers[index] != null &&
                                      videoControllers[index]![jndex] != null
                                  ? GestureDetector(
                                      onTap: () {
                                        final controller =
                                            videoControllers[index]?[jndex];
                                        togglePlayPause(controller);
                                      },
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          BetterPlayer(
                                            controller:
                                                videoControllers[index]![jndex]!,
                                          ),
                                          AnimatedOpacity(
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            opacity: showCenterIcon ? 1.0 : 0.0,
                                            child: AnimatedScale(
                                              duration: Duration(
                                                milliseconds: 300,
                                              ),
                                              scale: showCenterIcon ? 1.5 : 0.0,
                                              curve: Curves.easeOutBack,
                                              child: Icon(
                                                centerIcon,
                                                size: 60,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
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
                                          // Likes
                                          AnimatedOpacity(
                                            duration: Duration(
                                              milliseconds: 300,
                                            ),
                                            opacity: showCenterIconLikes
                                                ? 1.0
                                                : 0.0,
                                            child: AnimatedScale(
                                              duration: Duration(
                                                milliseconds: 300,
                                              ),
                                              scale: showCenterIconLikes
                                                  ? 1.5
                                                  : 0.0,
                                              curve: Curves.easeOutBack,
                                              child: Icon(
                                                centerIconLikes,
                                                size: 60,
                                                color: Colors.white.withOpacity(
                                                  0.9,
                                                ),
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
                                    )
                                  : const Center(
                                      child: SpinKitCircle(color: Colors.white),
                                    ))
                            : Image.network(
                                "https://pos7d.site/Globee/sys/uploads/Items/${items[index]['id']}/$mediaUrl",
                                fit: BoxFit.cover,
                              ),
                      ),
                    ],
                  );
                },
              ),

              Positioned(
                left: 0,
                bottom: videoDuration != null && videoPosition != null ? 30 : 0,
                right: 0, // عشان العرض ما يبقاش محدود
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.7),
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
                                      "https://pos7d.site/Globee/${currentUsers[0]['urlAvatar']}",
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Text(
                                    currentUsers[0]['Fullname'],
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : Container(),
                      SizedBox(height: 8),
                      Text(
                        items[index]['name'],
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        "${items[index]['price']} QAR",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        items[index]['description'],
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),

              // أزرار التفاعل
              Positioned(
                right: 16,
                bottom: 130,
                child: Column(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(
                          userLIkes != "0" ? Iconsax.like_15 : Iconsax.like_1,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () async {
                          toggleLikeUnlikes();
                          SharedPreferences prefx =
                              await SharedPreferences.getInstance();
                          var likes = await AppUtils.makeRequests(
                            "fetch",
                            "SELECT * FROM Likes WHERE user_id = '${prefx.getString("UID")}' AND item_id = '${items[index]['id']}' ",
                          );
                          if (likes[0] != null) {
                            await AppUtils.makeRequests(
                              "query",
                              "DELETE FROM Likes WHERE user_id = '${prefx.getString("UID")}' AND item_id = '${items[index]['id']}'",
                            );
                          } else {
                            await AppUtils.makeRequests(
                              "query",
                              "INSERT INTO Likes VALUES(NULL, '${prefx.getString("UID")}', '${items[index]['id']}', '${DateTime.now()}')",
                            );
                          }
                          getCountLikes(items[index]['id']);
                          getUserLike(items[index]['id']);
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
                            color: Colors.black.withOpacity(0.4),
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
                        onPressed: () {
                          showCommentsBottomSheet(context);
                        },
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "0",
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
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Iconsax.share,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "0",
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
                            color: Colors.black.withOpacity(0.4),
                            blurRadius: 6,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Iconsax.shopping_cart,
                          color: Colors.white,
                          size: 32,
                        ),
                        onPressed: () {},
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "0",
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
                      final newPosition = Duration(milliseconds: value.toInt());
                      currentController?.videoPlayerController?.seekTo(
                        newPosition,
                      );
                      setState(() {});
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
