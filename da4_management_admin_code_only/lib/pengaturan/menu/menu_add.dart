import 'package:da4_management/backend/moduleDataHandler.dart';
import 'package:flutter/material.dart';
import '../../backend/pushDatabase.dart';
import '../list_menu_page.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MenuAddScreen extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  MenuAddScreen({
    required this.data,
  });

  @override
  State<MenuAddScreen> createState() => _MenuAddScreenState();
}

class _MenuAddScreenState extends State<MenuAddScreen> {
  String? _selectedType;
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _beliController = TextEditingController();
  final TextEditingController _jualController = TextEditingController();
  List<String> typeMenuOptions = [
    'Fruit Tea',
    'Ice Cream',
    'Milk Tea',
    'Original Tea'
  ];
  bool _changesMade = false;
  List<Map<String, dynamic>> menus = [];
  bool dataLoaded = false;
  Map<String, dynamic> moduleSetting = {};

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    typeMenuOptions = List<String>.from(moduleSetting['menu']);
    dataLoaded = true;
    setState(() {});
  }

  Future<void> getModuleSetting() async {
    if ((await ModuleHandler().checkModuleExist()) == true) {
      moduleSetting = await ModuleHandler().getModuleData();
    } else {
      await ModuleHandler().uploadModuleDataDefault();
      moduleSetting = await ModuleHandler().getModuleData();
    }
    setUpModule();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _beliController.dispose();
    _jualController.dispose();
    super.dispose();
  }

  Future<int> getLastMenuId() async {
    if (menus.isNotEmpty) {
      final lastMenu = menus.last;
      return int.parse(lastMenu['id']);
    } else {
      return 0; // If no menus exist, start from 0
    }
  }

  bool validateInputs() {
    if (_nameController.text.isEmpty ||
        _selectedType == null ||
        _beliController.text.isEmpty ||
        _jualController.text.isEmpty) {
      return false; // At least one input field is empty
    }
    return true; // All input fields have values
  }

  Future<void> addMenu() async {
    if (!validateInputs()) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Error'),
            content: Text('Please fill all the fields.'),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () {
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      );
      return;
    }

    menus = widget.data;

    final newMenu = Menu.generateId(
      name: _nameController.text,
      type: _selectedType!,
      beli: int.tryParse(_beliController.text) ?? 0,
      jual: int.tryParse(_jualController.text) ?? 0,
    );

    final lastId = await getLastMenuId();
    newMenu.id = (lastId + 1).toString();

    menus.add(newMenu.toMap());

    FirestoreUploader().uploadDataMenu(menus);

    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<bool> _onWillPopAddMenu() async {
    if (_changesMade) {
      final shouldDiscard = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Discard Changes?'),
            content: Text('Are you sure you want to discard your changes?'),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.pop(context, false);
                },
              ),
              TextButton(
                child: Text('Discard'),
                onPressed: () {
                  Navigator.pop(context, true);
                },
              ),
            ],
          );
        },
      );
      return shouldDiscard ?? false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPopAddMenu,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Tambah Menu'),
        ),
        body: (dataLoaded == false)
            ? Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(
                      height: 6,
                    ),
                    Text(
                      'Loading data',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _nameController,
                        onChanged: (value) {
                          setState(() {
                            _changesMade = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Nama',
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedType,
                        items: typeMenuOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedType = value!;
                            _changesMade = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Tipe',
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                        controller: _beliController,
                        onChanged: (value) {
                          setState(() {
                            _changesMade = true;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Beli',
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _jualController,
                        onChanged: (value) {
                          setState(() {
                            _changesMade = true;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga Jual',
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _changesMade ? addMenu : null,
                        child: Text('Save'),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}

class Menu {
  late String id;
  final String name;
  final String type;
  final int beli;
  final int jual;

  Menu({
    required this.id,
    required this.name,
    required this.type,
    required this.beli,
    required this.jual,
  });

  Menu.generateId({
    required this.name,
    required this.type,
    required this.beli,
    required this.jual,
  }) : id = '';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'beli': beli,
      'jual': jual,
    };
  }
}
