import 'package:flutter/material.dart';
import '../../backend/pushDatabase.dart';
import '../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';

class StockAddScreen extends StatefulWidget {
  final List<Map<String, dynamic>> data;

  StockAddScreen({
    required this.data,
  });

  @override
  State<StockAddScreen> createState() => _StockAddScreenState();
}

class _StockAddScreenState extends State<StockAddScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _typeController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _qtyController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  List<String> typeStockOptions = [
    'Bahan Baku Resep',
    'Alat Masak',
    'Alat Konsumsi'
  ];
  List<String> unitStockOptions = [
    'CTN',
    'PCS',
  ];
  bool _changesMade = false;
  String? _selectedType;
  String? _selectedUnit;
  List<Map<String, dynamic>> stocks = [];

  bool dataLoaded = false;
  Map<String, dynamic> moduleSetting = {};

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    typeStockOptions = List<String>.from(moduleSetting['barang']);
    unitStockOptions = List<String>.from(moduleSetting['unit']);
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
        _selectedType == null ||
        _priceController.text.isEmpty ||
        _qtyController.text.isEmpty ||
        _selectedUnit == null) {
      return false; // At least one input field is empty
    }
    return true; // All input fields have values
  }

  Future<int> getLastStockId() async {
    if (stocks.isNotEmpty) {
      final lastStock = stocks.last;
      return int.parse(lastStock['id']);
    } else {
      return 0; // If no stocks exist, start from 0
    }
  }

  Future<void> addStock() async {
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
    stocks = widget.data;

    final newStock = Stock.generateId(
      name: _nameController.text,
      type: _selectedType!,
      price: int.tryParse(_priceController.text) ?? 0,
      qty: int.tryParse(_qtyController.text) ?? 0,
      unit: _selectedUnit!,
    );

    final lastId = await getLastStockId();
    newStock.id = (lastId + 1).toString();

    stocks.add(newStock.toMap());
    FirestoreUploader().uploadDataStock(stocks);

    Navigator.pop(context);
    Navigator.pop(context);
  }

  Future<bool> _onWillPopAddStock() async {
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
      onWillPop: _onWillPopAddStock,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Add Stock'),
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
                        items: typeStockOptions.map((option) {
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
                        value: _selectedUnit,
                        items: unitStockOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedUnit = value!;
                            _changesMade = true;
                          });
                        },
                        decoration: InputDecoration(
                          labelText: 'Unit',
                        ),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _changesMade ? addStock : null,
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

class Stock {
  late String id;
  final String name;
  final String type;
  final int price;
  final int qty;
  final String unit;

  Stock({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.qty,
    required this.unit,
  });

  Stock.generateId({
    required this.name,
    required this.type,
    required this.price,
    required this.qty,
    required this.unit,
  }) : id = '';

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
