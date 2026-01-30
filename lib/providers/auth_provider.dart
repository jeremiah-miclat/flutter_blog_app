import 'package:flutter/material.dart';
import 'package:flutter_blog_app/pages/login_page.dart';
import 'package:flutter_blog_app/pages/profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider extends StatelessWidget {
  const AuthProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AuthState>(
      stream: Supabase.instance.client.auth.onAuthStateChange,
      builder: (context, snapshot) {
        final session = Supabase.instance.client.auth.currentSession;
        if (session != null) {
          return ProfilePage();
        } else {
          return LoginPage();
        }
      },
    );
  }
}
