import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:greenbank/pages/HomePage.dart';
import 'package:greenbank/pages/RegisterPage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LoginPageWidget extends StatefulWidget {
  const LoginPageWidget({super.key});

  @override
  State<LoginPageWidget> createState() => _LoginPageWidgetState();
}

class _LoginPageWidgetState extends State<LoginPageWidget> {
  final TextEditingController _emailAddressLoginTextController =
  TextEditingController();
  final TextEditingController _passwordLoginTextController =
  TextEditingController();
  bool _passwordLoginVisibility = false;

  void _passwordLoginVisibilityToggle() {
    setState(() {
      _passwordLoginVisibility = !_passwordLoginVisibility;
    });
  }

  void _login() async {
    var url = Uri.parse('http://192.168.1.14:8080/auth/login');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': _emailAddressLoginTextController.text,
        'senha': _passwordLoginTextController.text,
      }),
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);

      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);
      await prefs.setString('email', _emailAddressLoginTextController.text); // Adicione essa linha

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Logado')),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            content: Text('Erro no Login: ${response.body}'),
          );
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              controller: _emailAddressLoginTextController,
              decoration: const InputDecoration(labelText: 'E-mail'),
            ),
            TextFormField(
              controller: _passwordLoginTextController,
              obscureText: _passwordLoginVisibility,
              decoration: InputDecoration(
                labelText: 'Senha',
                suffixIcon: IconButton(
                  onPressed: _passwordLoginVisibilityToggle,
                  icon: _passwordLoginVisibility
                      ? const Icon(Icons.visibility_off)
                      : const Icon(Icons.visibility),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _login,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                textStyle: const TextStyle(color: Colors.black),
              ),
              child: const Text('Login'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => RegisterPage()),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.greenAccent,
                textStyle: const TextStyle(color: Colors.black),
              ),
              child: const Text('Registrar'),
            ),
          ],
        ),
      ),
    );
  }
}