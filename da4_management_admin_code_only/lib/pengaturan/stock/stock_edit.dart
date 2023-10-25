import 'package:flutter/material.dart';
import '../../backend/pushDatabase.dart';
import '../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';

class StockEditScreen extends StatefulWidget {
  final int idx;

  final List<Map<String, dynamic>> data;

  StockEditScreen({
    required this.idx,
    required this.data,
  });
  @override
  State<StockEditScreen> createState() => _StockEditScreenState();
}

class _StockEditScreenState extends State<StockEditScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  List<String> typeStockOptions = [
    'Bahan Baku Resep',
    'Alat Masak',
    'Alat Konsumsi',
  ];
  List<String> unitStockOptions = [
    'CTN',
    'PCS',
  ];
  bool _changesMade = false;

  Map<String, dynamic> dataIDX = {};

  @override
  void initState() {
    super.initState();
    dataIDX = widget.data[widget.idx];
    _nameController.text = dataIDX['name'];
    _typeController.text = dataIDX['type'];
    _priceController.text = dataIDX['price'].toString();
    _qtyController.text = dataIDX['qty'].toString();
    _unitController.text = dataIDX['unit'];
    getModuleSetting();
  }

  bool dataLoaded = false;
  Map<String, dynamic> moduleSetting = {};

  void setUpModule() {
    typeStockOptions = List<String>.from(moduleSetting['barang']);
    unitStockOptions = List<String>.from(moduleSetting['unit']);
    if (typeStockOptions.any((element) => element == _typeController.text) ==
        false) {
      typeStockOptions.add(_typeController.text);
    }
    if (unitStockOptions.any((element) => element == _unitController.text) ==
        false) {
      unitStockOptions.add(_unitController.text);
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
    _priceController.dispose();
    _qtyController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  bool validateInputs() {
    if (_nameController.text.isEmpty ||
        _typeController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _unitController.text.isEmpty) {
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
                  price: int.tryParse(_priceController.text) ?? 0,
                  qty: int.tryParse(_qtyController.text) ?? 0,
                  unit: _unitController.text,
                );

                widget.data[widget.idx] = updatedMenu.toMap();

                FirestoreUploader().uploadDataStock(widget.data);

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
                FirestoreUploader().uploadDataStock(widget.data);
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
          title: Text('Edit Stock'),
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
                        items: typeStockOptions.map((option) {
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
                        controller: _priceController,
                        onChanged: (value) {
                          setState(() {
                            _changesMade = true;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Harga',
                        ),
                      ),
                      SizedBox(height: 16),
                      TextField(
                        controller: _qtyController,
                        onChanged: (value) {
                          setState(() {
                            _changesMade = true;
                          });
                        },
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'QTY',
                        ),
                      ),
                      SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _unitController.text,
                        items: unitStockOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _unitController.text = value!;
                            _changesMade = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Unit',
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
  final String unit;
  final int price;
  final int qty;

  Menu({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.qty,
    required this.unit,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      'qty': qty,
      'unit': unit,
    };
  }
}
