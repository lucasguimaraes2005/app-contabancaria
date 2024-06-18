import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _selectedIndex = 0;
  String _nomeUsuario = '';
  String _emailUsuario = '';
  bool _temContaBancaria = false;

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  void _buscarDadosUsuario() async {

    var url = Uri.parse('http://192.168.1.14:8080/user');
    var response = await http.get(url);

    if (response.statusCode == 200) {
      var dadosUsuario = json.decode(response.body);
      setState(() {
        _nomeUsuario = dadosUsuario['nome'];
        _emailUsuario = dadosUsuario['email'];
        _temContaBancaria = dadosUsuario['contasBancarias'].isNotEmpty;
      });
    } else {
      print('Falha ao buscar dados do usuário');
    }
  }

  static List<Widget> _widgetOptions(String nome, String email, bool temConta) => <Widget>[
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('Bem vindo! $nome', style: TextStyle(fontWeight: FontWeight.bold),),
        Text('O que temos para hoje?', style: TextStyle(fontWeight: FontWeight.bold),),
        Text('Informações da minha conta', style: TextStyle(fontWeight: FontWeight.bold),),
        Text('Email: $email', style: TextStyle(fontWeight: FontWeight.bold),),
        Text(temConta ? 'Você tem conta bancária e pode conferir informações dela na sessão "Minha conta"' : 'Você ainda não tem uma conta bancária! Crie uma na sessão "Minha conta"', style: TextStyle(fontWeight: FontWeight.bold),),
      ],
    ),
    Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text("teste")
      ],
    )
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: _widgetOptions(_nomeUsuario, _emailUsuario, _temContaBancaria).elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const [
          BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Home'
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.account_balance),
              label: 'Minha conta'
          )
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.greenAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}
