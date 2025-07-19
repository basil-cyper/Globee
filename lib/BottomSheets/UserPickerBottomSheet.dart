import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class SimpleMediaPicker {
  static final ImagePicker _picker = ImagePicker();

  static Future<XFile?> openCamera(BuildContext context) async {
    return await _picker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
    );
  }

  static Future<XFile?> openGallery(BuildContext context) async {
    return await _picker.pickImage(source: ImageSource.gallery);
  }

  static void showPicker(BuildContext context) {
    showModalBottomSheet(
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
                leading: const Icon(Iconsax.camera),
                title: const Text('التقاط صورة بالكاميرا'),
                onTap: () async {
                  Navigator.pop(ctx);
                  XFile? file = await openCamera(context);
                  if (file != null) {
                    Provider.of<AppProvider>(
                      context,
                      listen: false,
                    ).addUser(file.path);
                  }
                },
              ),
              ListTile(
                leading: const Icon(Iconsax.gallery),
                title: const Text('اختيار صورة من المعرض'),
                onTap: () async {
                  Navigator.pop(ctx);
                  XFile? file = await openGallery(context);
                  if (file != null) {
                    Provider.of<AppProvider>(
                      context,
                      listen: false,
                    ).addUser(file.path);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
