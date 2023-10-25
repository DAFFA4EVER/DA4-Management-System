import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/pullDatabase.dart';
import 'dart:convert';
import 'dart:html' as html;

class ListStockScreen extends StatefulWidget {
  @override
  State<ListStockScreen> createState() => _ListStockScreenState();
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

class _ListStockScreenState extends State<ListStockScreen> {
  List<Menu> menuList = [];
  List<Menu> filteredMenuList = [];
  List<Menu> searchedMenuList = [];
  String selectedFilterOption = 'All';
  String searchQuery = '';
  List<Map<String, dynamic>> menus = [];
  bool dataLoaded = false;
  bool available = false;
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
    loadStockData();
  }

  Future<void> loadStockData() async {
    menus = await getStockData();

    dataLoaded = true;
    available = true;
    setState(() {});
  }

  Future<void> saveDataAsJson() async {
    final jsonData = jsonEncode(menus);

    final blob = html.Blob([jsonData]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: blobUrl)
      ..target = 'blank'
      ..download = 'stock_mixue_backup.json'
      ..click();

    html.Url.revokeObjectUrl(blobUrl);

    // Show a message to the user
    html.window.alert('Report data as JSON has been downloaded');
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: const Text('Konfirmasi'),
              content: const Text('Anda yakin ingin keluar?'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text('Tidak'),
                ),
                TextButton(
                  onPressed: () {
                    // Save the updated data
                    Navigator.pop(context);
                    Navigator.pop(context); // Close the dialog
                    // Code to be executed after the delay
                  },
                  child: const Text('Ya'),
                ),
              ],
            );
          },
        );
        // Save the data before popping the route
        return true;
      },
      child: Scaffold(
        floatingActionButton: (dataLoaded == true)
            ? FloatingActionButton(
                onPressed: () {
                  saveDataAsJson();
                },
                child: Icon(Icons.download))
            : SizedBox.shrink(),
        appBar: AppBar(
          actions: [
            (dataLoaded == true)
                ? IconButton(
                    icon: Icon(Icons.copy),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: jsonEncode(menus)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  )
                : SizedBox.shrink(),
          ],
          title: const Text('Stock Data'),
        ),
        body: (dataLoaded == false && available == false)
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
            : ((available == false))
                ? Center(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          height: 6,
                        ),
                        Text(
                          'Data tidak tersedia',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                  )
                : ListView(children: [
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.black,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(jsonEncode(menus),
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ]),
      ),
    );
  }
}
