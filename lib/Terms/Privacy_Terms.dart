import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class PrivacyTerms extends StatefulWidget {
  final String termsPage;

  const PrivacyTerms({super.key, required this.termsPage});

  @override
  State<PrivacyTerms> createState() => _PrivacyTermsState();
}

class _PrivacyTermsState extends State<PrivacyTerms> {
  WebViewController? _controller;
  String lang = "eng";
  List languages = [];

  Future getLang() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    setState(() {
      lang = prefx.getString("Lang")!;
    });
  }

  Future<void> getInvoiceScreen() async {
    setState(() {
      _controller = WebViewController()
        ..loadRequest(
          Uri.parse(
            "https://pos7d.site/Globee/${widget.termsPage}.php?langDB=$lang&k=${DateTime.now().millisecondsSinceEpoch}",
          ),
        )
        ..setJavaScriptMode(JavaScriptMode.unrestricted);
    });
  }

  @override
  void initState() {
    super.initState();
    getLang();
    getInvoiceScreen();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () async {
            context.go('/login');
          },
          icon: Icon(Iconsax.arrow_circle_left),
        ),
        forceMaterialTransparency: true,
        centerTitle: true,
        backgroundColor: Colors.transparent,
      ),
      body: WebViewWidget(controller: _controller!),
    );
  }
}
