import 'package:flutter/material.dart';
import '../backend/pullDatabase.dart';
import 'package:intl/intl.dart';

class SelectMenuScreen extends StatefulWidget {
  final List<Map<String, dynamic>> initialSelectedItems;
  final Function(List<Map<String, dynamic>> updatedSelection)?
      onSelectionChanged;



  SelectMenuScreen({
    required this.initialSelectedItems,
    this.onSelectionChanged,
  });

  @override
  _SelectMenuScreenState createState() => _SelectMenuScreenState();
}

class Menu {
  final String id;
  final String name;
  final String type;
  final int beli;
  final int jual;
  final int qty;
  bool isSelected;

  Menu({
    required this.id,
    required this.name,
    required this.type,
    required this.beli,
    required this.jual,
    required this.qty,
    this.isSelected = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'beli': beli,
      'jual': jual,
      'quantity': qty,
    };
  }
}

class _SelectMenuScreenState extends State<SelectMenuScreen> {
  List<Menu> menuList = [];
  List<Menu> filteredMenuList = [];
  List<Menu> searchedMenuList = [];
  List<Menu> selectedMenuList = [];
  String searchQuery = '';
  List<Map<String, dynamic>> menus = [];
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    loadMenuData();
    if (widget.initialSelectedItems != null) {
      setState(() {
        selectedMenuList = widget.initialSelectedItems
            .map((selectedItem) => Menu(
                  id: selectedItem['id'],
                  name: selectedItem['name'],
                  type: selectedItem['type'],
                  beli: selectedItem['beli'],
                  jual: selectedItem['jual'],
                  qty: selectedItem['quantity'],
                  isSelected: true,
                ))
            .toList();
        dataLoaded = true;
      });
    }
  }

  Future<void> loadMenuData() async {
    menus = await getMenuData();
    setState(() {
      menuList = menus
          .map((menuData) => Menu(
                id: menuData['id'],
                name: menuData['name'],
                type: menuData['type'],
                beli: menuData['beli'] ?? 0,
                jual: menuData['jual'] ?? 0,
                qty: menuData['quantity'] ?? 1,
                isSelected: selectedMenuList
                    .any((selectedMenu) => selectedMenu.id == menuData['id']),
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

  void selectMenu(Menu menu) {
    if (menu.isSelected) {
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
                onPressed: () {
                  setState(() {
                    menu.isSelected = !menu.isSelected;
                    selectedMenuList.removeWhere(
                        (selectedMenu) => selectedMenu.id == menu.id);
                  });
                  if (widget.onSelectionChanged != null) {
                    widget.onSelectionChanged!(
                        selectedMenuList.map((menu) => menu.toMap()).toList());
                  }
                  Navigator.of(context).pop();
                },
              ),
            ],
          );
        },
      );
    } else {
      setState(() {
        menu.isSelected = !menu.isSelected;
        selectedMenuList.add(menu);
      });
      if (widget.onSelectionChanged != null) {
        widget.onSelectionChanged!(
            selectedMenuList.map((menu) => menu.toMap()).toList());
      }
    }
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
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: searchedMenuList.length,
                      itemBuilder: (context, index) {
                        final menu = searchedMenuList[index];
                        return InkWell(
                          onTap: () => selectMenu(menu),
                          child: Card(
                            elevation: 2,
                            margin: const EdgeInsets.all(8.0),
                            child: ListTile(
                              title: Text(
                                menu.name,
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
                                        menu.type,
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
                                      Text('Harga : ${formatPrice(menu.jual)}'),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Checkbox(
                                value: menu.isSelected,
                                onChanged: (selected) => selectMenu(menu),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
