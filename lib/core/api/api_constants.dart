import 'package:flutter/foundation.dart';

class ApiConstants {
  static const String baseUrl = "https://nb-listings-backend.vercel.app/api/v1";
  static const supabaseUrl = "https://sopbhhpvyorspvtcwkxb.supabase.co";
  static const supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InNvcGJoaHB2eW9yc3B2dGN3a3hiIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODM5MjY0MDgsImV4cCI6MjA5OTUwMjQwOH0.O_mQkMfmkP4E3NwYjxpAdL080TevKA8qFtGhV6rFEqo";

  static const login = "/auth/login";
  static const register = "/auth/register";
  static const me = "/auth/me";
  static const health = "/health";
}