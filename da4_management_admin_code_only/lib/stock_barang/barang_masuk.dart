import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'select_stock_gudang.dart' as SelectStock;
import '../backend/gudangDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../backend/buktiDataHandlerAndroid.dart';
import 'temp_selection.dart';

class GudangMasukScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String namaGudang;

  GudangMasukScreen(
      {required this.currentdate,
      required this.edit,
      required this.namaGudang});

  @override
  _GudangMasukScreenState createState() => _GudangMasukScreenState();
}

class _GudangMasukScreenState extends State<GudangMasukScreen> {
  final rupiahController = TextEditingController();
  List<Map<String, dynamic>> buktiSOItem = [];
  List<Map<String, dynamic>> buktiBayarSOItem = [];
  List<Map<String, dynamic>> buktiBarangMasukItem = [];
  List<Map<String, dynamic>> barangMasukStockItems = [];
  final laporanHelper = GudangLaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> laporanGudangMasukData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  bool dataLoaded = false;
  String previousDate = '';

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    if (widget.currentdate == '') {
      currentDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      currentDate = widget.currentdate;
    }
    //currentDate = '2023-07-18';
    canEdit = widget.edit;
    checkLaporanExist();
  }

  String? imagePath;
  String? imageName;

  Future<bool> pickImage(int index, String method) async {
    try {
      var pickedImage =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (pickedImage == null) return false;

      final imageName = pickedImage.name;
      final imageFile = File(pickedImage.path);
      final firestorageURL = await BuktiDataHandlerAndroid.instance
          .uploadImageURL(imageFile, currentDate, widget.namaGudang);
      if (method == 'SO') {
        setState(() {
          buktiSOItem[index]['tanggal'] = currentDate;
          buktiSOItem[index]['photo'] = pickedImage!.path;
          buktiSOItem[index]['imageName'] = imageName;
          buktiSOItem[index]['firestorage'] = firestorageURL;
        });
      } else if (method == 'bayar') {
        setState(() {
          buktiBayarSOItem[index]['tanggal'] = currentDate;
          buktiBayarSOItem[index]['photo'] = pickedImage!.path;
          buktiBayarSOItem[index]['imageName'] = imageName;
          buktiBayarSOItem[index]['firestorage'] = firestorageURL;
        });
      } else {
        // masuk
        setState(() {
          buktiBarangMasukItem[index]['tanggal'] = currentDate;
          buktiBarangMasukItem[index]['photo'] = pickedImage!.path;
          buktiBarangMasukItem[index]['imageName'] = imageName;
          buktiBarangMasukItem[index]['firestorage'] = firestorageURL;
        });
      }
    } on PlatformException catch (e) {
      print('Error picking image: $e');
    }
    return true;
  }

  void navigateToSelectStockScreen() async {
    if (canEdit) {
      tempSelection.updateData(barangMasukStockItems);

      await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) => SelectStock.SelectStockGudangScreen()),
      );
      setState(() {
        barangMasukStockItems = tempSelection.getData();

        updatelaporanGudangData();
      });
    }
  }

  Future<String> getPreviousStock() async {
    List<String> availableDate = [];
    final gudangList = await GudangLaporanDatabaseHandlerFirestore.instance
        .getLaporanGudangList();

    for (final item in gudangList) {
      String selectedDate = item.substring(
        item.lastIndexOf("_") + 1,
      );
      availableDate.add(selectedDate);
    }
    if (currentDate == availableDate.last) {
      print("X1");
      return availableDate[availableDate.length - 2];
    } else {
      print("X2");
      if (availableDate.contains(currentDate) == false) {
        print("X3");
        return availableDate.last;
      } else {
        print("X4");
        return DateFormat('yyyy-MM-dd')
            .format(DateTime.parse(currentDate).subtract(Duration(days: 1)))
            .toString();
      }
    }
  }

  Future<void> checkLaporanExist() async {
    try {
      if (await laporanHelper.checkLaporanGudangExist(currentDate) == false) {
        if (canEdit) {
          laporanGudangMasukData =
              laporanHelper.laporanGudangTemplate(currentDate);
        }
      } else {
        laporanGudangMasukData =
            await laporanHelper.loadLaporanGudangFromFirestore(currentDate);
      }

      previousDate = await getPreviousStock();
      print(previousDate);
      print(await laporanHelper.checkLaporanGudangExist(currentDate));
      if ((await laporanHelper.checkLaporanGudangExist(currentDate) == true) &&
          laporanGudangMasukData['stokGudang'].isNotEmpty) {
        print("B");
        barangMasukStockItems =
            List<Map<String, dynamic>>.from(laporanGudangMasukData['stokGudang']);
        print("C");
      } else {
        print("D");
        Map<String, dynamic> laporanGudangYesterdayData =
            await laporanHelper.loadLaporanGudangFromFirestore(previousDate);
        barangMasukStockItems = List<Map<String, dynamic>>.from(
            laporanGudangYesterdayData['stokGudang']);
      }

      barangMasukStockItems = List<Map<String, dynamic>>.from(
          laporanGudangMasukData['barangMasuk']);

      //
      //laporanGudangMasukData['uploaded'] = false;
      if (laporanGudangMasukData['uploaded'] == true) {
        canEdit = false;
      }

      setState(() {
        tokoNama = laporanGudangMasukData['namaToko'];
        tanggal = laporanGudangMasukData['date'];

        //
        buktiSOItem =
            List<Map<String, dynamic>>.from(laporanGudangMasukData['strukSO']);
        buktiBarangMasukItem = List<Map<String, dynamic>>.from(
            laporanGudangMasukData['buktiMasuk']);
        buktiBayarSOItem = List<Map<String, dynamic>>.from(
            laporanGudangMasukData['buktiBayar']);
        dataLoaded = true;
      });
    } catch (e) {
      print(e);
    }
  }

  bool checkEmptyField() {
    // stok masuk
    kosongMessage = 'Anda yakin ingin keluar?';
    if (barangMasukStockItems.isNotEmpty) {
      // bukti masuk
      if (buktiBarangMasukItem.isEmpty) {
        kosongMessage = 'Data bukti barang masuk belum lengkap';
        return true;
      }
      if (buktiBarangMasukItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['keterangan'] == '')) {
        kosongMessage = 'Data bukti barang masuk belum lengkap';
        return true;
      }
      // bukti so
      if (buktiSOItem.isEmpty) {
        kosongMessage = 'Data bukti SO belum lengkap';
        return true;
      }
      if (buktiSOItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['harga'] == '')) {
        kosongMessage = 'Data bukti SO belum lengkap';
        return true;
      }
      // bukti bayar
      if (buktiBayarSOItem.isEmpty) {
        kosongMessage = 'Data bukti pembayaran SO belum lengkap';
        return true;
      }

      if (buktiBayarSOItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['harga'] == '')) {
        kosongMessage = 'Data bukti pembayaran SO belum lengkap';
        return true;
      }
    }
    return false;
  }

  void updatelaporanGudangData() {
    if (canEdit) {
      // Stock Masuk
      for (final selectedItem in barangMasukStockItems) {
        final String itemName = selectedItem['id'];
        final existingItemIndex =
            laporanGudangMasukData['barangMasuk'].indexWhere(
          (item) => item['id'] == itemName,
        );
        if (existingItemIndex != -1) {
          laporanGudangMasukData['barangMasuk'][existingItemIndex]['quantity'] =
              selectedItem['quantity'];
        } else {
          laporanGudangMasukData['barangMasuk'].add(selectedItem);
        }
      }

      laporanGudangMasukData['barangMasuk'].removeWhere(
        (item) => !barangMasukStockItems
            .any((selectedItem) => selectedItem['id'] == item['id']),
      );

      // Remove items with quantity 0
      laporanGudangMasukData['barangMasuk'].removeWhere(
        (item) => item['quantity'] == 0,
      );

      if (laporanGudangMasukData['barangMasuk'] == null) {
        laporanGudangMasukData['barangMasuk'] = [];
      }

      laporanGudangMasukData['strukSO'] = buktiSOItem;
      laporanGudangMasukData['buktiMasuk'] = buktiBarangMasukItem;
      laporanGudangMasukData['buktiBayar'] = buktiBayarSOItem;
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (checkEmptyField()) {
          if ((canEdit && dataLoaded)) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: Text('Masih Kosong'),
                  content: Text(kosongMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the dialog
                      },
                      child: const Text('Tetap'),
                    ),
                    TextButton(
                      onPressed: () {
                        updatelaporanGudangData();
                        laporanHelper.saveLaporanGudangToFirestore(
                            laporanGudangMasukData, currentDate);

                        Navigator.pop(context);
                        Navigator.pop(context); // Close the dialog
                        // Code to be executed after the delay
                      },
                      child: const Text('Keluar'),
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

                      updatelaporanGudangData();
                      laporanHelper.saveLaporanGudangToFirestore(
                          laporanGudangMasukData, currentDate);
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
          title: const Text('Barang Masuk'),
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
                        'Gudang',
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

                  // Barang Masuk di gudang
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Barang Masuk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: barangMasukStockItems.length,
                          itemBuilder: (context, index) {
                            final stock = barangMasukStockItems[index];
                            final quantity = stock['quantity'] ?? 0;
                            return Card(
                              child: ListTile(
                                title: Text(stock['nama']),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("${stock['unit']} (${stock['qty']})"),
                                    Text(formatPrice(stock['price'])),
                                  ],
                                ),
                                trailing: SizedBox(
                                  width: 60,
                                  child: TextFormField(
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    enabled: (canEdit && dataLoaded),
                                    initialValue: '$quantity',
                                    style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold),
                                    textAlign: TextAlign.center,
                                    decoration: InputDecoration(
                                      contentPadding: const EdgeInsets.all(8),
                                      border: OutlineInputBorder(
                                        borderRadius:
                                            BorderRadius.circular(10.0),
                                      ),
                                    ),
                                    onChanged: (value) {
                                      setState(() {
                                        stock['quantity'] =
                                            int.tryParse(value) ?? 0;
                                        updatelaporanGudangData();
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
                  // Bukti Masuk
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Bukti Barang Masuk',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: buktiBarangMasukItem.length,
                          itemBuilder: (context, index) {
                            final itemBuktiMasuk =
                                buktiBarangMasukItem[index] ??
                                    {}; // Initialize with an empty map if null
                            final TextEditingController namaController =
                                TextEditingController(
                                    text: itemBuktiMasuk['nama']);
                            final TextEditingController keteranganController =
                                TextEditingController(
                                    text: itemBuktiMasuk['keterangan']);
                            final String photo = itemBuktiMasuk['photo'] ?? '';

                            return Card(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: namaController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Penanggung Jawab',
                                      ),
                                      onChanged: (value) {
                                        itemBuktiMasuk['nama'] = value;
                                        updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: keteranganController,
                                      decoration: const InputDecoration(
                                        labelText: 'Keterangan',
                                      ),
                                      onChanged: (value) {
                                        itemBuktiMasuk['keterangan'] = value;
                                        updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  if (photo.isNotEmpty) ...[
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
                                                itemBuktiMasuk['imageName'],
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
                                                    itemBuktiMasuk['imageName'],
                                                    widget.namaGudang);
                                        if (imageData != null) {
                                          hideLoadingOverlay(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: Container(
                                                    child: Image.memory(
                                                        imageData)),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Close'))
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
                                                          itemBuktiMasuk[
                                                              'imageName'],
                                                          widget.namaGudang);
                                                  setState(() {
                                                    itemBuktiMasuk['photo'] =
                                                        '';
                                                    itemBuktiMasuk[
                                                        'imageName'] = '';
                                                    itemBuktiMasuk[
                                                        'firestorage'] = '';
                                                    itemBuktiMasuk['tanggal'] =
                                                        '';
                                                    updatelaporanGudangData();
                                                    // Save the updated data
                                                    laporanHelper
                                                        .saveLaporanGudangToFirestore(
                                                      laporanGudangMasukData,
                                                      currentDate,
                                                    );
                                                  });
                                                },
                                                icon: const Icon(Icons.cancel),
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
                                                        itemBuktiMasuk[
                                                            'imageName'],
                                                        widget.namaGudang);
                                                setState(() {
                                                  buktiBarangMasukItem
                                                      .removeAt(index);
                                                  updatelaporanGudangData();
                                                  // Save the updated data
                                                  laporanHelper
                                                      .saveLaporanGudangToFirestore(
                                                    laporanGudangMasukData,
                                                    currentDate,
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                  Icons.delete_forever),
                                            )
                                          : SizedBox.shrink(),
                                      (canEdit && dataLoaded)
                                          ? IconButton(
                                              icon: Icon((itemBuktiMasuk[
                                                              'photo'] ==
                                                          '' &&
                                                      itemBuktiMasuk[
                                                              'imageName'] ==
                                                          '')
                                                  ? Icons.add_photo_alternate
                                                  : Icons.change_circle),
                                              onPressed: () async {
                                                showLoadingOverlay(context);
                                                bool status = await pickImage(
                                                    index, 'masuk');
                                                if (status || !status) {
                                                  hideLoadingOverlay(context);
                                                }
                                                updatelaporanGudangData();
                                                // Save the updated data
                                                laporanHelper
                                                    .saveLaporanGudangToFirestore(
                                                  laporanGudangMasukData,
                                                  currentDate,
                                                );
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
                        (canEdit &&
                                barangMasukStockItems.isNotEmpty &&
                                dataLoaded)
                            ? ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    buktiBarangMasukItem.add({
                                      'nama': '',
                                      'jumlah': null,
                                      'photo': '',
                                      'imageName': '',
                                      'firestorage': '',
                                      'tanggal': '',
                                    });
                                  });
                                },
                                child: const Icon(Icons.add),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  // Bukti SO
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Bukti SO',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: buktiSOItem.length,
                          itemBuilder: (context, index) {
                            final itemBuktiSO = buktiSOItem[index] ??
                                {}; // Initialize with an empty map if null
                            final TextEditingController namaController =
                                TextEditingController(
                                    text: itemBuktiSO['nama']);
                            final TextEditingController jumlahController =
                                TextEditingController(
                                    text: itemBuktiSO['jumlah']?.toString() ??
                                        null);
                            final String photo = itemBuktiSO['photo'] ?? '';

                            return Card(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: namaController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Nama SO',
                                      ),
                                      onChanged: (value) {
                                        itemBuktiSO['nama'] = value;
                                        updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: jumlahController,
                                      inputFormatters: [
                                        ThousandsSeparatorDigitsOnlyInputFormatter(), //FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Total Harga (Rupiah)',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        final parsedValue =
                                            value.replaceAll(',', '');
                                        final intValue =
                                            int.tryParse(parsedValue) ?? 0;
                                        itemBuktiSO['jumlah'] = intValue;
                                        updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  if (photo.isNotEmpty) ...[
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
                                                itemBuktiSO['imageName'],
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
                                                    itemBuktiSO['imageName'],
                                                    widget.namaGudang);
                                        if (imageData != null) {
                                          hideLoadingOverlay(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: Container(
                                                    child: Image.memory(
                                                        imageData)),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Close'))
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
                                                          itemBuktiSO[
                                                              'imageName'],
                                                          widget.namaGudang);
                                                  setState(() {
                                                    itemBuktiSO['photo'] = '';
                                                    itemBuktiSO['imageName'] =
                                                        '';
                                                    itemBuktiSO['firestorage'] =
                                                        '';
                                                    itemBuktiSO['tanggal'] = '';
                                                    updatelaporanGudangData();
                                                    // Save the updated data
                                                    laporanHelper
                                                        .saveLaporanGudangToFirestore(
                                                      laporanGudangMasukData,
                                                      currentDate,
                                                    );
                                                  });
                                                },
                                                icon: const Icon(Icons.cancel),
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
                                                        itemBuktiSO[
                                                            'imageName'],
                                                        widget.namaGudang);
                                                setState(() {
                                                  buktiSOItem.removeAt(index);
                                                  updatelaporanGudangData();
                                                  // Save the updated data
                                                  laporanHelper
                                                      .saveLaporanGudangToFirestore(
                                                    laporanGudangMasukData,
                                                    currentDate,
                                                  );
                                                });
                                              },
                                              icon: const Icon(
                                                  Icons.delete_forever),
                                            )
                                          : SizedBox.shrink(),
                                      (canEdit && dataLoaded)
                                          ? IconButton(
                                              icon: Icon((itemBuktiSO[
                                                              'photo'] ==
                                                          '' &&
                                                      itemBuktiSO[
                                                              'imageName'] ==
                                                          '')
                                                  ? Icons.add_photo_alternate
                                                  : Icons.change_circle),
                                              onPressed: () async {
                                                showLoadingOverlay(context);
                                                bool status = await pickImage(
                                                    index, 'SO');
                                                if (status || !status) {
                                                  hideLoadingOverlay(context);
                                                }
                                                updatelaporanGudangData();
                                                // Save the updated data
                                                laporanHelper
                                                    .saveLaporanGudangToFirestore(
                                                  laporanGudangMasukData,
                                                  currentDate,
                                                );
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
                        (canEdit &&
                                barangMasukStockItems.isNotEmpty &&
                                dataLoaded)
                            ? ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    buktiSOItem.add({
                                      'nama': '',
                                      'jumlah': null,
                                      'photo': '',
                                      'imageName': '',
                                      'firestorage': '',
                                      'tanggal': '',
                                    });
                                  });
                                },
                                child: const Icon(Icons.add),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
                  // Bukti Bayar
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Bukti Bayar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: buktiBayarSOItem.length,
                          itemBuilder: (context, index) {
                            final itemBayarSO = buktiBayarSOItem[index] ??
                                {}; // Initialize with an empty map if null
                            final TextEditingController namaController =
                                TextEditingController(
                                    text: itemBayarSO['nama']);
                            final TextEditingController jumlahController =
                                TextEditingController(
                                    text: itemBayarSO['jumlah']?.toString() ??
                                        null);
                            final String photo = itemBayarSO['photo'] ?? '';

                            return Card(
                              child: Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: namaController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Penanggung Jawab',
                                      ),
                                      onChanged: (value) {
                                        itemBayarSO['nama'] = value;
                                        updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: jumlahController,
                                      inputFormatters: [
                                        ThousandsSeparatorDigitsOnlyInputFormatter(), //FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: const InputDecoration(
                                        labelText: 'Total Harga (Rupiah)',
                                      ),
                                      keyboardType: TextInputType.number,
                                      onChanged: (value) {
                                        final parsedValue =
                                            value.replaceAll(',', '');
                                        final intValue =
                                            int.tryParse(parsedValue) ?? 0;
                                        itemBayarSO['jumlah'] = intValue;
                                        updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  if (photo.isNotEmpty) ...[
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
                                                itemBayarSO['imageName'],
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
                                                    itemBayarSO['imageName'],
                                                    widget.namaGudang);
                                        if (imageData != null) {
                                          hideLoadingOverlay(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: Container(
                                                    child: Image.memory(
                                                        imageData)),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Close'))
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
                                                          itemBayarSO[
                                                              'imageName'],
                                                          widget.namaGudang);
                                                  setState(() {
                                                    itemBayarSO['photo'] = '';
                                                    itemBayarSO['imageName'] =
                                                        '';
                                                    itemBayarSO['firestorage'] =
                                                        '';
                                                    itemBayarSO['tanggal'] = '';
                                                    updatelaporanGudangData();

                                                    // Save the updated data
                                                    laporanHelper
                                                        .saveLaporanGudangToFirestore(
                                                            laporanGudangMasukData,
                                                            currentDate);
                                                  });
                                                },
                                                icon: const Icon(Icons.cancel),
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
                                                        itemBayarSO[
                                                            'imageName'],
                                                        widget.namaGudang);
                                                setState(() {
                                                  buktiBayarSOItem
                                                      .removeAt(index);
                                                  updatelaporanGudangData();

                                                  // Save the updated data
                                                  laporanHelper
                                                      .saveLaporanGudangToFirestore(
                                                          laporanGudangMasukData,
                                                          currentDate);
                                                });
                                              },
                                              icon: const Icon(
                                                  Icons.delete_forever),
                                            )
                                          : SizedBox.shrink(),
                                      (canEdit && dataLoaded)
                                          ? IconButton(
                                              icon: Icon((itemBayarSO[
                                                              'photo'] ==
                                                          '' &&
                                                      itemBayarSO[
                                                              'imageName'] ==
                                                          '')
                                                  ? Icons.add_photo_alternate
                                                  : Icons.change_circle),
                                              onPressed: () async {
                                                showLoadingOverlay(context);
                                                bool status = await pickImage(
                                                    index, 'bayar');
                                                if (status || !status) {
                                                  hideLoadingOverlay(context);
                                                }
                                                updatelaporanGudangData();

                                                // Save the updated data
                                                laporanHelper
                                                    .saveLaporanGudangToFirestore(
                                                  laporanGudangMasukData,
                                                  currentDate,
                                                );
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
                        (canEdit &&
                                barangMasukStockItems.isNotEmpty &&
                                dataLoaded)
                            ? ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    buktiBayarSOItem.add({
                                      'nama': '',
                                      'jumlah': null,
                                      'photo': '',
                                      'imageName': '',
                                      'firestorage': '',
                                      'tanggal': ''
                                    });
                                  });
                                },
                                child: const Icon(Icons.add),
                              )
                            : const SizedBox.shrink(),
                      ],
                    ),
                  ),
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
