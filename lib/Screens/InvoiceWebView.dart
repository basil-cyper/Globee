import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax/iconsax.dart';
import 'package:globee/Core/Utils.dart';
import 'package:globee/provider/App_Provider.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InvoiceWebView extends StatefulWidget {
  final String orderId;
  final String? payment;
  final String? shipId;
  final String? custId;
  const InvoiceWebView({
    super.key,
    required this.orderId,
    this.payment,
    this.shipId,
    this.custId,
  });

  @override
  State<InvoiceWebView> createState() => _InvoiceWebViewState();
}

class _InvoiceWebViewState extends State<InvoiceWebView> {
  WebViewController? _controller;
  String? paymentSessionUrl;

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

  Future<void> getInvoiceScreen() async {
    SharedPreferences prefx = await SharedPreferences.getInstance();
    setState(() {
      _controller = WebViewController()
        ..loadRequest(
          Uri.parse(
            "https://pos7d.site/Globee/Mazo_Invoice.php?uid=${widget.payment == 'Customer' ? '' : prefx.getString("UID")}&oid=${widget.orderId}&shipId=${widget.shipId != "" ? widget.shipId : Provider.of<AppProvider>(context, listen: false).shipId}&custId=${widget.custId}&lang=$lang&k=${DateTime.now().millisecondsSinceEpoch}",
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
            SharedPreferences prefx = await SharedPreferences.getInstance();
            if (widget.payment == "") {
              context.go('/customersOrders');
            } else {
              context.go('/paymentSuccess');
            }
          },
          icon: Icon(Iconsax.arrow_circle_left),
        ),
        actions: [
          IconButton(
            icon: const Icon(Iconsax.refresh),
            onPressed: () {
              _controller?.reload();
            },
          ),
        ],
        forceMaterialTransparency: true,
        centerTitle: true,
        title: Text(languages[80][lang], style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.transparent,
      ),
      body: WebViewWidget(controller: _controller!),
    );
  }
}
