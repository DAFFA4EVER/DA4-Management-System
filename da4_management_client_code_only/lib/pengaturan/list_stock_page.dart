import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/pullDatabase.dart';
import '../backend/moduleDataHandler.dart';

class ListStockScreen extends StatefulWidget {
  @override
  State<ListStockScreen> createState() => _ListStockScreenState();
}

class Menu {
  final String id;
  final String name;
  final String type;
  final int price;
  final int qty;
  final String unit;

  Menu({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.qty,
    required this.unit,
  });
}

class _ListStockScreenState extends State<ListStockScreen> {
  List<Menu> menuList = [];
  List<Menu> filteredMenuList = [];
  List<Menu> searchedMenuList = [];
  String searchQuery = '';
  String selectedFilterOption = 'All';
  List<Map<String, dynamic>> stocks = [];
  bool dataLoaded = false;
  List<String> filterStockOptions = [
    'All',
    'Bahan Baku Resep',
    'Alat Masak',
    'Alat Konsumsi',
  ];

  @override
  void initState() {
    super.initState();
    loadMenuData();
    getModuleSetting();
  }

  Map<String, dynamic> moduleSetting = {};

  void setUpModule() {
    filterStockOptions = List<String>.from(moduleSetting['barang']);
    filterStockOptions.add("All");
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

  Future<void> loadMenuData() async {
    stocks = await getStockData();
    setState(() {
      menuList = stocks
          .map((menuData) => Menu(
                id: menuData['id'],
                name: menuData['name'],
                type: menuData['type'],
                price: menuData['price'],
                qty: menuData['qty'],
                unit: menuData['unit'],
              ))
          .toList();
      filteredMenuList = menuList;
      searchedMenuList = menuList;
      dataLoaded = true;
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

  void filterMenuList(String? filterOption) {
    setState(() {
      selectedFilterOption = filterOption ?? 'All';
      if (selectedFilterOption == 'All') {
        filteredMenuList = menuList;
      } else {
        filteredMenuList = menuList.where((menu) {
          return menu.type == selectedFilterOption;
        }).toList();
      }
      searchMenuList();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Stock List'),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
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
                            contentPadding: EdgeInsets.symmetric(
                                vertical: 12.0, horizontal: 16.0),
                          ),
                        ),
                      ),
                      SizedBox(width: 10),
                      DropdownButton<String>(
                        value: selectedFilterOption,
                        items: filterStockOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (value) {
                          filterMenuList(value);
                        },
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchedMenuList.length,
                    itemBuilder: (context, index) {
                      final menu = searchedMenuList[index];
                      if (filterStockOptions
                              .any((element) => element == menu.type) ==
                          false) {
                        filterStockOptions.add(menu.type);
                      }
                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Text(
                                menu.name,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.category,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    menu.type,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 8.0),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text('Harga : ${formatPrice(menu.price)}'),
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.add_box,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text('QTY : ${menu.qty} (${menu.unit})'),
                                ],
                              ),
                            ),
                            SizedBox(
                              height: 8,
                            ),
                          ],
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
