import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'home_page.dart';
import 'main.dart';
import 'connection_error_page.dart';

class LoginPage extends StatefulWidget {
  final ThemeNotifier themeNotifier;
  const LoginPage({Key? key, required this.themeNotifier}) : super(key: key);

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  String? _errorStack;

  Future<void> _signInOrSignUp(bool isSignUp) async {
    setState(() {
      _isLoading = true;
      _error = null;
      _errorStack = null;
    });
    final supabase = Supabase.instance.client;
    try {
      if (isSignUp) {
        await supabase.auth.signUp(
          email: _emailController.text,
          password: _passwordController.text,
        );
      } else {
        await supabase.auth.signInWithPassword(
          email: _emailController.text,
          password: _passwordController.text,
        );
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => HomePage(themeNotifier: widget.themeNotifier)),
        );
      }
    } on AuthException catch (e, stack) {
      setState(() {
        _error = e.message;
        _errorStack = stack.toString();
      });
    } catch (e, stack) {
      String errorMessage = e.toString();
      if (errorMessage.contains('No host specified') ||
          errorMessage.contains('Connection failed') ||
          errorMessage.contains('timeout') ||
          errorMessage.contains('network')) {
        errorMessage = 'Connection error: Unable to reach Dash AI services.\n\nReason: $e\n\nPlease check your internet connection and try again.';
      }
      setState(() {
        _error = errorMessage;
        _errorStack = stack.toString();
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login / Signup'),
        actions: [
          TextButton(
            onPressed: () => setState(() => widget.themeNotifier.toggleTheme()),
            child: Text(widget.themeNotifier.themeMode == ThemeMode.dark ? 'Light Mode' : 'Dark Mode'),
            style: TextButton.styleFrom(foregroundColor: Colors.white),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 600;
          return Center(
            child: Container(
              width: isWide ? 400 : double.infinity,
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(labelText: 'Email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  if (_error != null && _error!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                    if (_errorStack != null && _errorStack!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.vertical,
                          child: Text(
                            _errorStack!,
                            style: const TextStyle(
                              color: Colors.red,
                              fontSize: 10,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _signInOrSignUp(false),
                        child: _isLoading ? const CircularProgressIndicator() : const Text('Login'),
                      ),
                      ElevatedButton(
                        onPressed: _isLoading ? null : () => _signInOrSignUp(true),
                        child: _isLoading ? const CircularProgressIndicator() : const Text('Sign Up'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => HomePage(themeNotifier: widget.themeNotifier),
                        ),
                      );
                    },
                    child: const Text('Skip Login (Dev Only)'),
                  ),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ConnectionErrorPage(
                            error: 'Manual connection test',
                          ),
                        ),
                      );
                    },
                    child: const Text('Test Connection'),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

 