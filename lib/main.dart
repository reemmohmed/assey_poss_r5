import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:async';

void main() {
  runApp(MyApp());
}

class Employee {
  final int id;
  final String name;

  Employee({required this.id, required this.name});

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name};
  }
}

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper.internal();

  factory DatabaseHelper() => _instance;

  static Database? _db;

  DatabaseHelper.internal();

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await initDb();
    return _db!;
  }

  Future<Database> initDb() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, 'employees.db');

    // Delete the database
    await deleteDatabase(path);

    return await openDatabase(path, version: 1,
        onCreate: (Database db, int version) async {
      await db
          .execute('CREATE TABLE Employee(id INTEGER PRIMARY KEY, name TEXT)');
    });
  }

  Future<int> insertEmployee(Employee employee) async {
    var dbClient = await db;
    return await dbClient.insert('Employee', employee.toMap());
  }

  Future<List<Employee>> getEmployees() async {
    var dbClient = await db;
    List<Map> list = await dbClient.rawQuery('SELECT * FROM Employee');
    List<Employee> employees = [];
    for (int i = 0; i < list.length; i++) {
      employees.add(Employee(id: list[i]['id'], name: list[i]['name']));
    }
    return employees;
  }
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Employee Database',
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController _controller = TextEditingController();
  List<Employee> _employees = [];
  bool _isNameValid = true;

  @override
  void initState() {
    super.initState();
    _getEmployees();
  }

  _getEmployees() async {
    var dbHelper = DatabaseHelper();
    List<Employee> employees = await dbHelper.getEmployees();
    setState(() {
      _employees = employees;
    });
  }

  _addEmployee() async {
    if (_controller.text.isNotEmpty) {
      var dbHelper = DatabaseHelper();
      await dbHelper.insertEmployee(Employee(id: 0, name: _controller.text));
      _controller.clear();
      _getEmployees();
      setState(() {
        _isNameValid = true;
      });
    } else {
      setState(() {
        _isNameValid = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee Database'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                labelText: 'Employee Name',
                errorText: _isNameValid ? null : 'Please enter a valid name',
              ),
            ),
          ),
          ElevatedButton(
            onPressed: _addEmployee,
            child: Text('Add Employee'),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _employees.length,
              itemBuilder: (BuildContext context, int index) {
                return ListTile(
                  title: Text(_employees[index].name),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
