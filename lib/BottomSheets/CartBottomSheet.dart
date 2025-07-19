import 'package:globee/Core/Utils.dart';
import 'package:globee/Widgets/Back_Button.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class CartBottomSheet {
  static void showCart(
    BuildContext context,
    String cartId,
    int qttData,
    int qtt,
    void Function(int newQtt) onQttChanged,
  ) {
    showModalBottomSheet(
      isDismissible: false,
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        int count = 0;
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return Stack(
              children: [
                Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(16),
                      topRight: Radius.circular(16),
                    ),
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 200,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    if (count != 0) {
                                      count = count > 0 ? count - 1 : 0;
                                    } else {
                                      qtt = qtt > 0 ? qtt - 1 : 0;
                                    }
                                  });
                                  AppUtils.makeRequestsViews(
                                    "query",
                                    "UPDATE Cart SET qtt = ${count == 0 ? qtt : count} WHERE id = '$cartId' ",
                                  );
                                  onQttChanged(count == 0 ? qtt : count);
                                },
                                child: RectButtonWidget(bicon: Iconsax.minus),
                              ),
                              Text(
                                "${count == 0 ? qtt : count}",
                                style: TextStyle(fontSize: 30),
                              ),
                              GestureDetector(
                                onTap: () {
                                  if (count < qttData) {
                                    setState(() {
                                      count++;
                                      AppUtils.makeRequestsViews(
                                        "query",
                                        "UPDATE Cart SET qtt = $count WHERE id = '$cartId'",
                                      );
                                      onQttChanged(count);
                                    });
                                  }
                                },
                                child: RectButtonWidget(bicon: Iconsax.add),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 10,
                  child: GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Iconsax.close_circle, size: 30),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
