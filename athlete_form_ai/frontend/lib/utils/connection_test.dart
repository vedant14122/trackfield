import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:convert';
import '../config/api_config.dart';

class ConnectionTest {
  static Future<Map<String, dynamic>> testAllConnections() async {
    final results = <String, dynamic>{};
    
    // Test backend API
    results['backend'] = await testBackendConnection();
    
    // Test Supabase
    results['supabase'] = await testSupabaseConnection();
    
    return results;
  }
  
  static Future<Map<String, dynamic>> testBackendConnection() async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.healthEndpoint),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'status': 'success',
          'message': 'Backend API is accessible',
          'data': data,
          'url': ApiConfig.healthEndpoint,
        };
      } else {
        return {
          'status': 'error',
          'message': 'Backend API returned status ${response.statusCode}',
          'url': ApiConfig.healthEndpoint,
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Backend API connection failed: ${e.toString()}',
        'url': ApiConfig.healthEndpoint,
        'error': e.toString(),
      };
    }
  }
  
  static Future<Map<String, dynamic>> testSupabaseConnection() async {
    try {
      final client = Supabase.instance.client;
      
      // Test basic connection by trying to get current user
      final user = client.auth.currentUser;
      
      // Test database connection with a simple query
      final response = await client
          .from('profiles')
          .select('count')
          .limit(1);
      
              return {
          'status': 'success',
          'message': 'Supabase connection successful',
          'user': user?.email ?? 'No user logged in',
          'url': ApiConfig.supabaseUrl,
          'data': response,
        };
    } catch (e) {
      return {
        'status': 'error',
        'message': 'Supabase connection failed: ${e.toString()}',
        'url': ApiConfig.supabaseUrl,
        'error': e.toString(),
      };
    }
  }
  
  static String getConnectionSummary(Map<String, dynamic> results) {
    final backendStatus = results['backend']['status'];
    final supabaseStatus = results['supabase']['status'];
    
    if (backendStatus == 'success' && supabaseStatus == 'success') {
      return 'All connections successful';
    } else if (backendStatus == 'error' && supabaseStatus == 'error') {
      return 'All connections failed';
    } else if (backendStatus == 'error') {
      return 'Backend API connection failed';
    } else {
      return 'Supabase connection failed';
    }
  }
  
  static List<String> getTroubleshootingSteps(Map<String, dynamic> results) {
    final steps = <String>[];
    
    if (results['backend']['status'] == 'error') {
      steps.add('Check if the backend server is running on ${ApiConfig.apiBaseUrl}');
      steps.add('Verify your network connection');
      steps.add('Check if the backend server is accessible from your device');
    }
    
    if (results['supabase']['status'] == 'error') {
      steps.add('Check your internet connection');
      steps.add('Verify the Supabase project is active');
      steps.add('Check if there are any firewall restrictions');
    }
    
    return steps;
  }
} 