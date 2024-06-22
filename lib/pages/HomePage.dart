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
  final _numeroContaController = TextEditingController();
  final _valorDepositoController = TextEditingController();
  final _numeroContaDestinoController = TextEditingController();
  final _valorTransferenciaController = TextEditingController();

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

      if (response.statusCode == 200) {
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

  Future<void> _showDepositoModal() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Depósito'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Número da conta',
                ),
                controller: _numeroContaController,
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Valor do depósito',
                ),
                controller: _valorDepositoController,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Depositar'),
              onPressed: () async {
                // Chamar API para fazer depósito
                await _depositar();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showTransferenciaModal() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Transferência'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Número da conta de destino',
                ),
                controller: _numeroContaDestinoController,
              ),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Valor da transferência',
                ),
                controller: _valorTransferenciaController,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              child: Text('Cancelar'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Transferir'),
              onPressed: () async {
                // Chamar API para fazer transferência
                await _transferir();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _depositar() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email')?? '';
    String token = prefs.getString('token')?? '';

    var url = Uri.parse('http://192.168.1.14:8080/transacao/deposito');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var body = json.encode({
      "numeroConta": _numeroContaController.text,
      "valorDeposito": double.parse(_valorDepositoController.text),
      "tipoTransacao": "Deposito",
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Depósito realizado com sucesso!"),
            content: Text("Seu depósito foi realizado com sucesso."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {
        // Erro ao realizar depósito
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Erro ao realizar depósito"),
            content: Text("Erro: ${response.statusCode} - ${response.reasonPhrase}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Erro ao fazer requisição"),
          content: Text("Erro: $e"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        ),
      );
    }
  }

  Future<void> _transferir() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String email = prefs.getString('email')?? '';
    String token = prefs.getString('token')?? '';

    var url = Uri.parse('http://192.168.1.14:8080/transacao');
    var headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
    var body = json.encode({
      "emailContaBancaria": email,
      "numeroConta": _numeroContaDestinoController.text,
      "valorTransacao": double.parse(_valorTransferenciaController.text),
      "tipoTransacao": "transferencia",
    });

    try {
      var response = await http.post(url, headers: headers, body: body);

      if (response.statusCode == 200) {

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Transferência realizada com sucesso!"),
            content: Text("Sua transferência foi realizada com sucesso."),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      } else {

        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text("Erro ao realizar transferência"),
            content: Text("Erro: ${response.statusCode} - ${response.reasonPhrase}"),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text("OK"),
              ),
            ],
          ),
        );
      }
    } catch (e) {

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text("Erro ao fazer requisição"),
          content: Text("Erro: $e"),
          actions: [
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("OK"),
            ),
          ],
        ),
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
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _showDepositoModal();
              },
              child: Text("Depósito"),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                await _showTransferenciaModal();
              },
              child: Text("Transferência"),
            ),
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