class ApiConfig {
  // Development configuration
  static const bool isDevelopment = true;
  
  // API Base URLs
  static const String localApiUrl = 'http://localhost:8000';
  static const String productionApiUrl = 'https://your-production-api.com'; // Replace with actual production URL
  
  // Get the appropriate API URL based on environment
  static String get apiBaseUrl {
    if (isDevelopment) {
      return localApiUrl;
    } else {
      return productionApiUrl;
    }
  }
  
  // Specific API endpoints
  static String get analyzeEndpoint => '$apiBaseUrl/analyze';
  static String get chatEndpoint => '$apiBaseUrl/chat';
  static String get healthEndpoint => '$apiBaseUrl/health';
  
  // Supabase configuration
  static const String supabaseUrl = 'https://qbrznwagzojfrazmwkjf.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InFicnpud2Fnem9qZnJhem13a2pmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTEwMjczNDAsImV4cCI6MjA2NjYwMzM0MH0.rYG0_L7NP9JExe-CCnCSq6D3xiZfChG91S63otTyEug';
  
  // Timeout configuration
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 60);
  
  // Retry configuration
  static const int maxRetries = 3;
  static const Duration retryDelay = Duration(seconds: 2);
} 