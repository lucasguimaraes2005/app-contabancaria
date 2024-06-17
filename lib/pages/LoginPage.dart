import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';


import 'HomePage.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _user = TextEditingController();
  final TextEditingController _pass = TextEditingController();
  bool _ocultar = false;

  void _botaoPassVisibility() {
    setState(() {
      _ocultar = !_ocultar;
    });
  }

  void _login() async {
    var url = Uri.parse('http://192.168.1.14:8080/auth/login');
    var response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': _user.text, 'senha': _pass.text}),
    );

    if (response.statusCode == 200) {
      var responseData = json.decode(response.body);

      // Salve o token usando SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', responseData['token']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const MyHomePage(title: 'Logado')),
      );
    } else {
      // Mostre o diálogo de erro com o corpo da resposta HTTP
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
              TextField(
                controller: _user,
                decoration: const InputDecoration(labelText: 'Usuário'),
              ),
              TextField(
                controller: _pass,
                decoration: InputDecoration(
                    labelText: 'Senha',
                    suffixIcon: IconButton(
                        onPressed: _botaoPassVisibility,
                        icon: _ocultar ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                    )
                ),
                obscureText: _ocultar,
              ),
              const SizedBox(height: 20,),
              ElevatedButton(
                onPressed: _login,
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    textStyle: const TextStyle(color: Colors.black)
                ),
                child: const Text('Login'),
              )
            ],
          ),
        )
    );
  }
}