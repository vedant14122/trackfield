import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionPage extends StatelessWidget {
  final String email; // Pass the user's email

  // Replace these with your actual Stripe Price IDs and prices
  static const String dashAiPriceId = 'price_1RflipJW4cJEU4chj6AR93Lk';         // Dash AI
  static const String dashAiPresalePriceId = 'price_1RisRNJW4cJEU4chvtcdfOPd';  // Dash AI Presale
  static const String dashAiBetaPriceId = 'price_1RisT2JW4cJEU4chCrjXMKcE';     // Dash AI Beta Tester Discount

  static const String dashAiPrice = ' 5.99/month';         // Example price
  static const String dashAiPresalePrice = ' 4.99/month';   // Example price
  static const String dashAiBetaPrice = ' 4.59/month';      // Example price

  const SubscriptionPage({Key? key, required this.email}) : super(key: key);

  Future<void> startSubscriptionCheckout(BuildContext context, String priceId) async {
    try {
      final response = await http.post(
        Uri.parse('https://qbrznwagzojfrazmwkjf.supabase.co/functions/v1/create-subscription-session'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'priceId': priceId}),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final url = data['url'];
        if (await canLaunchUrl(Uri.parse(url))) {
          await launchUrl(Uri.parse(url));
        } else {
          throw 'Could not launch checkout URL';
        }
      } else {
        throw 'Failed to create checkout session: ${response.statusCode}';
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Choose a Subscription')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          ListTile(
            title: const Text('Dash AI'),
            subtitle: Text('Standard monthly subscription\n$dashAiPrice'),
            trailing: ElevatedButton(
              onPressed: () => startSubscriptionCheckout(context, dashAiPriceId),
              child: const Text('Subscribe'),
            ),
          ),
          ListTile(
            title: const Text('Dash AI Presale'),
            subtitle: Text('Special presale offer\n$dashAiPresalePrice'),
            trailing: ElevatedButton(
              onPressed: () => startSubscriptionCheckout(context, dashAiPresalePriceId),
              child: const Text('Subscribe'),
            ),
          ),
          ListTile(
            title: const Text('Dash AI Beta Tester Discount'),
            subtitle: Text('Discounted for beta testers\n$dashAiBetaPrice'),
            trailing: ElevatedButton(
              onPressed: () => startSubscriptionCheckout(context, dashAiBetaPriceId),
              child: const Text('Subscribe'),
            ),
          ),
        ],
      ),
    );
  }
} 