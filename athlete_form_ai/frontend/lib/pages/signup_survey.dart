import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SurveyPage extends StatefulWidget {
  @override
  State<SurveyPage> createState() => _SurveyPageState();
}

class _SurveyPageState extends State<SurveyPage> {
  final _formKey = GlobalKey<FormState>();

  String name = '';
  String email = '';
  String goal = '';
  String experience = '';
  bool showPayment = false;

  // Replace with your Stripe Checkout link
  final String stripeUrl = "https://buy.stripe.com/test_cN2aGd1nR9rN6H6288";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Welcome Survey")),
      body: showPayment
          ? WebView(
              initialUrl: stripeUrl,
              javascriptMode: JavascriptMode.unrestricted,
            )
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    Text(
                      "Before you begin, please answer a few questions:",
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 20),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Full Name"),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      onSaved: (value) => name = value ?? '',
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: "Email Address"),
                      validator: (value) =>
                          value == null || !value.contains('@') ? "Enter a valid email" : null,
                      onSaved: (value) => email = value ?? '',
                    ),
                    TextFormField(
                      decoration: InputDecoration(labelText: "What is your training goal?"),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      onSaved: (value) => goal = value ?? '',
                    ),
                    TextFormField(
                      decoration:
                          InputDecoration(labelText: "How experienced are you in track & field?"),
                      validator: (value) => value == null || value.isEmpty ? "Required" : null,
                      onSaved: (value) => experience = value ?? '',
                    ),
                    SizedBox(height: 30),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          _formKey.currentState!.save();
                          setState(() => showPayment = true);
                        }
                      },
                      child: Text("Continue to Payment"),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
