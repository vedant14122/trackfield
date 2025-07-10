import 'package:flutter/material.dart';
import 'utils/connection_test.dart';

class ConnectionErrorPage extends StatefulWidget {
  final String error;
  final VoidCallback? onRetry;

  const ConnectionErrorPage({
    Key? key,
    required this.error,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ConnectionErrorPage> createState() => _ConnectionErrorPageState();
}

class _ConnectionErrorPageState extends State<ConnectionErrorPage> {
  bool _isTesting = false;
  Map<String, dynamic>? _testResults;

  Future<void> _runConnectionTest() async {
    setState(() {
      _isTesting = true;
    });

    try {
      final results = await ConnectionTest.testAllConnections();
      setState(() {
        _testResults = results;
        _isTesting = false;
      });
    } catch (e) {
      setState(() {
        _testResults = {
          'error': 'Test failed: ${e.toString()}',
        };
        _isTesting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Error Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.wifi_off,
                  size: 60,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 32),

              // Error Title
              const Text(
                'Connection Error',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const SizedBox(height: 16),

              // Error Message
              Text(
                'Unable to connect to Dash AI services',
                style: TextStyle(
                  fontSize: 18,
                  color: Theme.of(context).textTheme.bodyLarge?.color?.withValues(alpha: 0.7),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // Error Details Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.info_outline, color: Colors.orange),
                          SizedBox(width: 8),
                          Text(
                            'Error Details',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          widget.error,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Troubleshooting Steps
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.troubleshoot, color: Colors.blue),
                          SizedBox(width: 8),
                          Text(
                            'Troubleshooting Steps',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      _TroubleshootingStep(
                        number: '1',
                        text: 'Check your internet connection',
                      ),
                      _TroubleshootingStep(
                        number: '2',
                        text: 'Make sure you\'re not behind a firewall',
                      ),
                      _TroubleshootingStep(
                        number: '3',
                        text: 'Try closing and reopening the app',
                      ),
                      _TroubleshootingStep(
                        number: '4',
                        text: 'Contact support if the problem persists',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Action Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: widget.onRetry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _isTesting ? null : _runConnectionTest,
                      icon: _isTesting 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.wifi_tethering),
                      label: Text(_isTesting ? 'Testing...' : 'Test Connections'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
              
              // Test Results
              if (_testResults != null) ...[
                const SizedBox(height: 24),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _testResults!['error'] != null 
                                  ? Icons.error 
                                  : Icons.check_circle,
                              color: _testResults!['error'] != null 
                                  ? Colors.red 
                                  : Colors.green,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Connection Test Results',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_testResults!['error'] != null) ...[
                          Text(
                            'Test Error: ${_testResults!['error']}',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ] else ...[
                          _buildTestResult('Backend API', _testResults!['backend']),
                          const SizedBox(height: 8),
                          _buildTestResult('Supabase', _testResults!['supabase']),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTestResult(String title, Map<String, dynamic> result) {
    final isSuccess = result['status'] == 'success';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSuccess ? Colors.green : Colors.red,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isSuccess ? Icons.check_circle : Icons.error,
                color: isSuccess ? Colors.green : Colors.red,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            result['message'] ?? 'Unknown status',
            style: TextStyle(
              fontSize: 12,
              color: isSuccess ? Colors.green[700] : Colors.red[700],
            ),
          ),
          if (result['url'] != null) ...[
            const SizedBox(height: 4),
            Text(
              'URL: ${result['url']}',
              style: const TextStyle(fontSize: 10, color: Colors.grey),
            ),
          ],
        ],
      ),
    );
  }

  String _getErrorType(String error) {
    if (error.contains('No host specified')) {
      return 'Configuration Error';
    } else if (error.contains('Connection failed')) {
      return 'Network Error';
    } else if (error.contains('timeout')) {
      return 'Timeout Error';
    } else if (error.contains('unauthorized')) {
      return 'Authentication Error';
    } else {
      return 'Unknown Error';
    }
  }
}

class _TroubleshootingStep extends StatelessWidget {
  final String number;
  final String text;

  const _TroubleshootingStep({
    required this.number,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                number,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
} 