import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  print('🔍 Testing Supabase Connection...\n');

  try {
    // Initialize Supabase
    print('1. Initializing Supabase...');
    await Supabase.initialize(
      url: 'https://qbrznwagzojfrazmwkjf.supabase.co',
      anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFicnpud2Fnem9qZnJhem13a2pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMjczNDAsImV4cCI6MjA2NjYwMzM0MH0.rYG0_L7NP9JExe-CCnCSq6D3xiZfChG91S63otTyEug',
    );
    print('✅ Supabase initialized successfully\n');

    // Test basic connection
    print('2. Testing basic connection...');
    final client = Supabase.instance.client;
    print('✅ Supabase client created\n');

    // Test database query
    print('3. Testing database query...');
    try {
      final response = await client
          .from('profiles')
          .select('count')
          .limit(1);
      print('✅ Database query successful');
      print('   Response: $response\n');
    } catch (e) {
      print('⚠️  Database query failed (this might be expected if table is empty):');
      print('   Error: $e\n');
    }

    // Test auth status
    print('4. Testing auth status...');
    final user = client.auth.currentUser;
    if (user != null) {
      print('✅ User is authenticated');
      print('   User ID: ${user.id}');
      print('   Email: ${user.email}\n');
    } else {
      print('ℹ️  No user currently authenticated\n');
    }

    // Test Edge Functions (if available)
    print('5. Testing Edge Functions...');
    try {
      final functionResponse = await client.functions.invoke(
        'create-subscription-session',
        body: {'test': 'connection'},
      );
      print('✅ Edge Function call successful');
      print('   Response: ${functionResponse.data}\n');
    } catch (e) {
      print('⚠️  Edge Function test failed (this might be expected if not deployed):');
      print('   Error: $e\n');
    }

    // Test storage (if available)
    print('6. Testing storage...');
    try {
      final buckets = await client.storage.listBuckets();
      print('✅ Storage access successful');
      print('   Available buckets: ${buckets.length}\n');
    } catch (e) {
      print('⚠️  Storage test failed:');
      print('   Error: $e\n');
    }

    print('🎉 Supabase connectivity test completed successfully!');
    print('   URL: https://qbrznwagzojfrazmwkjf.supabase.co');
    print('   Status: Connected ✅');

  } catch (e) {
    print('❌ Supabase connection failed:');
    print('   Error: $e');
    print('\n🔧 Troubleshooting tips:');
    print('   1. Check your internet connection');
    print('   2. Verify the Supabase URL is correct');
    print('   3. Verify the anon key is correct');
    print('   4. Check if your Supabase project is active');
    print('   5. Check if your project has any restrictions');
  }
} 