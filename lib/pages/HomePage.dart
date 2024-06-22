import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  late Future<void> _future;
  double _numeroConta = 0.0;
  double _saldoAtual = 0.0;
  List<dynamic> _ultimasTransacoes = [];

  @override
  void initState() {
    super.initState();
    _future = _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email')?? '';
    String token = prefs.getString('token')?? '';

    var url = Uri.parse('http://192.168.1.14:8080/user');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var body = '{"email": "$email"}';

    try {
      var request = http.Request('GET', url);
      request.headers.addAll(headers);
      request.bodyBytes = utf8.encode(body);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var dadosUsuario = json.decode(responseBody);
        setState(() {
          _nomeUsuario = dadosUsuario['nome'];
          _emailUsuario = dadosUsuario['email'];
          _temContaBancaria = dadosUsuario['contasBancarias'].isNotEmpty;
        });
      } else {
        print('Falha ao buscar dados do usuário');
      }
    } catch (e) {
      print('Erro ao fazer requisição: $e');
    }
  }

  Future<void> _buscarDadosContaBancaria() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email')?? '';
    String token = prefs.getString('token')?? '';

    var url = Uri.parse('http://192.168.1.14:8080/contabancaria/conta');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var body = '{"emailUsuario": "$email"}';

    try {
      var request = http.Request('GET', url);
      request.headers.addAll(headers);
      request.bodyBytes = utf8.encode(body);

      var response = await request.send();

      if (response.statusCode == 200) {
        var responseBody = await response.stream.bytesToString();
        var dadosConta = json.decode(responseBody);
        setState(() {
          _numeroConta = dadosConta['numeroConta'].toDouble();
          _saldoAtual = dadosConta['saldoAtual'] != null ? dadosConta['saldoAtual'].toDouble() : 0.0;
        });
      } else {
        print('Falha ao buscar dados da conta bancária');
      }
    } catch (e) {
      print('Erro ao fazer requisição: $e');
    }
  }

  Future<void> _buscarUltimasTransacoes() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email')?? '';
    String token = prefs.getString('token')?? '';

    var url = Uri.parse('http://192.168.1.14:8080/transacao?email=$email');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };

    try {
      var response = await http.get(url, headers: headers);

      if (response.statusCode == 200) {
        var responseBody = response.body;
        var transacoes = json.decode(responseBody);
        setState(() {
          _ultimasTransacoes = transacoes;
        });
      } else {
        print('Falha ao buscar últimas transações');
      }
    } catch (e) {
      print('Erro ao fazer requisição: $e');
    }
  }

  Future<void> _criarContaBancaria() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email')?? '';
    String token = prefs.getString('token')?? '';

    var url = Uri.parse('http://192.168.1.14:8080/contabancaria');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var body = '{"emailUsuario": "$email"}';

    try {
      var request = http.Request('POST', url);
      request.headers.addAll(headers);
      request.bodyBytes = utf8.encode(body);

      var response = await request.send();

      if (response.statusCode == 201) { // Note: changed to 201 (Created) instead of 200 (OK)
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Conta bancária criada com sucesso!'),
              content: Text('Sua conta bancária foi criada com sucesso.'),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
        // Recarregar dados da conta bancária
        await _buscarDadosContaBancaria();
        await _buscarUltimasTransacoes();
      } else {
        await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Erro ao criar conta bancária'),
              content: Text('Erro ao criar conta bancária. Tente novamente mais tarde.'),
              actions: <Widget>[
                ElevatedButton(
                  child: Text('OK'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            );
          },
        );
      }
    } catch (e) {
      await showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Erro ao fazer requisição'),
            content: Text('Erro ao fazer requisição: $e'),
            actions: <Widget>[
              ElevatedButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    }
  }

  List<Widget> _widgetOptions(String nome, String email, bool temConta) => <Widget>[
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Bem vindo! $nome', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),),
            SizedBox(height: 16),
            Text('O que temos para hoje?', style: TextStyle(fontSize: 18, fontWeight:           FontWeight.bold),),
            SizedBox(height: 16),
            Text('Informações da minha conta', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),),
            SizedBox(height: 16),
            Text('Email: $email', style: TextStyle(fontSize: 16),),
            SizedBox(height: 16),
            Text(temConta
                ? 'Você tem conta bancária e pode conferir informações dela na sessão "Minha conta"'
                : 'Você ainda não tem uma conta bancária! Crie uma na sessão "Minha conta"',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    ),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Minha conta"),
            SizedBox(height: 16),
            _temContaBancaria
                ? Column(
              children: [
                Text("Número da conta: $_numeroConta"),
                SizedBox(height: 16),
                Text("Saldo atual: R\$ $_saldoAtual"),
                SizedBox(height: 16),
                Text("Últimas transações:"),
                SizedBox(height: 16),
                ListView.builder(
                  shrinkWrap: true,
                  itemCount: _ultimasTransacoes.length,
                  itemBuilder: (context, index) {
                    return ListTile(
                      title: Text(_ultimasTransacoes[index]['descricao']),
                      subtitle: Text("R\$ ${_ultimasTransacoes[index]['valor']}"),
                    );
                  },
                ),
              ],
            )
                : ElevatedButton(
              onPressed: () async {
                // Criar conta bancária
                await _criarContaBancaria();
                // Recarregar dados da conta bancária
                await _buscarDadosContaBancaria();
                await _buscarUltimasTransacoes();
              },
              child: Text("Criar conta"),
            ),
          ],
        ),
      ),
    ),
    Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text("Tela de transações"),
          ],
        ),
      ),
    )
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    if (index == 1) {
      _buscarDadosContaBancaria();
      _buscarUltimasTransacoes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: FutureBuilder(
          future: _future?? Future.value(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.done) {
              return _widgetOptions(_nomeUsuario, _emailUsuario, _temContaBancaria).elementAt(_selectedIndex);
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
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
          ),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt),
              label: 'Transações'
          )
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.greenAccent,
        onTap: _onItemTapped,
      ),
    );
  }
}