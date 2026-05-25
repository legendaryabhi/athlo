import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String supabaseUrl = 'https://jxmjwvgoxqeowrctlwiy.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imp4bWp3dmdveHFlb3dyY3Rsd2l5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk1MDYxMTMsImV4cCI6MjA5NTA4MjExM30.k3DauvmyvEQWv5NxeP_QOVBxJbUullAhcLGEE-_XTdo';

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
    );
  }

  static SupabaseClient get client => Supabase.instance.client;
}
