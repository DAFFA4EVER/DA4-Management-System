import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'select_menu_page.dart' as SelectMenu;
import 'select_stock_page.dart' as SelectStock;
import '../backend/laporanDataHandlerFirestore.dart';
import '../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../backend/buktiDataHandlerAndroid.dart';
import 'laporan_readySetor.dart';
import '../backend/control.dart';

class LaporanTodayScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String chooseTokoID;

  LaporanTodayScreen(
      {required this.currentdate,
      required this.edit,
      required this.chooseTokoID});

  @override
  _LaporanTodayScreenState createState() => _LaporanTodayScreenState();
}

class _LaporanTodayScreenState extends State<LaporanTodayScreen> {
  final rupiahController = TextEditingController();
  List<Map<String, dynamic>> pemasukanExternalItems = [];
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
  int cashInput = 0;
  bool dataLoaded = false;
  bool available = true;
  bool imageAvailable = false;
  List<String> pemasukkanExternalJenis = [
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
    //

    //
    canEdit = widget.edit;
    checkLaporanExist();
  }

  Map<String, dynamic> moduleSetting = {};

  void setUpModule() {
    pengeluaranJenis = List<String>.from(moduleSetting['pengeluaran']);
    pemasukkanExternalJenis = List<String>.from(moduleSetting['pemasukkan']);
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

  Future<bool> pickImage(int index, String method) async {
    try {
      var pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return true;

      final imageName = pickedImage.name;
      final imageFile = File(pickedImage.path);
      final firestorageURL = await BuktiDataHandlerAndroid.instance
          .uploadImageURL(imageFile, currentDate, widget.chooseTokoID);
      if (method == 'struk') {
        setState(() {
          strukItems[index]['photo'] = pickedImage!.path;
          strukItems[index]['imageName'] = imageName;
          strukItems[index]['firestorage'] = firestorageURL;
        });
      } else if (method == 'pemasukan') {
        setState(() {
          pemasukanExternalItems[index]['photo'] = pickedImage!.path;
          pemasukanExternalItems[index]['imageName'] = imageName;
          pemasukanExternalItems[index]['firestorage'] = firestorageURL;
        });
      } else {
        setState(() {
          pengeluaranItems[index]['photo'] = pickedImage!.path;
          pengeluaranItems[index]['imageName'] = imageName;
          pengeluaranItems[index]['firestorage'] = firestorageURL;
        });
      }
    } on PlatformException catch (e) {
      print('Error picking image: $e');
    }
    return true;
  }

  void navigateToSelectMenuScreen() async {
    if (canEdit) {
      final selected = await Navigator.push<List<Map<String, dynamic>>>(
        context,
        MaterialPageRoute(
          builder: (context) => SelectMenu.SelectMenuScreen(
            initialSelectedItems: selectedMenuItems,
            onSelectionChanged: (updatedSelection) {
              setState(() {
                selectedMenuItems = updatedSelection;
                updateLaporanData();
              });
            },
          ),
        ),
      );
      if (selected != null) {
        setState(() {
          selectedMenuItems = selected;
          updateLaporanData();
        });
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
      if (await laporanHelper.checkLaporanExist(
              currentDate, widget.chooseTokoID) ==
          false) {
        available = false;
      } else {
        laporanData = await laporanHelper.loadLaporanFromFirestore(
            currentDate, widget.chooseTokoID);
      }
      if (available) {
        selectedMenuItems =
            List<Map<String, dynamic>>.from(laporanData['menu']);

        selectedStockItems =
            List<Map<String, dynamic>>.from(laporanData['stokToko']);

        //
        if (laporanData['uploaded'] == true) {
          canEdit = false;
        }
        if (loginState.role == 'superadmin') {
          canEdit = true;
        } else if (loginState.role == 'admin') {
          canEdit = true;
        }
      }
      if (laporanData['imageData'] == null) {
        laporanData['imageData'] = true;
      }

      imageAvailable = laporanData['imageData'];

      setState(() {
        if (available) {
          tokoNama = laporanData['namaToko'];
          tanggal = laporanData['date'];
          cashInput = laporanData['cash'];

          strukItems = List<Map<String, dynamic>>.from(laporanData['struk']);
          pengeluaranItems =
              List<Map<String, dynamic>>.from(laporanData['pengeluaran']);
          pemasukanExternalItems = List<Map<String, dynamic>>.from(
              laporanData['pemasukan external']);
          rupiahController.text = cashInput.toString();

          absenItems = List<Map<String, dynamic>>.from(laporanData['absen']);
          getModuleSetting();
          dataLoaded = true;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  bool checkEmptyField() {
    if (canEdit) {
      return false;
    }
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

    if (strukItems
        .any((item) => item['photo'] == '' || item['imageName'] == '')) {
      kosongMessage = 'Data struk belum lengkap';
      return true;
    }

    if (pemasukanExternalItems
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

    if (pemasukanExternalItems
        .any((item) => item['jumlah'] == null || item['nama'] == '')) {
      kosongMessage = 'Data pemasukan belum lengkap';
      return true;
    }
    //
    if (strukItems.any((item) => item['nama'] == '' || item['jumlah'] == '')) {
      kosongMessage = 'Data struk belum lengkap';
      return true;
    }
    //
    if (absenItems.any((item) =>
        (item['masuk'] == '' || item['keluar'] == '') &&
        item['role'] != 'off')) {
      kosongMessage = 'Data absen belum lengkap';
      return true;
    }
    //
    if (selectedMenuItems.any((item) => item['quantity'] == 0)) {
      kosongMessage = 'Data menu belum lengkap';
      return true;
    }
    if (cashInput == 0) {
      kosongMessage = 'Data uang cash belum lengkap';
      return true;
    }
    return false;
  }

  void updateLaporanData() {
    if (canEdit) {
      // Menu
      for (final selectedItem in selectedMenuItems) {
        final String itemName = selectedItem['name'];
        final existingItemIndex = laporanData['menu'].indexWhere(
          (item) => item['name'] == itemName,
        );
        if (existingItemIndex != -1) {
          laporanData['menu'][existingItemIndex]['quantity'] =
              selectedItem['quantity'];
        } else {
          laporanData['menu'].add(selectedItem);
        }
      }

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
      laporanData['cash'] = cashInput;
      // Pengeluaran
      laporanData['pengeluaran'] = pengeluaranItems;
      // pemasukan
      laporanData['pemasukan external'] = pemasukanExternalItems;

      laporanData['struk'] = strukItems;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (checkEmptyField() && available) {
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
                        laporanHelper.saveLaporanToFirestore(
                            laporanData, currentDate, widget.chooseTokoID);
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
                      if (available) {
                        laporanHelper.saveLaporanToFirestore(
                            laporanData, currentDate, widget.chooseTokoID);
                      }
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
        } // Save the data before popping the route
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Laporan Hari Ini'),
        ),
        body: (dataLoaded == false && available)
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
                : ListView(
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
                                        enabled: (canEdit && dataLoaded),
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
                            (canEdit && dataLoaded)
                                ? ElevatedButton(
                                    onPressed: navigateToSelectMenuScreen,
                                    child: const Icon(Icons.add),
                                  )
                                : const SizedBox.shrink(),
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
                                'Stock di Toko',
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
                      // Cash
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Total Uang Cash',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: TextField(
                                keyboardType: TextInputType.number,
                                enabled: canEdit,
                                controller: rupiahController,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.bold),
                                decoration: InputDecoration(
                                  labelText: 'Jumlah (Rupiah)',
                                ),
                                onChanged: (value) {
                                  setState(() {
                                    cashInput = int.tryParse(
                                            value.replaceAll(',', '')) ??
                                        0;
                                    updateLaporanData();
                                  });
                                },
                              ),
                            ),
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
                                        text:
                                            pengeluaran['jumlah']?.toString() ??
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

                                final String photo = pengeluaran['photo'] ?? '';

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
                                        child: DropdownButtonFormField<String>(
                                          value:
                                              _typePengeluaranController.text,
                                          items: pengeluaranJenis.map((option) {
                                            return DropdownMenuItem<String>(
                                              enabled: (canEdit && dataLoaded),
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
                                                    textAlign: TextAlign.center,
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
                                                            'imageName'],
                                                        widget.chooseTokoID);
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
                                                                  'imageName'],
                                                              widget
                                                                  .chooseTokoID);
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
                                                                currentDate,
                                                                widget
                                                                    .chooseTokoID);
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
                                                                'imageName'],
                                                            widget
                                                                .chooseTokoID);
                                                    setState(() {
                                                      pengeluaranItems
                                                          .removeAt(index);
                                                      updateLaporanData();
                                                      // Save the updated data
                                                      laporanHelper
                                                          .saveLaporanToFirestore(
                                                              laporanData,
                                                              currentDate,
                                                              widget
                                                                  .chooseTokoID);
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
                                                    showLoadingOverlay(context);
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
                                                            currentDate,
                                                            widget
                                                                .chooseTokoID);
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
                                          'firestorage': ''
                                        });
                                      });
                                    },
                                    child: const Icon(Icons.add),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),

                      // Pemasukan external
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Pemasukan External',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: pemasukanExternalItems.length,
                              itemBuilder: (context, index) {
                                final pemasukan = pemasukanExternalItems[
                                        index] ??
                                    {}; // Initialize with an empty map if null
                                final TextEditingController namaController =
                                    TextEditingController(
                                        text: pemasukan['nama']);
                                final TextEditingController jumlahController =
                                    TextEditingController(
                                        text: pemasukan['jumlah']?.toString() ??
                                            null);
                                final String photo = pemasukan['photo'] ?? '';

                                if (pemasukan['type'] == null) {
                                  pemasukan['type'] =
                                      pemasukkanExternalJenis[0];
                                  updateLaporanData();
                                }
                                if (pemasukkanExternalJenis.any((element) =>
                                        element == pemasukan['type']) ==
                                    false) {
                                  pemasukkanExternalJenis
                                      .add(pemasukan['type']);
                                }
                                final TextEditingController
                                    _typePemasukanController =
                                    TextEditingController(
                                        text: pemasukan['type'] ??
                                            pemasukkanExternalJenis[0]);

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
                                            labelText: 'Nama pemasukan',
                                          ),
                                          onChanged: (value) {
                                            pemasukan['nama'] = value;
                                            updateLaporanData();
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: DropdownButtonFormField<String>(
                                          value: _typePemasukanController.text,
                                          items: pemasukkanExternalJenis
                                              .map((option) {
                                            return DropdownMenuItem<String>(
                                              value: option,
                                              enabled: (canEdit && dataLoaded),
                                              child: Text(option),
                                            );
                                          }).toList(),
                                          onChanged: (value) {
                                            setState(() {
                                              pemasukan['type'] = value!;
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
                                            pemasukan['jumlah'] =
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
                                                    pemasukan['imageName'],
                                                    textAlign: TextAlign.center,
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
                                                        pemasukan['imageName'],
                                                        widget.chooseTokoID);
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
                                                              pemasukan[
                                                                  'imageName'],
                                                              widget
                                                                  .chooseTokoID);
                                                      setState(() {
                                                        pemasukan['photo'] = '';
                                                        pemasukan['imageName'] =
                                                            '';
                                                        pemasukan[
                                                            'firestorage'] = '';
                                                        updateLaporanData();

                                                        // Save the updated data
                                                        laporanHelper
                                                            .saveLaporanToFirestore(
                                                                laporanData,
                                                                currentDate,
                                                                widget
                                                                    .chooseTokoID);
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
                                                            pemasukan[
                                                                'imageName'],
                                                            widget
                                                                .chooseTokoID);
                                                    setState(() {
                                                      pemasukanExternalItems
                                                          .removeAt(index);
                                                      updateLaporanData();

                                                      // Save the updated data
                                                      laporanHelper
                                                          .saveLaporanToFirestore(
                                                              laporanData,
                                                              currentDate,
                                                              widget
                                                                  .chooseTokoID);
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.delete_forever),
                                                )
                                              : SizedBox.shrink(),
                                          (canEdit && dataLoaded)
                                              ? IconButton(
                                                  icon: Icon((pemasukan[
                                                                  'photo'] ==
                                                              '' &&
                                                          pemasukan[
                                                                  'imageName'] ==
                                                              '')
                                                      ? Icons
                                                          .add_photo_alternate
                                                      : Icons.change_circle),
                                                  onPressed: () async {
                                                    showLoadingOverlay(context);
                                                    bool status =
                                                        await pickImage(
                                                            index, 'pemasukan');
                                                    if (status || !status) {
                                                      hideLoadingOverlay(
                                                          context);
                                                    }
                                                    updateLaporanData();

                                                    // Save the updated data
                                                    laporanHelper
                                                        .saveLaporanToFirestore(
                                                            laporanData,
                                                            currentDate,
                                                            widget
                                                                .chooseTokoID);
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
                                        pemasukanExternalItems.add({
                                          'nama': '',
                                          'jumlah': null,
                                          'photo': '',
                                          'imageName': '',
                                          'firestorage': ''
                                        });
                                      });
                                    },
                                    child: const Icon(Icons.add),
                                  )
                                : const SizedBox.shrink(),
                          ],
                        ),
                      ),
                      // Struk
                      Card(
                        elevation: 2,
                        margin: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 12),
                              child: Text(
                                'Struk Penjualan',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: strukItems.length,
                              itemBuilder: (context, index) {
                                final struk = strukItems[index] ??
                                    {}; // Initialize with an empty map if null
                                final TextEditingController
                                    namaStrukController =
                                    TextEditingController(text: struk['nama']);
                                if (struk['jumlah'] == null) {
                                  struk['jumlah'] = '';
                                }
                                final TextEditingController jumlahController =
                                    TextEditingController(
                                        text:
                                            struk['jumlah']?.toString() ?? '');

                                final String photo = struk['photo'] ?? '';

                                return Card(
                                  child: Column(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          enabled: (canEdit && dataLoaded),
                                          controller: namaStrukController,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold),
                                          decoration: const InputDecoration(
                                            labelText: 'Nama struk',
                                          ),
                                          onChanged: (value) {
                                            struk['nama'] = value;
                                            updateLaporanData();
                                          },
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: TextField(
                                          controller: jumlahController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          decoration: const InputDecoration(
                                            labelText:
                                                'Total Pendapatan Sesuai Struk (Rupiah)',
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            struk['jumlah'] =
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
                                                    struk['imageName'],
                                                    textAlign: TextAlign.center,
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
                                                        struk['imageName'],
                                                        widget.chooseTokoID);
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
                                                              struk[
                                                                  'imageName'],
                                                              widget
                                                                  .chooseTokoID);
                                                      setState(() {
                                                        struk['photo'] = '';
                                                        struk['imageName'] = '';
                                                        struk['firestorage'] =
                                                            '';
                                                        updateLaporanData();

                                                        // Save the updated data
                                                        laporanHelper
                                                            .saveLaporanToFirestore(
                                                                laporanData,
                                                                currentDate,
                                                                widget
                                                                    .chooseTokoID);
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
                                                            struk['imageName'],
                                                            widget
                                                                .chooseTokoID);
                                                    setState(() {
                                                      pemasukanExternalItems
                                                          .removeAt(index);
                                                      updateLaporanData();

                                                      // Save the updated data
                                                      laporanHelper
                                                          .saveLaporanToFirestore(
                                                              laporanData,
                                                              currentDate,
                                                              widget
                                                                  .chooseTokoID);
                                                    });
                                                  },
                                                  icon: const Icon(
                                                      Icons.delete_forever),
                                                )
                                              : SizedBox.shrink(),
                                          (canEdit && dataLoaded)
                                              ? IconButton(
                                                  icon: Icon((struk['photo'] ==
                                                              '' &&
                                                          struk['imageName'] ==
                                                              '')
                                                      ? Icons
                                                          .add_photo_alternate
                                                      : Icons.change_circle),
                                                  onPressed: () async {
                                                    showLoadingOverlay(context);
                                                    bool status =
                                                        await pickImage(
                                                            index, 'struk');
                                                    if (status || !status) {
                                                      hideLoadingOverlay(
                                                          context);
                                                    }
                                                    updateLaporanData();

                                                    // Save the updated data
                                                    laporanHelper
                                                        .saveLaporanToFirestore(
                                                            laporanData,
                                                            currentDate,
                                                            widget
                                                                .chooseTokoID);
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
                          ],
                        ),
                      ),
                      // Preview Laporan
                      (canEdit && dataLoaded)
                          ? Card(
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
                                    updateLaporanData();
                                    // Save the updated data
                                    laporanHelper.saveLaporanToFirestore(
                                        laporanData,
                                        currentDate,
                                        widget.chooseTokoID);

                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                LaporanSetorScreen(
                                                    chooseTokoID:
                                                        widget.chooseTokoID,
                                                    edit: false,
                                                    currentdate: currentDate)));
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  child: Text(
                                    'Preview Laporan',
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
