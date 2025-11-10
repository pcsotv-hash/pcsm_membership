import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../services/api_service.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({Key? key}) : super(key: key);
  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final ApiService api = ApiService();
  final TextEditingController user = TextEditingController(text: "admin");
  final TextEditingController pass = TextEditingController(text: "pcsm2025");
  bool loading = false;

  void login() async {
    setState(()=>loading=true);
    final res = await api.adminLogin(user.text.trim(), pass.text.trim());
    setState(()=>loading=false);
    if (res['status'] == 1 || res['status'] == "1") {
      // store role if provided, navigate
      Navigator.pushReplacementNamed(context, '/admin-dashboard', arguments: res);
    } else {
      Fluttertoast.showToast(msg: res['message'] ?? "Login failed");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text("Admin Login")),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(children:[
            TextField(controller: user, decoration: const InputDecoration(labelText: "Username")),
            const SizedBox(height:8),
            TextField(controller: pass, decoration: const InputDecoration(labelText: "Password"), obscureText: true),
            const SizedBox(height:12),
            ElevatedButton(onPressed: loading?null:login, child: Text(loading?"Logging in...":"Login"))
          ]),
        ),
      ),
    );
  }
}
