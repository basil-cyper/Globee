import 'package:globee/Core/Utils.dart';
import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  List<Map<String, dynamic>> allItems = [];
  List<Map<String, dynamic>> filteredItems = [];
  TextEditingController searchController = TextEditingController();

  Future fetchItems() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    await AppUtils.makeRequests(
      "query",
      "UPDATE Users SET last_activity = '${DateTime.now()}' WHERE uid = '${prefx.getString("UID")}' ",
    );
    var itemsx = await AppUtils.makeRequests(
      "fetch",
      "SELECT id, name FROM Items WHERE visibility = 'Public' AND status = '1' ",
    );

    if (itemsx != null && itemsx is List) {
      setState(() {
        allItems = List<Map<String, dynamic>>.from(itemsx);
        filteredItems = allItems; // في البداية كلها ظاهرة
      });
    }
  }

  String lang = "eng";
  List languages = [];

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

  void filterItems(String query) {
    final results = query.isEmpty
        ? allItems
        : allItems
              .where(
                (item) => item['name'].toString().toLowerCase().contains(
                  query.toLowerCase(),
                ),
              )
              .toList();

    setState(() {
      filteredItems = results;
    });
  }

  @override
  void initState() {
    super.initState();
    getLang();
    fetchItems();
    searchController.addListener(() {
      filterItems(searchController.text);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: lang == 'arb' ? TextDirection.rtl : TextDirection.ltr,
      child: languages.isEmpty
          ? Scaffold(backgroundColor: Colors.white)
          : GestureDetector(
              onTap: () {
                FocusScope.of(context).unfocus();
              },
              child: Scaffold(
                backgroundColor: Colors.white,
                appBar: AppBar(
                  forceMaterialTransparency: true,
                  backgroundColor: Colors.transparent,
                  leading: IconButton(
                    icon: Icon(
                      lang == 'arb'
                          ? Iconsax.arrow_circle_right
                          : Iconsax.arrow_circle_left,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  title: TextFormField(
                    controller: searchController,
                    onChanged: (value) {
                      final query = value.toLowerCase();

                      setState(() {
                        filteredItems = allItems.where((item) {
                          final itemName = item['name']
                              .toString()
                              .toLowerCase();
                          return itemName.contains(query);
                        }).toList();
                      });
                    },
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      hintText: languages[29][lang],
                      contentPadding: EdgeInsets.symmetric(
                        vertical: 0,
                        horizontal: 20,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(50),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                body: filteredItems.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Iconsax.box_remove, size: 100),
                            SizedBox(height: 10),
                            Text(
                              "No Items Found",
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          children: filteredItems.map((item) {
                            return ListTile(
                              onTap: () {
                                Navigator.pop(context, item['id']);
                              },
                              title: Text(item['name']),
                              trailing: Icon(Iconsax.search_normal),
                            );
                          }).toList(),
                        ),
                      ),
              ),
            ),
    );
  }
}
