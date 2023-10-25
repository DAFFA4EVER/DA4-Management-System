import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../backend/pullDatabase.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
    loadMenuData();
  }

  Future<void> loadMenuData() async {
    menus = await getMenuData();

    dataLoaded = true;
    available = true;
    setState(() {});
  }

  Future<void> saveDataAsJson() async {
    final jsonData = jsonEncode(menus);

    final directory = await getExternalStorageDirectory();
    final backupDirectory = Directory(
        '${directory!.path}/da4 backup/laporan/da4 backup/menu_mixue');

    if (!backupDirectory.existsSync()) {
      backupDirectory.createSync(recursive: true);
    }
    print(directory);
    final file = File('${backupDirectory.path}/menu_mixue_backup.json');

    await file.writeAsString(jsonData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved as JSON in da4 backup folder')),
    );
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
          title: const Text('Menu Data'),
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
