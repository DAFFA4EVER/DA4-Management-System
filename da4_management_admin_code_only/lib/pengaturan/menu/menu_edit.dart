import 'package:flutter/material.dart';
import '../../backend/pushDatabase.dart';
import '../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';

class MenuEditScreen extends StatefulWidget {
  final int idx;

  final List<Map<String, dynamic>> data;

  MenuEditScreen({
    required this.idx,
    required this.data,
  });

  @override
  State<MenuEditScreen> createState() => _MenuEditScreenState();
}

class _MenuEditScreenState extends State<MenuEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _beliController = TextEditingController();
  final TextEditingController _jualController = TextEditingController();
  List<String> typeMenuOptions = [
    'Fruit Tea',
    'Ice Cream',
    'Milk Tea',
    'Original Tea'
  ];
  bool _changesMade = false;
  bool dataLoaded = false;

  Map<String, dynamic> dataIDX = {};
  late final Map<String, dynamic> moduleSetting;

  @override
  void initState() {
    super.initState();
    dataIDX = widget.data[widget.idx];
    _nameController.text = dataIDX['name'];
    _typeController.text = dataIDX['type'];
    _beliController.text = dataIDX['beli'].toString();
    _jualController.text = dataIDX['jual'].toString();
    getModuleSetting();
  }

  void setUpModule() {
    typeMenuOptions = List<String>.from(moduleSetting['menu']);
    if (typeMenuOptions.any((element) => element == _typeController.text) ==
        false) {
      typeMenuOptions.add(_typeController.text);
    }
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
    _typeController.dispose();
    _beliController.dispose();
    _jualController.dispose();
    super.dispose();
  }

  bool validateInputs() {
    if (_nameController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _beliController.text.isEmpty ||
        _jualController.text.isEmpty) {
      return false; // At least one input field is empty
    }
    return true; // All input fields have values
  }

  void updateMenu() {
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

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text('Are you sure you want to save the changes?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Save'),
              onPressed: () {
                final updatedMenu = Menu(
                  id: dataIDX['id'],
                  name: _nameController.text,
                  type: _typeController.text,
                  beli: int.tryParse(_beliController.text) ?? 0,
                  jual: int.tryParse(_jualController.text) ?? 0,
                );

                widget.data[widget.idx] = updatedMenu.toMap();

                FirestoreUploader().uploadDataMenu(widget.data);

                Navigator.pop(context); // Close the confirmation dialog
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  void deleteMenu() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Delete Menu'),
          content: Text('Are you sure you want to delete this menu?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                widget.data.removeAt(widget.idx);
                FirestoreUploader().uploadDataMenu(widget.data);
                Navigator.pop(context);
                Navigator.pop(context);
                Navigator.pop(context);
              },
            ),
          ],
        );
      },
    );
  }

  Future<bool> _onWillPop() async {
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
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed: () {
                deleteMenu();
              },
              icon: Icon(Icons.delete),
            )
          ],
          title: Text('Edit Menu'),
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
                        value: _typeController.text,
                        items: typeMenuOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _typeController.text = value!;
                            _changesMade = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Tipe',
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
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
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
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
                        onPressed: _changesMade ? updateMenu : null,
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
  final String id;
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
