import 'dart:async';
import 'package:da4_management_client/backend/control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/moduleDataHandler.dart';
//import 'select_menu_page.dart' as SelectMenu;
import 'select_stock_page.dart' as SelectStock;
import '../backend/pullDatabase.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../backend/buktiDataHandlerAndroid.dart';

class LaporanTodayPointScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;

  LaporanTodayPointScreen({required this.currentdate, required this.edit});

  @override
  _LaporanTodayPointScreenState createState() => _LaporanTodayPointScreenState();
}

class _LaporanTodayPointScreenState extends State<LaporanTodayPointScreen> {
  String selectedFilter = 'semua';
  String searchQuery = '';
  TextEditingController searchController = TextEditingController(text: '');
  List<int> searchResult = [];
  final rupiahController = TextEditingController();
  int ongoingCount = 0;
  int selesaiCount = 0;
  int cancelCount = 0;
  List<Map<String, dynamic>> pembayaranItems = [];
  List<Map<String, dynamic>> pengeluaranItems = [];
  List<Map<String, dynamic>> strukItems = [];
  List<Map<String, dynamic>> absenItems = [];
  List<Map<String, dynamic>> selectedMenuItems = [];
  List<Map<String, dynamic>> selectedStockItems = [];
  final laporanHelper = LaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> laporanData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  int totalPendapatan = 0;
  String previousDate = '';
  DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  bool dataLoaded = false;
  bool detailPembayaran = false;
  bool imageAvailable = false;

  List<String> jenisPembayaranList = [
    'Grab',
    'Gojek',
    'QRIS',
    'OVO',
    'GoPay',
    'Card',
    'Lainnya',
  ];

  List<String> pengeluaranJenis = [
    'Listrik',
    'Gaji',
    'ATK',
    'Bahan Baku Tambahan',
    'Service',
    'Peralatan',
    'Rumah Tangga',
    'Entertainment',
    'Promosi',
    'Transportasi',
    'Admin Grab',
    'Admin Gojek',
    'Admin Bank',
    'Admin Lainnya',
    'Penyusutan',
    'Beban Ongkos Kirim',
    'Beban Produksi',
    'Lainnya',
  ];

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    if (widget.currentdate == '') {
      currentDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      currentDate = widget.currentdate;
    }
    canEdit = widget.edit;
    checkLaporanExist();
  }

  Future<bool> pickImage(int index, String method) async {
    try {
      var pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return false;

      final imageName = pickedImage.name;
      final imageFile = File(pickedImage.path);
      final firestorageURL = await BuktiDataHandlerAndroid.instance
          .uploadImageURL(imageFile, currentDate);
      if (method == 'struk') {
        setState(() {
          strukItems[index]['photo'] = pickedImage!.path;
          strukItems[index]['imageName'] = imageName;
          strukItems[index]['firestorage'] = firestorageURL;
        });
      } else if (method == 'pemasukan') {
        setState(() {
          pembayaranItems[index]['photo'] = pickedImage!.path;
          pembayaranItems[index]['imageName'] = imageName;
          pembayaranItems[index]['firestorage'] = firestorageURL;
        });
      } else {
        setState(() {
          pengeluaranItems[index]['photo'] = pickedImage!.path;
          pengeluaranItems[index]['imageName'] = imageName;
          pengeluaranItems[index]['firestorage'] = firestorageURL;
        });
      }
      laporanHelper.saveLaporanToFirestore(laporanData, currentDate);
    } on PlatformException catch (e) {
      print('Error picking image: $e');
    }
    return true;
  }

  Map<String, dynamic> moduleSetting = {};

  void setUpModule() {
    pengeluaranJenis = List<String>.from(moduleSetting['pengeluaran']);
    jenisPembayaranList = List<String>.from(moduleSetting['pemasukkan']);
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

  String? imagePath;
  String? imageName;

  Future<String> getPreviousStock() async {
    List<String> availableDate = [];
    final gudangList =
        await LaporanDatabaseHandlerFirestore.instance.getLaporanList();

    for (final item in gudangList) {
      String selectedDate = item.substring(
        item.lastIndexOf("_") + 1,
      );
      availableDate.add(selectedDate);
    }
    if (currentDate == availableDate.last) {
      if (availableDate.length > 1) {
        return availableDate[availableDate.length - 2];
      } else {
        return availableDate[0];
      }
    } else {
      if (availableDate.contains(currentDate) == false) {
        return availableDate.last;
      } else {
        return DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(currentDate).subtract(Duration(days: 1)))
            .toString();
      }
    }
  }

  void navigateToSelectStockScreen() async {
    if (canEdit) {
      final selected = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => SelectStock.SelectStockScreen(
            initialSelectedItems: selectedStockItems,
            onSelectionChanged: (updatedSelection) {
              setState(() {
                selectedStockItems = updatedSelection;
                updateLaporanData();
              });
            },
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          selectedStockItems = selected;
          updateLaporanData();
        });
      }
    }
  }

  Future<void> checkLaporanExist() async {
    try {
      print('a');
      if (await laporanHelper.checkLaporanExist(currentDate) == false) {
        laporanData = laporanHelper.laporanTemplate(currentDate);
      } else {
        laporanData = await laporanHelper.loadLaporanFromFirestore(currentDate);
      }
      print('b');
      previousDate = await getPreviousStock();
      print('c');

      if ((await laporanHelper.checkLaporanExist(previousDate) == true) &&
          (laporanData['uploaded'] == false)) {
        if (canEdit) {
          print('Today Not Exist');
          Map<String, dynamic> laporanTokoYesterdayData =
              await laporanHelper.loadLaporanFromFirestore(previousDate);
          selectedStockItems = List<Map<String, dynamic>>.from(
              laporanTokoYesterdayData['stokToko']);
        }
      } else {
        print('Today Exist');
        selectedStockItems =
            List<Map<String, dynamic>>.from(laporanData['stokToko']);
      }

      final listDoneMenuItems =
          List<Map<String, dynamic>>.from(laporanData['menu']);
      final menus = await getMenuData();

      if (laporanData['imageData'] == null) {
        laporanData['imageData'] = true;
      }

      imageAvailable = laporanData['imageData'];

      pembayaranItems =
          List<Map<String, dynamic>>.from(laporanData['pemasukan external']);
      for (final bayarItem in pembayaranItems) {
        totalPendapatan += bayarItem['jumlah'] as int;
        if (bayarItem['status'] == 'ongoing') {
          ongoingCount += 1;
        } else if (bayarItem['status'] == 'selesai') {
          selesaiCount += 1;
        } else if (bayarItem['status'] == 'cancel') {
          cancelCount += 1;
        }
      }
      // HEHEHEHE
      if (listDoneMenuItems.isNotEmpty && pembayaranItems.isNotEmpty) {
        for (int y = 0; y < listDoneMenuItems.length; y++) {
          if (y == 0) {
            for (int p = 0; p < menus.length; p++) {
              menus[p]['quantity'] = 0;
            }
          }
          final int t = menus.indexWhere(
              (element) => (element['id'] == listDoneMenuItems[y]['id']));

          final int x = pembayaranItems.indexWhere(
              (element) => element['order'] == listDoneMenuItems[y]['order']);

          if (pembayaranItems[x]['status'] != 'cancel') {
            menus[t]['quantity'] += listDoneMenuItems[y]['quantity'];
          }
        }
      }

      // HEHEHEHE
      selectedMenuItems = menus;
      //
      if (laporanData['uploaded'] == true) {
        canEdit = false;
      }
      getModuleSetting();
      dataLoaded = true;
    } catch (e) {
      print(e);
    }

    if (laporanData['namaToko'] == null) {
      laporanData['namaToko'] = TokoID.tokoName;
      laporanData['date'] = currentDate;
      laporanData['cash'] = 0;
    }
    searchResult = List.generate(pembayaranItems.length, (index) => index);
    setState(() {
      tokoNama = laporanData['namaToko'];
      tanggal = laporanData['date'];

      pengeluaranItems =
          List<Map<String, dynamic>>.from(laporanData['pengeluaran']);

      absenItems = List<Map<String, dynamic>>.from(laporanData['absen']);
      strukItems = List<Map<String, dynamic>>.from(laporanData['struk']);
    });
  }

  bool checkEmptyField() {
    if (absenItems == []) {
      kosongMessage = 'Data absen belum lengkap';
      return true;
    }
    if (selectedMenuItems.isEmpty) {
      kosongMessage = 'Data menu belum lengkap';
      return true;
    }
    if (selectedStockItems.isEmpty) {
      kosongMessage = 'Data stok belum lengkap';
      return true;
    }

    if (pengeluaranItems
        .any((item) => item['photo'] == '' || item['imageName'] == '')) {
      kosongMessage = 'Data pengeluaran belum lengkap';
      return true;
    }

    if (pembayaranItems
        .any((item) => item['photo'] == '' || item['imageName'] == '')) {
      kosongMessage = 'Data pemasukan belum lengkap';
      return true;
    }
    //

    if (pengeluaranItems
        .any((item) => item['jumlah'] == null || item['nama'] == '')) {
      kosongMessage = 'Data pengeluaran belum lengkap';
      return true;
    }

    if (pembayaranItems
        .any((item) => item['jumlah'] == null || item['nama'] == '')) {
      kosongMessage = 'Data pemasukan belum lengkap';
      return true;
    }

    //
    if (selectedMenuItems.any((item) => item['quantity'] == 0)) {
      kosongMessage = 'Data menu belum lengkap';
      return true;
    }

    return false;
  }

  void updateLaporanData() {
    if (canEdit) {
      // Stock
      for (final selectedItem in selectedStockItems) {
        final String itemName = selectedItem['name'];
        final existingItemIndex = laporanData['stokToko'].indexWhere(
          (item) => item['name'] == itemName,
        );
        if (existingItemIndex != -1) {
          laporanData['stokToko'][existingItemIndex]['quantity'] =
              selectedItem['quantity'];
        } else {
          laporanData['stokToko'].add(selectedItem);
        }
      }

      // Date
      laporanData['date'] = currentDate;
      // Cash
      laporanData['cash'] = totalPendapatan;
      // Pengeluaran
      laporanData['pengeluaran'] = pengeluaranItems;
      // pemasukan
      laporanData['pemasukan external'] = pembayaranItems;
      // struk
      laporanData['struk'] = strukItems;

      laporanHelper.saveLaporanToFirestore(laporanData, currentDate);
    }
  }

  void searchDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: const Text('Pencarian'),
              content: Container(
                width: MediaQuery.of(context).size.width * 0.8,
                height: MediaQuery.of(context).size.height * 0.25,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    TextField(
                      controller: searchController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(labelText: 'Code Pesanan'),
                    ),
                    SizedBox(
                      height: 16,
                    ),
                    Text(
                      'Filter',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'semua';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'semua'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Semua',
                            style: TextStyle(
                                color: (selectedFilter == 'semua')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'ongoing';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'ongoing'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Ongoing',
                            style: TextStyle(
                                color: (selectedFilter == 'ongoing')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'selesai';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'selesai'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Selesai',
                            style: TextStyle(
                                color: (selectedFilter == 'selesai')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              selectedFilter = 'cancel';
                            });
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith(
                                (states) => selectedFilter == 'cancel'
                                    ? Colors.white
                                    : null),
                          ),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                                color: (selectedFilter == 'cancel')
                                    ? Colors.black
                                    : Colors.blue),
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () async {
                    searchProcess();
                    Navigator.pop(context); // Close the dialog
                    setState(() {});
                  },
                  child: const Text('Cari'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void searchProcess() async {
    dataLoaded = false;
    searchQuery = searchController.text;
    if (selectedFilter == 'semua' && searchQuery != '') {
      searchResult = [];
      for (int i = 0; i < pembayaranItems.length; i++) {
        if (pembayaranItems[i]['order']
            .substring(pembayaranItems[i]['order'].length - 4,
                pembayaranItems[i]['order'].length)
            .contains(searchQuery)) {
          searchResult.add(i);
        }
      }
    } else if (selectedFilter != 'semua' && searchQuery == '') {
      searchResult = [];
      for (int i = 0; i < pembayaranItems.length; i++) {
        if ((pembayaranItems[i]['status']).contains(selectedFilter)) {
          searchResult.add(i);
        }
      }
    } else if (selectedFilter != 'semua' && searchQuery != '') {
      searchResult = [];
      for (int i = 0; i < pembayaranItems.length; i++) {
        if ((pembayaranItems[i]['status']).contains(selectedFilter)) {
          if (pembayaranItems[i]['order']
              .substring(pembayaranItems[i]['order'].length - 4,
                  pembayaranItems[i]['order'].length)
              .contains(searchQuery)) {
            searchResult.add(i);
          }
        }
      }
    } else {
      searchResult = List.generate(pembayaranItems.length, (index) => index);
    }

    dataLoaded = true;
    setState(() {});
  }

  void showPesananList(BuildContext context, String orderName,
      List<Map<String, dynamic>> pesananOrder) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          // Content of the bottom sheet
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  margin: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        "Order Code",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        orderName,
                        style: TextStyle(
                          fontSize: 16,
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      ListView.builder(
                          shrinkWrap: true,
                          itemCount: pesananOrder.length,
                          itemBuilder: (context, index) {
                            String menuName = pesananOrder[index]['name'];
                            int menuHarga = pesananOrder[index]['jual'];
                            int jumlah = pesananOrder[index]['quantity'];

                            String status = pesananOrder[index]['status'];

                            status = status.substring(0, 1).toUpperCase() +
                                status.substring(1);

                            return Container(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          menuName,
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(formatPrice(menuHarga)),
                                      ],
                                    ),
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(right: 8.0),
                                      child: Text(
                                        jumlah.toString(),
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          })
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (checkEmptyField()) {
          if (canEdit && dataLoaded) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Masih Kosong'),
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
          }
        } else {
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
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Hari Ini'),
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
            : Stack(
                children: [
                  Scrollbar(
                    child: ListView(
                      children: [
                        // Tanggal
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: ListTile(
                            title: const Text(
                              'Tanggal',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              tanggal,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        // Toko Nama
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: ListTile(
                            title: const Text(
                              'Toko',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              tokoNama,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        // Menu Terjual
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Menu Terjual',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedMenuItems.length,
                                itemBuilder: (context, index) {
                                  final menu = selectedMenuItems[index];
                                  final quantity = menu['quantity'] ?? 0;
                                  return Card(
                                    child: ListTile(
                                      title: Text(menu['name']),
                                      subtitle: Text(formatPrice(menu['jual'])),
                                      trailing: SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          initialValue: '$quantity',
                                          enabled: false,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.all(8),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              menu['quantity'] =
                                                  int.tryParse(value) ?? 0;
                                              updateLaporanData();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Jenis Pembayaran
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'Daftar Penjualan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Pendapatan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(formatPrice(totalPendapatan)),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Total Pesanan',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text((ongoingCount +
                                            selesaiCount +
                                            cancelCount)
                                        .toString()),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Ongoing',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(ongoingCount.toString()),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                    left: 16, right: 16, top: 16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Selesai',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(selesaiCount.toString()),
                                  ],
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: 16,
                                  right: 16,
                                  top: 16,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Cancel',
                                      style: TextStyle(
                                          fontWeight: FontWeight.bold),
                                    ),
                                    Text(cancelCount.toString()),
                                  ],
                                ),
                              ),
                              Padding(
                                  padding: const EdgeInsets.only(
                                      left: 16, right: 16, top: 16),
                                  child: IconButton(
                                      onPressed: () {
                                        showModalBottomSheet(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return Container(
                                                width: MediaQuery.of(context)
                                                        .size
                                                        .width *
                                                    0.9,
                                                // Content of the bottom sheet
                                                child: const Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    mainAxisSize:
                                                        MainAxisSize.min,
                                                    children: [
                                                      Center(
                                                        child: Padding(
                                                            padding:
                                                                EdgeInsets.only(
                                                                    left: 16,
                                                                    right: 16,
                                                                    top: 16),
                                                            child: Text(
                                                              'Keterangan',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 18),
                                                            )),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 16,
                                                                right: 16,
                                                                top: 16),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Total Pendapatan',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            Text(
                                                                'Termasuk pesanan yang di cancel'),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 16,
                                                                right: 16,
                                                                top: 16),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                              'Total Pesanan',
                                                              style: TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            ),
                                                            Text(
                                                                'Termasuk pesanan yang di cancel'),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 16,
                                                                right: 16,
                                                                top: 16),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Ongoing',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                Text(
                                                                    'Pesanan masih diproses'),
                                                              ],
                                                            ),
                                                            Icon(Icons.restore),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                                left: 16,
                                                                right: 16,
                                                                top: 16),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Selesai',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                Text(
                                                                    'Pesanan telah selesai'),
                                                              ],
                                                            ),
                                                            Icon(Icons.done),
                                                          ],
                                                        ),
                                                      ),
                                                      Padding(
                                                        padding:
                                                            EdgeInsets.only(
                                                          left: 16,
                                                          right: 16,
                                                          top: 16,
                                                        ),
                                                        child: Row(
                                                          mainAxisAlignment:
                                                              MainAxisAlignment
                                                                  .spaceBetween,
                                                          children: [
                                                            Column(
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Text(
                                                                  'Cancel',
                                                                  style: TextStyle(
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold),
                                                                ),
                                                                Text(
                                                                    'Pesanan dibatalkan'),
                                                              ],
                                                            ),
                                                            Icon(Icons
                                                                .cancel_outlined),
                                                          ],
                                                        ),
                                                      ),
                                                      SizedBox(
                                                        height: 16,
                                                      ),
                                                    ]),
                                              );
                                            });
                                      },
                                      icon: const Icon(Icons.info_outline))),
                              (detailPembayaran == true)
                                  ? Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                            onPressed: () {
                                              searchDialog();
                                            },
                                            icon: Icon(Icons.search)),
                                        Card(
                                          elevation: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                                borderRadius:
                                                    BorderRadius.circular(16)),
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .height *
                                                0.25,
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(16.0),
                                              child: Scrollbar(
                                                child: (searchResult.isNotEmpty)
                                                    ? ListView.builder(
                                                        //shrinkWrap: true,
                                                        //physics:
                                                        //    const NeverScrollableScrollPhysics(),
                                                        itemCount:
                                                            pembayaranItems
                                                                .length,
                                                        itemBuilder:
                                                            (context, index) {
                                                          final pemasukan =
                                                              pembayaranItems[
                                                                      index] ??
                                                                  {}; // Initialize with an empty map if null

                                                          final List<
                                                              Map<String,
                                                                  dynamic>> pesanan = List<
                                                                      Map<String,
                                                                          dynamic>>.from(
                                                                  laporanData[
                                                                      'menu'])
                                                              .where((element) =>
                                                                  element[
                                                                      'order'] ==
                                                                  pembayaranItems[
                                                                          index]
                                                                      ['order'])
                                                              .toList();

                                                          if (searchResult
                                                              .contains(
                                                                  index)) {
                                                            return Container(
                                                              margin: EdgeInsets
                                                                  .only(
                                                                      top: 8,
                                                                      bottom:
                                                                          8),
                                                              child: Column(
                                                                children: [
                                                                  Row(
                                                                    mainAxisAlignment:
                                                                        MainAxisAlignment
                                                                            .spaceAround,
                                                                    children: [
                                                                      if (pemasukan[
                                                                              'status'] ==
                                                                          'ongoing')
                                                                        const Padding(
                                                                          padding:
                                                                              EdgeInsets.all(8.0),
                                                                          child:
                                                                              Icon(Icons.restore_outlined),
                                                                        )
                                                                      else if (pemasukan[
                                                                              'status'] ==
                                                                          'selesai')
                                                                        const Padding(
                                                                            padding:
                                                                                EdgeInsets.all(8.0),
                                                                            child: Icon(Icons.done))
                                                                      else
                                                                        const Padding(
                                                                          padding:
                                                                              EdgeInsets.all(8.0),
                                                                          child:
                                                                              Icon(Icons.cancel_outlined),
                                                                        ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(8.0),
                                                                        child:
                                                                            Text(
                                                                          pemasukan['order'].substring(pemasukan['order'].length -
                                                                              4),
                                                                          style: TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 18),
                                                                        ),
                                                                      ),
                                                                      Padding(
                                                                        padding:
                                                                            const EdgeInsets.all(8.0),
                                                                        child: Text(
                                                                            pemasukan[
                                                                                'type'],
                                                                            style:
                                                                                TextStyle(fontSize: 16)),
                                                                      ),
                                                                      Padding(
                                                                          padding: const EdgeInsets.all(
                                                                              8),
                                                                          child:
                                                                              Text(formatPrice(pemasukan['jumlah']))),
                                                                      IconButton(
                                                                          onPressed:
                                                                              () {
                                                                            showPesananList(
                                                                                context,
                                                                                pemasukan['order'].substring(pemasukan['order'].length - 4),
                                                                                pesanan);
                                                                          },
                                                                          icon:
                                                                              Icon(Icons.remove_red_eye))
                                                                    ],
                                                                  ),
                                                                ],
                                                              ),
                                                            );
                                                          } else {
                                                            return SizedBox
                                                                .shrink();
                                                          }
                                                        },
                                                      )
                                                    : const Center(
                                                        child: Text(
                                                        'Tidak Tersedia',
                                                        style: TextStyle(
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 18),
                                                      )),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    )
                                  : SizedBox.shrink(),
                              IconButton(
                                  onPressed: () {
                                    if (detailPembayaran == false) {
                                      detailPembayaran = true;
                                    } else {
                                      detailPembayaran = false;
                                    }
                                    setState(() {});
                                  },
                                  tooltip: 'List Pesanan',
                                  icon: (detailPembayaran == false)
                                      ? Icon(Icons.keyboard_arrow_down)
                                      : Icon(Icons.keyboard_arrow_up)),
                            ],
                          ),
                        ),
                        // Stock di Toko
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Stock Bahan Toko',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: selectedStockItems.length,
                                itemBuilder: (context, index) {
                                  final stock = selectedStockItems[index];
                                  final quantity = stock['quantity'] ?? 0;
                                  return Card(
                                    child: ListTile(
                                      title: Text(stock['name']),
                                      subtitle: Text(stock['unit']),
                                      trailing: SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          enabled: (canEdit && dataLoaded),
                                          initialValue: '$quantity',
                                          style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold),
                                          textAlign: TextAlign.center,
                                          decoration: InputDecoration(
                                            contentPadding:
                                                const EdgeInsets.all(8),
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10.0),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              stock['quantity'] =
                                                  int.tryParse(value) ?? 0;
                                              updateLaporanData();
                                            });
                                          },
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                              (canEdit && dataLoaded)
                                  ? ElevatedButton(
                                      onPressed: navigateToSelectStockScreen,
                                      child: const Icon(Icons.add),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),
                        // Pengeluaran
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Pengeluaran',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: pengeluaranItems.length,
                                itemBuilder: (context, index) {
                                  final pengeluaran = pengeluaranItems[index] ??
                                      {}; // Initialize with an empty map if null
                                  final TextEditingController namaController =
                                      TextEditingController(
                                          text: pengeluaran['nama']);
                                  final TextEditingController jumlahController =
                                      TextEditingController(
                                          text: pengeluaran['jumlah']
                                                  ?.toString() ??
                                              null);

                                  if (pengeluaran['type'] == null) {
                                    pengeluaran['type'] = pengeluaranJenis[0];
                                    updateLaporanData();
                                  }

                                  if (pengeluaranJenis.any((element) =>
                                          element == pengeluaran['type']) ==
                                      false) {
                                    pengeluaranJenis.add(pengeluaran['type']);
                                  }

                                  final TextEditingController
                                      _typePengeluaranController =
                                      TextEditingController(
                                          text: pengeluaran['type']);

                                  final String photo =
                                      pengeluaran['photo'] ?? '';

                                  return Card(
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: TextField(
                                            enabled: canEdit,
                                            controller: namaController,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            decoration: const InputDecoration(
                                              labelText: 'Nama Pengeluaran',
                                            ),
                                            onChanged: (value) {
                                              pengeluaran['nama'] = value;
                                              updateLaporanData();
                                            },
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child:
                                              DropdownButtonFormField<String>(
                                            value:
                                                _typePengeluaranController.text,
                                            items:
                                                pengeluaranJenis.map((option) {
                                              return DropdownMenuItem<String>(
                                                enabled:
                                                    (canEdit && dataLoaded),
                                                value: option,
                                                child: Text(option),
                                              );
                                            }).toList(),
                                            onChanged: (value) {
                                              setState(() {
                                                pengeluaran['type'] = value!;

                                                updateLaporanData();
                                              });
                                            },
                                            decoration: InputDecoration(
                                              labelText: 'Tipe',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: TextField(
                                            enabled: canEdit,
                                            controller: jumlahController,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: const InputDecoration(
                                              labelText: 'Total Harga (Rupiah)',
                                            ),
                                            keyboardType: TextInputType.number,
                                            onChanged: (value) {
                                              pengeluaran['jumlah'] =
                                                  int.tryParse(value);
                                              updateLaporanData();
                                            },
                                          ),
                                        ),
                                        if (photo.isNotEmpty &&
                                            imageAvailable) ...[
                                          const Divider(),
                                          InkWell(
                                            child: Column(
                                              children: [
                                                SizedBox(
                                                  height: 10,
                                                ),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  children: [
                                                    Icon(Icons.photo),
                                                    Text(
                                                      pengeluaran['imageName'],
                                                      textAlign:
                                                          TextAlign.center,
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(
                                                  height: 10,
                                                ),
                                              ],
                                            ),
                                            onTap: () async {
                                              showLoadingOverlay(context);
                                              final imageData =
                                                  await BuktiDataHandlerAndroid
                                                      .instance
                                                      .loadBuktiFromFirestorage(
                                                          currentDate,
                                                          pengeluaran[
                                                              'imageName']);
                                              if (imageData != null) {
                                                hideLoadingOverlay(context);
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: Container(
                                                          child: Image.memory(
                                                              imageData)),
                                                      actions: [
                                                        TextButton(
                                                            onPressed: () {
                                                              Navigator.pop(
                                                                  context);
                                                            },
                                                            child: const Text(
                                                                'Close'))
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          const Divider(),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              (canEdit && dataLoaded)
                                                  ? IconButton(
                                                      onPressed: () async {
                                                        await BuktiDataHandlerAndroid
                                                            .instance
                                                            .deleteBukti(
                                                                currentDate,
                                                                pengeluaran[
                                                                    'imageName']);
                                                        setState(() {
                                                          pengeluaran['photo'] =
                                                              '';
                                                          pengeluaran[
                                                              'imageName'] = '';
                                                          pengeluaran[
                                                              'firestorage'] = '';
                                                          updateLaporanData();
                                                          // Save the updated data
                                                          laporanHelper
                                                              .saveLaporanToFirestore(
                                                                  laporanData,
                                                                  currentDate);
                                                        });
                                                      },
                                                      icon: const Icon(
                                                          Icons.cancel),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ],
                                        const Divider(),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            (canEdit && dataLoaded)
                                                ? IconButton(
                                                    onPressed: () async {
                                                      await BuktiDataHandlerAndroid
                                                          .instance
                                                          .deleteBukti(
                                                              currentDate,
                                                              pengeluaran[
                                                                  'imageName']);
                                                      setState(() {
                                                        pengeluaranItems
                                                            .removeAt(index);
                                                        updateLaporanData();
                                                        // Save the updated data
                                                        laporanHelper
                                                            .saveLaporanToFirestore(
                                                                laporanData,
                                                                currentDate);
                                                      });
                                                    },
                                                    icon: const Icon(
                                                        Icons.delete_forever),
                                                  )
                                                : SizedBox.shrink(),
                                            (canEdit && dataLoaded)
                                                ? IconButton(
                                                    icon: Icon((pengeluaran[
                                                                    'photo'] ==
                                                                '' &&
                                                            pengeluaran[
                                                                    'imageName'] ==
                                                                '')
                                                        ? Icons
                                                            .add_photo_alternate
                                                        : Icons.change_circle),
                                                    onPressed: () async {
                                                      showLoadingOverlay(
                                                          context);
                                                      bool status =
                                                          await pickImage(index,
                                                              'pengeluaran');
                                                      if (status || !status) {
                                                        hideLoadingOverlay(
                                                            context);
                                                      }
                                                      updateLaporanData();
                                                      // Save the updated data
                                                      laporanHelper
                                                          .saveLaporanToFirestore(
                                                              laporanData,
                                                              currentDate);
                                                    },
                                                  )
                                                : SizedBox.shrink(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              (canEdit && dataLoaded)
                                  ? ElevatedButton(
                                      onPressed: () {
                                        setState(() {
                                          pengeluaranItems.add({
                                            'nama': '',
                                            'jumlah': null,
                                            'photo': '',
                                            'imageName': '',
                                            'firestorage': '',
                                            'time': DateFormat('HH:mm:ss')
                                                .format(DateTime.now()),
                                          });
                                        });
                                      },
                                      child: const Icon(Icons.add),
                                    )
                                  : const SizedBox.shrink(),
                            ],
                          ),
                        ),

                        SizedBox(
                          height: 100,
                        )
                      ],
                    ),
                  ),
                  // Preview Laporan
                  (canEdit && dataLoaded)
                      ? Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Card(
                            color: Theme.of(context).primaryColor,
                            elevation: 2,
                            margin: const EdgeInsets.all(16),
                            child: InkWell(
                              onTap: () {
                                if (checkEmptyField()) {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Data Kosong'),
                                        content: Text(kosongMessage),
                                        actions: [
                                          TextButton(
                                            onPressed: () {
                                              Navigator.pop(
                                                  context); // Close the dialog
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                } else {
                                  showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Simpan Laporan'),
                                        content: const Text(
                                            'Apakah anda sudah yakin?'),
                                        actions: [
                                          TextButton(
                                            onPressed: () async {
                                              laporanData['uploaded'] = true;
                                              updateLaporanData();
                                              canEdit = false;

                                              Navigator.pop(
                                                  context); // Close the dialog
                                              Navigator.pop(
                                                  context); // Close the dialog
                                            },
                                            child: const Text('OK'),
                                          ),
                                        ],
                                      );
                                    },
                                  );
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                child: Text(
                                  'Simpan Laporan',
                                  textAlign: TextAlign.center,
                                  style: (Theme.of(context).brightness ==
                                          Brightness.dark)
                                      ? TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red)
                                      : TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white),
                                ),
                              ),
                            ),
                          ),
                        )
                      : SizedBox.shrink(),
                ],
              ),
      ),
    );
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

  void showLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Loading...',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16.0),
                CircularProgressIndicator(),
              ],
            ),
          ),
        );
      },
    );
  }

  void hideLoadingOverlay(BuildContext context) {
    Navigator.of(context).pop();
  }
}
