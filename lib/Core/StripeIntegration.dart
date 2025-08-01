// import 'package:dio/dio.dart';
// import 'package:flutter_stripe/flutter_stripe.dart';
// import 'package:globee/Core/ApiKeys.dart';

// abstract class PaymentManager {
//   static Future<String> makePayment(int amount, String currency) async {
//     try {
//       String clientSecret = await _getClientSecret(amount.toString(), currency);
//       await _initializePaymentSheet(clientSecret);
//       await Stripe.instance.presentPaymentSheet();

//       // Retrieve the payment status
//       final paymentIntent = await Stripe.instance.retrievePaymentIntent(
//         clientSecret,
//       );
//       if (paymentIntent.status == PaymentIntentsStatus.Succeeded) {
//         return "Succeeded";
//       } else {
//         return "Failed";
//       }
//     } catch (error) {
//       throw Exception("Error creating payment: $error");
//     }
//   }

//   static Future<void> _initializePaymentSheet(String clientSecret) async {
//     await Stripe.instance.initPaymentSheet(
//       paymentSheetParameters: SetupPaymentSheetParameters(
//         paymentIntentClientSecret: clientSecret,
//         merchantDisplayName: "Basil Mohamed",
//       ),
//     );
//   }

//   static Future<String> _getClientSecret(String amount, String currency) async {
//     Dio dio = Dio();
//     var response = await dio.post(
//       "https://api.stripe.com/v1/payment_intents",
//       options: Options(
//         headers: {
//           "Authorization": "Bearer ${ApiKeys.secretKey}",
//           "Content-Type": "application/x-www-form-urlencoded",
//         },
//       ),
//       data: {"amount": amount, "currency": currency},
//     );
//     return response.data['client_secret'];
//   }
// }
