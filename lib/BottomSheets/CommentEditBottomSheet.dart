import 'package:globee/Core/Utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SimpleMoreComment {
  static Future<dynamic> showItemComments(
    BuildContext context,
    commentId,
  ) async {
    SharedPreferences prefx = await SharedPreferences.getInstance();

    String lang = prefx.getString("Lang")!;

    var results = await AppUtils.makeRequests(
      "fetch",
      "SELECT $lang FROM Languages ",
    );

    return await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Directionality(
          textDirection: TextDirection.rtl,
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
                  leading: const Icon(Iconsax.edit),
                  title: Text(results[49][lang]),
                  onTap: () async {
                    var currentComment = await AppUtils.makeRequests(
                      "fetch",
                      "SELECT id, comment FROM Comments WHERE id = '$commentId'",
                    );
                    Navigator.pop(context, {
                      'deleted': false,
                      'cComment': currentComment,
                    });
                  },
                ),
                ListTile(
                  leading: const Icon(Iconsax.trash),
                  title: Text(results[50][lang]),
                  onTap: () async {
                    await AppUtils.makeRequests(
                      "query",
                      "DELETE FROM Comments WHERE id = '$commentId'",
                    );
                    Navigator.pop(context, {'deleted': true});
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
