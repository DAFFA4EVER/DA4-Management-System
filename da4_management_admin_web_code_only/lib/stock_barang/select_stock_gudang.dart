import 'package:flutter/material.dart';
import '../backend/pullDatabase.dart';
import 'package:intl/intl.dart';
import 'temp_selection.dart';

class SelectStockGudangScreen extends StatefulWidget {
  @override
  _SelectStockGudangScreenState createState() =>
      _SelectStockGudangScreenState();
}

class Menu {
  final String id;
  final String name;
  final String type;
  final int price;
  final int qty;
  final String unit;
  final int quantity;
  bool isSelected;

  Menu({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.qty,
    required this.unit,
    required this.quantity,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nama': name,
      'type': type,
      'price': price,
      'qty': qty,
      'unit': unit,
      'quantity': quantity,
      'isSelected': isSelected,
    };
  }
}

class _SelectStockGudangScreenState extends State<SelectStockGudangScreen> {
  List<Menu> selectedStocks = []; // Initialize with an empty list
  List<Menu> menuList = [];
  List<Menu> filteredMenuList = [];
  List<Menu> searchedMenuList = [];
  String searchQuery = '';
  List<Map<String, dynamic>> stocks = [];

  @override
  void initState() {
    super.initState();
    loadMenuData();
    if (tempSelection.getData().isNotEmpty) {
      setState(() {
        selectedStocks = tempSelection
            .getData()
            .map((selectedItem) => Menu(
                  id: selectedItem['id'],
                  name: selectedItem['nama'],
                  type: selectedItem['type'],
                  price: selectedItem['price'],
                  qty: selectedItem['qty'],
                  unit: selectedItem['unit'],
                  quantity: selectedItem['quantity'],
                  isSelected: true,
                ))
            .toList();
      });
    } else {
      selectedStocks = [];
    }
  }

  Future<void> loadMenuData() async {
    stocks = await getStockData();
    setState(() {
      menuList = stocks
          .map((stockData) => Menu(
                id: stockData['id'] ?? '?',
                name: stockData['name'] ?? '?',
                type: stockData['type'],
                price: stockData['price'] ?? 0,
                qty: stockData['qty'] ?? 0,
                unit: stockData['unit'] ?? '?',
                quantity: stockData['quantity'] ?? 1,
                isSelected: selectedStocks
                    .any((selectedMenu) => selectedMenu.id == stockData['id']),
              ))
          .toList();
      filteredMenuList = menuList;
      searchedMenuList = menuList;
    });
  }

  void searchMenuList() {
    setState(() {
      if (searchQuery.isEmpty) {
        searchedMenuList = filteredMenuList;
      } else {
        searchedMenuList = filteredMenuList.where((menu) {
          return menu.name.toLowerCase().contains(searchQuery.toLowerCase());
        }).toList();
      }
    });
  }

  String formatPrice(int price) {
    var formatCurrency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
    String formattedPrice = formatCurrency.format(price);
    int decimalIndex = formattedPrice.indexOf(',');
    if (decimalIndex != -1) {
      formattedPrice = formattedPrice.substring(0, decimalIndex);
    }
    return formattedPrice;
  }

  void selectStock(Menu stock) async {
    final List<Menu> updatedSelection = List.from(selectedStocks);
    final int selectedIndex = updatedSelection
        .indexWhere((selectedStock) => selectedStock.id == stock.id);
    List<Map<String, dynamic>> selectedMasukItems = tempSelection.getData();

    if (stock.isSelected) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Confirmation'),
            content: Text('Are you sure you want to uncheck this item?'),
            actions: <Widget>[
              TextButton(
                child: Text('Cancel'),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              TextButton(
                child: Text('Uncheck'),
                onPressed: () async {
                  updatedSelection.removeAt(selectedIndex);
                  setState(() {
                    stock.isSelected = !stock.isSelected;
                    selectedStocks = updatedSelection;
                  });

                  if (selectedMasukItems.isNotEmpty) {
                    selectedMasukItems.removeWhere(
                        (selectedItem) => selectedItem['id'] == stock.id);
                    tempSelection.updateData(selectedMasukItems);
                  }

                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      updatedSelection.add(stock);
      setState(() {
        stock.isSelected = !stock.isSelected;
        selectedStocks = updatedSelection;
      });

      if (selectedMasukItems.isNotEmpty) {
        selectedMasukItems.add(stock.toMap());
      } else {
        selectedMasukItems = [stock.toMap()];
      }

      tempSelection.updateData(selectedMasukItems);
    }
  }

  bool isStockSelected(Menu stock) {
    return stock.isSelected;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pop(context);
        },
        child: Icon(Icons.add),
      ),
      appBar: AppBar(
        title: Text('Stock List'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                  searchMenuList();
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: searchedMenuList.length,
              itemBuilder: (context, index) {
                final stock = searchedMenuList[index];
                return InkWell(
                  onTap: () => selectStock(stock),
                  child: Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(
                        stock.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 4,
                          ),
                          Row(
                            children: [
                              Icon(
                                Icons.category,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text(
                                stock.type,
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.add_box,
                                size: 16,
                                color: Colors.grey[600],
                              ),
                              SizedBox(width: 4),
                              Text('QTY : ${stock.qty} (${stock.unit})'),
                            ],
                          ),
                        ],
                      ),
                      trailing: Checkbox(
                        value: isStockSelected(stock),
                        onChanged: (selected) => selectStock(stock),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
