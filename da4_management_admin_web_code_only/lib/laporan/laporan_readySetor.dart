import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import '../backend/buktiDataHandlerAndroid.dart';
import '../main_menu.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as Path;
import 'package:cached_network_image/cached_network_image.dart';
import '../backend/control.dart';
import '../backend/moduleDataHandler.dart';

class LaporanSetorScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String chooseTokoID;

  LaporanSetorScreen(
      {required this.currentdate,
      required this.edit,
      required this.chooseTokoID});

  @override
  _LaporanSetorScreenState createState() => _LaporanSetorScreenState();
}

class _LaporanSetorScreenState extends State<LaporanSetorScreen> {
  String? selectedPenanggungJawab;
  List<String> penanggungJawabList = [];
  final rupiahController = TextEditingController();
  List<Map<String, dynamic>> pemasukanExternalItems = [];
  List<Map<String, dynamic>> pengeluaranItems = [];
  List<Map<String, dynamic>> strukItems = [];
  List<Map<String, dynamic>> setorItems = [];
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
  num totalPengeluaran = 0;
  num totalStruk = 0;
  num totalPemasukan = 0;
  num totalMenu = 0;
  bool uploaded = false;
  bool belumSetor = true;
  bool dataLoaded = false;
  bool abort = false;
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
    canEdit = false;
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

  Future<void> checkLaporanExist() async {
    try {
      if (await laporanHelper.checkLaporanExist(
              currentDate, widget.chooseTokoID) ==
          false) {
        available = false;
        dataLoaded = true;
        abort = true;
      } else {
        laporanData = await laporanHelper.loadLaporanFromFirestore(
            currentDate, widget.chooseTokoID);
      }
      if (available) {
        selectedMenuItems =
            List<Map<String, dynamic>>.from(laporanData['menu']);

        selectedStockItems =
            List<Map<String, dynamic>>.from(laporanData['stokToko']);

        if (laporanData['sudahSetor'] == null) {
          laporanData['sudahSetor'] = false;
          belumSetor = true;
        } else {
          if (laporanData['sudahSetor'] == true) {
            belumSetor = false;
          }
        }
      }
      canEdit = false;
      if (loginState.role == 'superadmin') {
        canEdit = true;
        belumSetor = true;
      } else if (loginState.role == 'admin') {
        canEdit = true;
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

          setorItems = List<Map<String, dynamic>>.from(laporanData['setor']);

          strukItems = List<Map<String, dynamic>>.from(laporanData['struk']);
          pengeluaranItems =
              List<Map<String, dynamic>>.from(laporanData['pengeluaran']);
          pemasukanExternalItems = List<Map<String, dynamic>>.from(
              laporanData['pemasukan external']);
          rupiahController.text = cashInput.toString();

          absenItems = List<Map<String, dynamic>>.from(laporanData['absen']);
          uploaded = laporanData['uploaded'];

          getListJawab();
          updateLaporanData();
          getGrandTotal();
          getModuleSetting();
          dataLoaded = true;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<bool> pickImage(int index, String method) async {
    try {
      var pickedImage =
          await ImagePicker().getImage(source: ImageSource.gallery);
      if (pickedImage == null) return false;

      final imageName = Path.basename(pickedImage!.path);

      final firestorageURL = await BuktiDataHandlerAndroid.instance
          .uploadImageURL(
              pickedImage, imageName, currentDate, widget.chooseTokoID);

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
      } else if (method == 'setor') {
        setorItems[index]['photo'] = pickedImage!.path;
        setorItems[index]['imageName'] = imageName;
        setorItems[index]['firestorage'] = firestorageURL;
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

  void updateLaporanData() {
    if (canEdit) {
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
    }
    laporanData['uploaded'] = uploaded;
    // Pengeluaran
    laporanData['pengeluaran'] = pengeluaranItems;
    laporanData['pemasukan external'] = pemasukanExternalItems;
    laporanData['penanggungJawab'] = selectedPenanggungJawab;
    laporanData['setor'] = setorItems;

    uploaded = laporanData['uploaded'];
    LaporanDatabaseHandlerFirestore.instance
        .saveLaporanToFirestore(laporanData, currentDate, widget.chooseTokoID);
    print('a');
  }

  void getGrandTotal() {
    // pengeluaran
    for (int i = 0; i < pengeluaranItems.length; i++) {
      totalPengeluaran += (pengeluaranItems[i]['jumlah']);
    }
    for (int i = 0; i < pemasukanExternalItems.length; i++) {
      totalPemasukan += (pemasukanExternalItems[i]['jumlah']);
    }
    for (int i = 0; i < selectedMenuItems.length; i++) {
      totalMenu +=
          (selectedMenuItems[i]['jual'] * selectedMenuItems[i]['quantity']);
    }
    for (int i = 0; i < strukItems.length; i++) {
      totalStruk += strukItems[i]['jumlah'] ?? 0;
    }
    setState(() {
      totalMenu;
      totalPemasukan;
      totalPengeluaran;
    });
  }

  void getListJawab() {
    penanggungJawabList = absenItems
        .where((item) => item['shift'] == 'Shift 2')
        .map((item) => item['nama'])
        .toList()
        .map((dynamic value) => value.toString())
        .toList();

    if (penanggungJawabList.isEmpty) {
      penanggungJawabList = absenItems
          .where((item) => item['shift'] == 'Shift 2')
          .map((item) => item['nama'])
          .toList()
          .map((dynamic value) => value.toString())
          .toList();
      if (penanggungJawabList.isEmpty) {
        penanggungJawabList.add('Belum absen');
      }
    }

    selectedPenanggungJawab = penanggungJawabList[0];
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
    // Setor
    if (setorItems.any((item) =>
        item['photo'] == '' ||
        item['imageName'] == '' ||
        item['jumlah'] == null ||
        item['nama'] == '' ||
        item['bank'] == '' ||
        item['rekening'] == '')) {
      kosongMessage = 'Data setor belum lengkap';
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
    if (strukItems.any((item) => item['nama'] == '')) {
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

  String capitalize(String text) {
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (checkEmptyField() && available) {
          if (canEdit) {
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
          title: const Text('Preview Laporan'),
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
            : ((dataLoaded == true) && (abort == true))
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
                : SelectionArea(
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
                                          enabled: (canEdit &&
                                              (loginState.role ==
                                                  'superadmin')),
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
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                                          enabled: (canEdit &&
                                              (loginState.role ==
                                                  'superadmin')),
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
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
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
                                  enabled: (canEdit &&
                                      (loginState.role == 'superadmin')),
                                  controller: rupiahController,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold),
                                  decoration: InputDecoration(
                                    labelText: 'Jumlah (Rupiah)',
                                  ),
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
                                            enabled: !uploaded,
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
                                            enableFeedback: !uploaded,
                                            value:
                                                _typePengeluaranController.text,
                                            items:
                                                pengeluaranJenis.map((option) {
                                              return DropdownMenuItem<String>(
                                                enabled: !uploaded,
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
                                            enabled: !uploaded,
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
                                                        width: double.maxFinite,
                                                        height:
                                                            double.maxFinite,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: imageData,
                                                          fit: BoxFit.contain,
                                                          placeholder: (context,
                                                                  url) =>
                                                              CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              (uploaded == false)
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
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            (uploaded == false)
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
                                            (uploaded == false)
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
                              (uploaded == false)
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
                                          text:
                                              pemasukan['jumlah']?.toString() ??
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
                                            enabled: ((canEdit &&
                                                    (loginState.role ==
                                                        'superadmin')) &&
                                                dataLoaded),
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
                                          child:
                                              DropdownButtonFormField<String>(
                                            enableFeedback: ((canEdit &&
                                                    (loginState.role ==
                                                        'superadmin')) &&
                                                dataLoaded),
                                            value:
                                                _typePemasukanController.text,
                                            items: pemasukkanExternalJenis
                                                .map((option) {
                                              return DropdownMenuItem<String>(
                                                value: option,
                                                enabled: ((canEdit &&
                                                        (loginState.role ==
                                                            'superadmin')) &&
                                                    dataLoaded),
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
                                            enabled: (canEdit &&
                                                (loginState.role ==
                                                    'superadmin')),
                                            controller: jumlahController,
                                            inputFormatters: [
                                              FilteringTextInputFormatter
                                                  .digitsOnly,
                                            ],
                                            decoration: const InputDecoration(
                                              labelText: 'Total Harga (Rupiah)',
                                            ),
                                            keyboardType: TextInputType.number,
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
                                                          pemasukan[
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
                                                        width: double.maxFinite,
                                                        height:
                                                            double.maxFinite,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: imageData,
                                                          fit: BoxFit.contain,
                                                          placeholder: (context,
                                                                  url) =>
                                                              CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              (canEdit &&
                                                      (loginState.role ==
                                                          'superadmin'))
                                                  ? IconButton(
                                                      onPressed: () async {},
                                                      icon: const Icon(
                                                          Icons.cancel),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ],
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            (canEdit &&
                                                    (loginState.role ==
                                                        'superadmin'))
                                                ? IconButton(
                                                    onPressed: () async {},
                                                    icon: const Icon(
                                                        Icons.delete_forever),
                                                  )
                                                : SizedBox.shrink(),
                                            (canEdit &&
                                                    (loginState.role ==
                                                        'superadmin'))
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
                                                    onPressed: () {},
                                                  )
                                                : SizedBox.shrink(),
                                          ],
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              (canEdit && (loginState.role == 'superadmin'))
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
                                      TextEditingController(
                                          text: struk['nama']);
                                  final TextEditingController jumlahController =
                                      TextEditingController(
                                          text: struk['jumlah']?.toString() ??
                                              '');

                                  final String photo = struk['photo'] ?? '';

                                  return Card(
                                    child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: TextField(
                                            enabled: (canEdit &&
                                                (loginState.role ==
                                                    'superadmin')),
                                            controller: namaStrukController,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                            decoration: const InputDecoration(
                                              labelText: 'Nama struk',
                                            ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.all(8),
                                          child: TextField(
                                            enabled: ((canEdit &&
                                                    (loginState.role ==
                                                        'superadmin')) &&
                                                dataLoaded),
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
                                                        width: double.maxFinite,
                                                        height:
                                                            double.maxFinite,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: imageData,
                                                          fit: BoxFit.contain,
                                                          placeholder: (context,
                                                                  url) =>
                                                              CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                        ],
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Grand Total
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: ListTile(
                            title: const Text(
                              'Total Keseluruhan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'Total Pemasukan External : \n${formatPrice(totalPemasukan)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'Total Pengeluaran : \n${formatPrice(totalPengeluaran)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'Total Menu Terjual : \n${formatPrice(totalMenu)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'Total Menu Terjual Sesuai Struk : \n${formatPrice(totalStruk)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                  Text(
                                    'Total Uang Cash : \n${formatPrice(cashInput)}',
                                    style: TextStyle(fontSize: 16),
                                  ),
                                  SizedBox(
                                    height: 12,
                                  ),
                                ]),
                          ),
                        ),
                        // Absen
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  "Absen Hari Ini",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: absenItems.length,
                                itemBuilder: (context, index) {
                                  final absen = absenItems[index] ??
                                      {}; // Initialize with an empty map if null
                                  final String namaPegawai = absen['nama'];
                                  final String rolePegawai = absen['role'];
                                  final String shiftPegawai = absen['shift'];
                                  final String waktuPegawai = absen['waktu'];
                                  final String photo = absen['photo'] ?? '';
                                  final String photo2 = absen['photo2'] ?? '';
                                  if (absen['imageName2'] == null) {
                                    absen['imageName2'] = '';
                                  }

                                  return Card(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Row(children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            namaPegawai,
                                            style: TextStyle(
                                              fontSize: 25,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ]),
                                        Row(children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            capitalize(rolePegawai),
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                        ]),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        Text(
                                          "Shift ${capitalize(shiftPegawai)}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.normal,
                                          ),
                                        ),
                                        Text(
                                          waktuPegawai,
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.normal,
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
                                                    Icon(
                                                      Icons.photo,
                                                    ),
                                                    Text(
                                                      absen['imageName'],
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(),
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
                                                absen['imageName'],
                                                widget.chooseTokoID,
                                              );
                                              if (imageData != null) {
                                                hideLoadingOverlay(context);
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: Container(
                                                        width: double.maxFinite,
                                                        height:
                                                            double.maxFinite,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: imageData,
                                                          fit: BoxFit.contain,
                                                          placeholder: (context,
                                                                  url) =>
                                                              CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              (canEdit &&
                                                      (loginState.role ==
                                                          'superadmin'))
                                                  ? IconButton(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: Text(
                                                                  'Hapus Photo'),
                                                              content: Text(
                                                                  'Hapus photo akan merubah jam masuk anda. Yakin?'),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: const Text(
                                                                        'Tidak')),
                                                                TextButton(
                                                                    onPressed:
                                                                        () async {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            'Ya'))
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                      icon: const Icon(
                                                          Icons.cancel),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ],
                                        Text(
                                          'Masuk',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          absen['masuk'],
                                          style: TextStyle(),
                                        ),
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            (rolePegawai != 'off' &&
                                                    absen['photo'] == '')
                                                ? (canEdit &&
                                                        (loginState.role ==
                                                            'superadmin'))
                                                    ? IconButton(
                                                        icon: Icon((absen[
                                                                        'photo'] ==
                                                                    '' &&
                                                                absen['imageName'] ==
                                                                    '')
                                                            ? Icons
                                                                .add_photo_alternate
                                                            : Icons
                                                                .change_circle),
                                                        onPressed: () {},
                                                      )
                                                    : SizedBox.shrink()
                                                : SizedBox.shrink(),
                                          ],
                                        ),
                                        const Divider(),
                                        // Keluar photo
                                        if (photo2.isNotEmpty) ...[
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
                                                    Icon(
                                                      Icons.photo,
                                                    ),
                                                    Text(
                                                      absen['imageName2'],
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: TextStyle(),
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
                                                absen['imageName2'],
                                                widget.chooseTokoID,
                                              );
                                              if (imageData != null) {
                                                hideLoadingOverlay(context);
                                                showDialog(
                                                  context: context,
                                                  builder:
                                                      (BuildContext context) {
                                                    return AlertDialog(
                                                      content: Container(
                                                        width: double.maxFinite,
                                                        height:
                                                            double.maxFinite,
                                                        child:
                                                            CachedNetworkImage(
                                                          imageUrl: imageData,
                                                          fit: BoxFit.contain,
                                                          placeholder: (context,
                                                                  url) =>
                                                              CircularProgressIndicator(),
                                                          errorWidget: (context,
                                                                  url, error) =>
                                                              Icon(Icons.error),
                                                        ),
                                                      ),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () {
                                                            Navigator.pop(
                                                                context);
                                                          },
                                                          child: const Text(
                                                              'Close'),
                                                        ),
                                                      ],
                                                    );
                                                  },
                                                );
                                              }
                                            },
                                          ),
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              (canEdit &&
                                                      (loginState.role ==
                                                          'superadmin'))
                                                  ? IconButton(
                                                      onPressed: () {
                                                        showDialog(
                                                          context: context,
                                                          builder: (BuildContext
                                                              context) {
                                                            return AlertDialog(
                                                              title: Text(
                                                                  'Hapus Photo'),
                                                              content: Text(
                                                                  'Hapus photo akan merubah jam masuk anda. Yakin?'),
                                                              actions: [
                                                                TextButton(
                                                                    onPressed:
                                                                        () {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child: const Text(
                                                                        'Tidak')),
                                                                TextButton(
                                                                    onPressed:
                                                                        () async {
                                                                      Navigator.pop(
                                                                          context);
                                                                    },
                                                                    child:
                                                                        const Text(
                                                                            'Ya'))
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                      icon: const Icon(
                                                        Icons.cancel,
                                                      ),
                                                    )
                                                  : const SizedBox.shrink(),
                                            ],
                                          ),
                                        ],
                                        (absen['keluar'] != '')
                                            ? Column(
                                                children: [
                                                  Text(
                                                    'Keluar',
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                    ),
                                                  ),
                                                  Text(
                                                    absen['keluar'],
                                                    style: TextStyle(),
                                                  ),
                                                  SizedBox(
                                                    height: 10,
                                                  ),
                                                ],
                                              )
                                            : SizedBox.shrink(),

                                        (absen['keterangan'] != '')
                                            ? const Divider()
                                            : SizedBox.shrink(),
                                        (absen['keterangan'] != '')
                                            ? Padding(
                                                padding:
                                                    const EdgeInsets.all(8.0),
                                                child: Text(
                                                  absen['keterangan'],
                                                  style: TextStyle(),
                                                ))
                                            : SizedBox.shrink(),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Penanggung Jawab Laporan

                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Penanggung Jawab Laporan',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              (uploaded == false)
                                  ? DropdownButton<String>(
                                      value: selectedPenanggungJawab,
                                      hint: Text('Select Penanggung Jawab'),
                                      items: penanggungJawabList
                                          .map((String option) {
                                            return DropdownMenuItem<String>(
                                              value: option,
                                              child: Text(option),
                                            );
                                          })
                                          .toSet()
                                          .toList(), // Convert to a set to remove duplicate values, then convert back to a list
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedPenanggungJawab =
                                              newValue ?? '';
                                        });
                                      },
                                    )
                                  : Text(
                                      laporanData['penanggungJawab'],
                                      style: TextStyle(
                                        fontSize: 16,
                                      ),
                                    ),
                              SizedBox(
                                height: 8,
                              )
                            ],
                          ),
                        ),
                        // Confirmation
                        (laporanData['uploaded'] == false)
                            ? Card(
                                color: Theme.of(context).primaryColor,
                                elevation: 2,
                                margin: const EdgeInsets.all(16),
                                child: InkWell(
                                  onTap: () {
                                    (checkEmptyField() == false)
                                        ? showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text('Konfirmasi'),
                                                content: Text(
                                                    'Apakah anda sudah yakin data yang dimasukkan valid?'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          uploaded = false;
                                                          Navigator.pop(
                                                              context);
                                                        });
                                                      },
                                                      child: Text('Tidak')),
                                                  TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          uploaded = true;
                                                          laporanData[
                                                                  'uploaded'] =
                                                              uploaded;
                                                          laporanData[
                                                                  'penanggungJawab'] =
                                                              selectedPenanggungJawab;
                                                          updateLaporanData();

                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          MainMenu()),
                                                              (route) => false);
                                                        });
                                                      },
                                                      child: Text('Ya'))
                                                ],
                                              );
                                            },
                                          )
                                        : SizedBox.shrink();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      (checkEmptyField() == false)
                                          ? 'Kirim Laporan'
                                          : 'Belum Lengkap',
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
                            : Card(
                                color: Theme.of(context).primaryColor,
                                elevation: 2,
                                margin: const EdgeInsets.all(16),
                                child: InkWell(
                                  onTap: () {},
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      'Terkirim',
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
                        // Setor
                        (uploaded == true)
                            ? Card(
                                elevation: 2,
                                margin: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Padding(
                                      padding:
                                          EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'Setor Ke Bank',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    ListView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: setorItems.length,
                                      itemBuilder: (context, index) {
                                        final setor = setorItems[index] ??
                                            {}; // Initialize with an empty map if null
                                        final TextEditingController
                                            setorNamaController =
                                            TextEditingController(
                                                text: setor['nama']);
                                        final TextEditingController
                                            setorBankController =
                                            TextEditingController(
                                                text: setor['bank']);
                                        final TextEditingController
                                            setorRekeningController =
                                            TextEditingController(
                                                text: setor['rekening']);
                                        final TextEditingController
                                            setorJumlahController =
                                            TextEditingController(
                                                text: setor['jumlah']
                                                        ?.toString() ??
                                                    null);

                                        final String photo =
                                            setor['photo'] ?? '';

                                        return Card(
                                          child: Column(
                                            children: [
                                              Padding(
                                                // nama setor
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: TextField(
                                                  enabled: belumSetor,
                                                  controller:
                                                      setorNamaController,
                                                  onChanged: (value) {
                                                    setor['nama'] = value;
                                                    updateLaporanData();
                                                  },
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Penanggung Jawab Setor',
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                // nama bank
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: TextField(
                                                  enabled: belumSetor,
                                                  controller:
                                                      setorBankController,
                                                  onChanged: (value) {
                                                    setor['bank'] = value;
                                                    updateLaporanData();
                                                  },
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'Bank Tujuan',
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                // no rekening
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: TextField(
                                                  enabled: belumSetor,
                                                  controller:
                                                      setorRekeningController,
                                                  onChanged: (value) {
                                                    setor['rekening'] = value;
                                                    updateLaporanData();
                                                  },
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    FilteringTextInputFormatter
                                                        .digitsOnly,
                                                  ],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText: 'No Rekening',
                                                  ),
                                                ),
                                              ),
                                              Padding(
                                                // jumlah
                                                padding:
                                                    const EdgeInsets.all(8),
                                                child: TextField(
                                                  enabled: belumSetor,
                                                  onChanged: (value) {
                                                    setor['jumlah'] = value;
                                                    updateLaporanData();
                                                  },
                                                  controller:
                                                      setorJumlahController,
                                                  keyboardType:
                                                      TextInputType.number,
                                                  inputFormatters: [
                                                    ThousandsSeparatorDigitsOnlyInputFormatter(),
                                                  ],
                                                  style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold),
                                                  decoration:
                                                      const InputDecoration(
                                                    labelText:
                                                        'Jumlah (Rupiah)',
                                                  ),
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
                                                            CrossAxisAlignment
                                                                .center,
                                                        children: [
                                                          Icon(Icons.photo),
                                                          Text(
                                                            setor['imageName'],
                                                            textAlign: TextAlign
                                                                .center,
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
                                                                setor[
                                                                    'imageName'],
                                                                widget
                                                                    .chooseTokoID);
                                                    if (imageData != null) {
                                                      hideLoadingOverlay(
                                                          context);
                                                      showDialog(
                                                        context: context,
                                                        builder: (BuildContext
                                                            context) {
                                                          return AlertDialog(
                                                            content: Container(
                                                              width: double
                                                                  .maxFinite,
                                                              height: double
                                                                  .maxFinite,
                                                              child:
                                                                  CachedNetworkImage(
                                                                imageUrl:
                                                                    imageData,
                                                                fit: BoxFit
                                                                    .contain,
                                                                placeholder: (context,
                                                                        url) =>
                                                                    CircularProgressIndicator(),
                                                                errorWidget: (context,
                                                                        url,
                                                                        error) =>
                                                                    Icon(Icons
                                                                        .error),
                                                              ),
                                                            ),
                                                            actions: [
                                                              TextButton(
                                                                onPressed: () {
                                                                  Navigator.pop(
                                                                      context);
                                                                },
                                                                child:
                                                                    const Text(
                                                                        'Close'),
                                                              ),
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
                                                    (belumSetor)
                                                        ? IconButton(
                                                            onPressed:
                                                                () async {
                                                              await BuktiDataHandlerAndroid
                                                                  .instance
                                                                  .deleteBukti(
                                                                      currentDate,
                                                                      setor[
                                                                          'imageName'],
                                                                      widget
                                                                          .chooseTokoID);
                                                              setState(() {
                                                                setor['photo'] =
                                                                    '';
                                                                setor['imageName'] =
                                                                    '';
                                                                setor['firestorage'] =
                                                                    '';
                                                                updateLaporanData();

                                                                // Save the updated data
                                                                laporanHelper.saveLaporanToFirestore(
                                                                    laporanData,
                                                                    currentDate,
                                                                    widget
                                                                        .chooseTokoID);
                                                              });
                                                            },
                                                            icon: const Icon(
                                                                Icons.cancel),
                                                          )
                                                        : const SizedBox
                                                            .shrink(),
                                                  ],
                                                ),
                                              ],
                                              Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  (belumSetor)
                                                      ? IconButton(
                                                          onPressed: () async {
                                                            await BuktiDataHandlerAndroid
                                                                .instance
                                                                .deleteBukti(
                                                                    currentDate,
                                                                    setor[
                                                                        'imageName'],
                                                                    widget
                                                                        .chooseTokoID);
                                                            setState(() {
                                                              pemasukanExternalItems
                                                                  .removeAt(
                                                                      index);
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
                                                          icon: const Icon(Icons
                                                              .delete_forever),
                                                        )
                                                      : SizedBox.shrink(),
                                                  (belumSetor)
                                                      ? IconButton(
                                                          icon: Icon((setor[
                                                                          'photo'] ==
                                                                      '' &&
                                                                  setor['imageName'] ==
                                                                      '')
                                                              ? Icons
                                                                  .add_photo_alternate
                                                              : Icons
                                                                  .change_circle),
                                                          onPressed: () async {
                                                            showLoadingOverlay(
                                                                context);
                                                            bool status =
                                                                await pickImage(
                                                                    index,
                                                                    'setor');
                                                            if (status ||
                                                                !status) {
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
                                                            setState(() {});
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
                              )
                            : SizedBox.shrink(),
                        // Confirmation Setor
                        (belumSetor == true && uploaded == true)
                            ? Card(
                                color: Theme.of(context).primaryColor,
                                elevation: 2,
                                margin: const EdgeInsets.all(16),
                                child: InkWell(
                                  onTap: () {
                                    (checkEmptyField() == false)
                                        ? showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: const Text(
                                                    'Konfirmasi Setor'),
                                                content: Text(
                                                    'Apakah anda sudah yakin data yang dimasukkan valid?'),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          uploaded = false;
                                                          Navigator.pop(
                                                              context);
                                                        });
                                                      },
                                                      child: Text('Tidak')),
                                                  TextButton(
                                                      onPressed: () {
                                                        setState(() {
                                                          uploaded = true;
                                                          laporanData['setor'] =
                                                              setorItems;
                                                          laporanData[
                                                                  'sudahSetor'] =
                                                              true;
                                                          updateLaporanData();

                                                          Navigator.pushAndRemoveUntil(
                                                              context,
                                                              MaterialPageRoute(
                                                                  builder:
                                                                      (context) =>
                                                                          MainMenu()),
                                                              (route) => false);
                                                        });
                                                      },
                                                      child: Text('Ya'))
                                                ],
                                              );
                                            },
                                          )
                                        : SizedBox.shrink();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(16),
                                    child: Text(
                                      (checkEmptyField() == false)
                                          ? 'Kirim Laporan'
                                          : 'Belum Lengkap',
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
                            : (uploaded == true)
                                ? Card(
                                    color: Theme.of(context).primaryColor,
                                    elevation: 2,
                                    margin: const EdgeInsets.all(16),
                                    child: InkWell(
                                      onTap: () {},
                                      child: Container(
                                        padding: const EdgeInsets.all(16),
                                        child: Text(
                                          'Terkirim',
                                          textAlign: TextAlign.center,
                                          style: (Theme.of(context)
                                                      .brightness ==
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
      ),
    );
  }

  String formatPrice(num price) {
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

class ThousandsSeparatorDigitsOnlyInputFormatter extends TextInputFormatter {
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    if (newValue.selection.baseOffset == 0) {
      return newValue;
    }

    final String parsedValue = newValue.text.replaceAll(',', '');
    final String formattedValue =
        NumberFormat('#,###', 'en_US').format(int.parse(parsedValue));

    return TextEditingValue(
      text: formattedValue,
      selection: TextSelection.collapsed(offset: formattedValue.length),
    );
  }
}
