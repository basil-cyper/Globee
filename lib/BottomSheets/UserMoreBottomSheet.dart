import 'package:globee/Core/Utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

class SimpleUserMore {
  static Future showUserMore(BuildContext context, itmid) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext ctx) {
        return Container(
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
                title: const Text('Edit Item'),
                onTap: () async {
                  AppUtils.sNavigateToReplace(context, '/EditDetailsItem', {
                    'item_id': itmid,
                  });
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.trash),
                title: const Text('Delete Item'),
                onTap: () async {
                  AppUtils.makeRequests(
                    "query",
                    "DELETE FROM Items WHERE id = '$itmid'",
                  );
                  Navigator.pop(context, 'koko');
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
