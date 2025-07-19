import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:globee/Core/Theme.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart' as datol;
import 'package:provider/provider.dart';

void showItemDetailsBottomSheet(
  BuildContext context, {
  required String itemId,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: FutureBuilder(
          future: _fetchItemData(context, itemId),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Container(
                height: 200,
                alignment: Alignment.center,
                child: SpinKitDoubleBounce(
                  color: AppTheme.primaryColor,
                  size: 30.0,
                ),
              );
            }

            final data = snapshot.data as Map<String, dynamic>;
            final request = data['request'];
            final itemCount = data['itemCount'];
            final formattedDateMDay = data['formattedDateMDay'];
            final formattedDateYear = data['formattedDateYear'];
            final views = data['views'];

            return Container(
              height: 600,
              padding: const EdgeInsets.all(20),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 5,
                        margin: EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    Text(
                      "الوصف",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Divider(),
                    SizedBox(height: 15),
                    Text(
                      request[0]['name'],
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 25),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildInfoColumn(
                          Icons.favorite,
                          itemCount[0]['likes'],
                          'لايكات',
                        ),
                        _buildInfoColumn(
                          Icons.remove_red_eye,
                          views,
                          'مشاهدات',
                        ),
                        _buildInfoColumn(
                          Icons.calendar_today,
                          "$formattedDateMDay - $formattedDateYear",
                          'تاريخ النشر',
                        ),
                      ],
                    ),
                    SizedBox(height: 25),
                  ],
                ),
              ),
            );
          },
        ),
      );
    },
  );
}

Widget _buildInfoColumn(IconData icon, String value, String label) {
  return Column(
    children: [
      Text(
        value.split('-')[0],
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 20,
          color: Colors.black,
        ),
      ),
      SizedBox(height: 4),
      Text(
        value.split('-').any((part) => RegExp(r'[a-zA-Zأ-ي]').hasMatch(part))
            ? value.split("-")[1]
            : label,
        style: TextStyle(color: Colors.grey[600], fontSize: 14),
      ),
    ],
  );
}

Future<Map<String, dynamic>> _fetchItemData(
  BuildContext context,
  String itemId,
) async {
  var request = await AppUtils.makeRequests(
    "fetch",
    "SELECT * FROM Items WHERE id = '$itemId' ",
  );

  final formattedDateMDay = datol.DateFormat(
    'MMM dd',
  ).format(DateTime.parse(request[0]['created_at']));
  final formattedDateYear = datol.DateFormat(
    'yyyy',
  ).format(DateTime.parse(request[0]['created_at']));

  var itemCount = await AppUtils.makeRequests(
    "fetch",
    "SELECT COUNT(id) as likes FROM Likes WHERE item_id = '$itemId'",
  );

  final views = Provider.of<AppProvider>(context, listen: false)
      .putItems[int.parse(
        Provider.of<AppProvider>(context, listen: false).currentIndex,
      )]['Views']
      .toString();

  return {
    'request': request,
    'itemCount': itemCount,
    'formattedDateMDay': formattedDateMDay,
    'formattedDateYear': formattedDateYear,
    'views': views,
  };
}
