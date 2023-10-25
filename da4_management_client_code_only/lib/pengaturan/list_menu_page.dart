import 'package:flutter/material.dart';
import '../backend/pullDatabase.dart';
import '../backend/moduleDataHandler.dart';
import 'package:intl/intl.dart';

class ListMenuScreen extends StatefulWidget {
  @override
  State<ListMenuScreen> createState() => _ListMenuScreenState();
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
}

class _ListMenuScreenState extends State<ListMenuScreen> {
  List<Menu> menuList = [];
  List<Menu> filteredMenuList = [];
  List<Menu> searchedMenuList = [];
  String selectedFilterOption = 'All';
  String searchQuery = '';
  List<Map<String, dynamic>> menus = [];
  bool dataLoaded = false;
  List<String> filterMenuOptions = [
    'All',
    'Fruit Tea',
    'Ice Cream',
    'Milk Tea',
    'Original Tea'
  ];

  @override
  void initState() {
    super.initState();
    loadMenuData();
    getModuleSetting();
  }

  Map<String, dynamic> moduleSetting = {};

  void setUpModule() {
    filterMenuOptions = List<String>.from(moduleSetting['menu']);
    filterMenuOptions.add("All");
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
    menus = await getMenuData();
    setState(() {
      menuList = menus
          .map((menuData) => Menu(
                id: menuData['id'],
                name: menuData['name'],
                type: menuData['type'],
                beli: menuData['beli'],
                jual: menuData['jual'],
              ))
          .toList();
      filteredMenuList = menuList;
      searchedMenuList = menuList;
      dataLoaded = true;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu List'),
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
                        onChanged: filterMenuList,
                        items: filterMenuOptions.map((option) {
                          return DropdownMenuItem<String>(
                            value: option,
                            child: Text(option),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: searchedMenuList.length,
                    itemBuilder: (context, index) {
                      final menu = searchedMenuList[index];
                       if (filterMenuOptions
                              .any((element) => element == menu.type) ==
                          false) {
                        filterMenuOptions.add(menu.type);
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
                                    Icons.shopping_cart,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text('Beli : ${formatPrice(menu.beli)}'),
                                  SizedBox(width: 16),
                                  Icon(
                                    Icons.attach_money,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 4),
                                  Text('Jual : ${formatPrice(menu.jual)}'),
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

class MenuService {
  static Future<void> reload() async {}
}
