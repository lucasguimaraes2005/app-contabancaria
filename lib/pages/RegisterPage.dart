

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';




class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _nome = TextEditingController();
  final TextEditingController _sexo = TextEditingController();
  final TextEditingController _cpf = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _senha = TextEditingController();

  bool _ocultar = false;

  void _botaoPassVisibility() {
    setState(() {
      _ocultar = !_ocultar;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registro'),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TextField(
                controller: _nome,
                decoration: const InputDecoration(labelText: 'Nome'),
              ),
              TextField(
                controller: _sexo,
                decoration: const InputDecoration(labelText: 'Sexo'),
              ),
              TextField(
                controller: _cpf,
                decoration: const InputDecoration(labelText: 'CPF'),
              ),
              TextField(
                controller: _email,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              TextField(
                controller: _senha,
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
                onPressed: () {

                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent,
                    textStyle: const TextStyle(color: Colors.black)
                ),
                child: const Text('Registrar'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
