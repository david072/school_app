import 'package:flutter/material.dart';

import 'auth/login_page.dart';

void main() {
  runApp(const MaterialApp(
    debugShowCheckedModeBanner: false,
    title: 'School App',
    home: LoginPage(),
  ));
}