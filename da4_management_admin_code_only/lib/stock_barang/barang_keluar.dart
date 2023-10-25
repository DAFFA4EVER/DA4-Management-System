import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/gudangDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../backend/buktiDataHandlerAndroid.dart';

class GudangKeluarScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String namaGudang;

  GudangKeluarScreen(
      {required this.currentdate,
      required this.edit,
      required this.namaGudang});

  @override
  _GudangKeluarScreenState createState() => _GudangKeluarScreenState();
}

class _GudangKeluarScreenState extends State<GudangKeluarScreen> {
  final rupiahController = TextEditingController();
  List<Map<String, dynamic>> buktiBarangKeluarItem = [];
  List<Map<String, dynamic>> barangGudangStockItems = [];
  List<Map<String, dynamic>> barangKeluarStockItems = [];
  final laporanHelper = GudangLaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> laporanGudangKeluarData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  String previousDate = '';
  bool dataLoaded = false;

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

      buktiBarangKeluarItem[index]['tanggal'] = currentDate;
      buktiBarangKeluarItem[index]['photo'] = pickedImage!.path;
      buktiBarangKeluarItem[index]['imageName'] = imageName;
      buktiBarangKeluarItem[index]['firestorage'] = firestorageURL;
    } on PlatformException catch (e) {
      print('Error picking image: $e');
    }
    return true;
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
          laporanGudangKeluarData =
              laporanHelper.laporanGudangTemplate(currentDate);
        }
      } else {
        laporanGudangKeluarData =
            await laporanHelper.loadLaporanGudangFromFirestore(currentDate);
      }
      // get yesterday stock
      previousDate = await getPreviousStock();
      print(previousDate);
      print(await laporanHelper.checkLaporanGudangExist(currentDate));
      if ((await laporanHelper.checkLaporanGudangExist(currentDate) == true) &&
          laporanGudangKeluarData['stokGudang'].isNotEmpty) {
        barangGudangStockItems = List<Map<String, dynamic>>.from(
            laporanGudangKeluarData['stokGudang']);
        print("C");
      } else {
        print("D");
        Map<String, dynamic> laporanGudangYesterdayData =
            await laporanHelper.loadLaporanGudangFromFirestore(previousDate);
        barangGudangStockItems = List<Map<String, dynamic>>.from(
            laporanGudangYesterdayData['stokGudang']);
      }

      setState(() {
        tokoNama = laporanGudangKeluarData['namaToko'];
        tanggal = laporanGudangKeluarData['date'];

        buktiBarangKeluarItem = List<Map<String, dynamic>>.from(
            laporanGudangKeluarData['buktiKeluar']);

        getCurrentGudangStokList();
        dataLoaded = true;
      });
    } catch (e) {
      print(e);
    }
  }

  bool checkEmptyField() {
    // stok keluar
    kosongMessage = 'Anda yakin ingin keluar?';
    if (barangKeluarStockItems.isNotEmpty) {
      // bukti keluar
      if (buktiBarangKeluarItem.isEmpty) {
        kosongMessage = 'Data bukti keluar belum lengkap';
        return true;
      }
      if (buktiBarangKeluarItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['keterangan'] == '')) {
        kosongMessage = 'Data bukti keluar belum lengkap';
        return true;
      }
    }
    return false;
  }

  void updatelaporanGudangData() {
    if (canEdit) {
      // Stock Keluar
      for (final selectedItem in barangKeluarStockItems) {
        final String itemName = selectedItem['id'];
        final existingItemIndex =
            laporanGudangKeluarData['barangKeluar'].indexWhere(
          (item) => item['id'] == itemName,
        );
        if (existingItemIndex != -1) {
          laporanGudangKeluarData['barangKeluar'][existingItemIndex]
                  ['quantity'] =
              laporanGudangKeluarData['barangKeluar'][existingItemIndex]
                  ['quantity'];
        } else {
          laporanGudangKeluarData['barangKeluar'].add(selectedItem);
        }
      }

      laporanGudangKeluarData['barangKeluar'].removeWhere(
        (item) => !barangKeluarStockItems
            .any((selectedItem) => selectedItem['id'] == item['id']),
      );

      // Remove items with quantity 0
      laporanGudangKeluarData['barangKeluar'].removeWhere(
        (item) => item['quantity'] == 0,
      );
      if (laporanGudangKeluarData['barangKeluar'] == null) {
        laporanGudangKeluarData['barangKeluar'] = [];
      }
      laporanGudangKeluarData['buktiKeluar'] = buktiBarangKeluarItem;
    }
  }

  void getCurrentGudangStokList() {
    try {
      List<Map<String, dynamic>> lastStock = [];
      // get stok gudang
      for (final selectedItem in barangGudangStockItems) {
        if (selectedItem['quantity'] != 0) {
          lastStock.add(selectedItem);
        }
      }

      // get stok barang masuk
      for (final selectedItem in laporanGudangKeluarData['barangMasuk']) {
        final String itemName = selectedItem['id'];
        final existingItemIndex = lastStock.indexWhere(
          (item) => item['id'] == itemName,
        );

        if ((existingItemIndex == -1) && (selectedItem['quantity'] != 0)) {
          lastStock.add(selectedItem);
        }
      }

      // update keluar barang place holder
      for (final selectedItem in lastStock) {
        final String itemName = selectedItem['id'];
        final existingItemIndex = barangKeluarStockItems.indexWhere(
          (item) => item['id'] == itemName,
        );
        if (existingItemIndex == -1) {
          Map<String, dynamic> inputData = {
            'id': selectedItem['id'],
            'nama': selectedItem['nama'],
            'qty': selectedItem['qty'],
            'unit': selectedItem['unit'],
            'quantity': 0,
            'price': selectedItem['price'],
          };
          barangKeluarStockItems.add(inputData);
        }
      }
      // remove unavailable stok
      barangKeluarStockItems.removeWhere(
        (item) =>
            !lastStock.any((selectedItem) => selectedItem['id'] == item['id']),
      );
    } catch (e) {
      print(e);
    }
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
                            laporanGudangKeluarData, currentDate);
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
                          laporanGudangKeluarData, currentDate);
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
          title: const Text('Barang Keluar'),
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

                  // Barang Keluar di gudang
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Barang Keluar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: barangKeluarStockItems.length,
                          itemBuilder: (context, index) {
                            final stock = barangKeluarStockItems[index];
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
                      ],
                    ),
                  ),
                  // Bukti Keluar
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Bukti Barang Keluar',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: buktiBarangKeluarItem.length,
                          itemBuilder: (context, index) {
                            final itemBuktiKeluar =
                                buktiBarangKeluarItem[index] ??
                                    {}; // Initialize with an empty map if null
                            final TextEditingController namaController =
                                TextEditingController(
                                    text: itemBuktiKeluar['nama']);
                            final TextEditingController keteranganController =
                                TextEditingController(
                                    text: itemBuktiKeluar['keterangan']);
                            final String photo = itemBuktiKeluar['photo'] ?? '';

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
                                        itemBuktiKeluar['nama'] = value;
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
                                        itemBuktiKeluar['keterangan'] = value;
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
                                                itemBuktiKeluar['imageName'],
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
                                                    itemBuktiKeluar[
                                                        'imageName'],
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
                                                          itemBuktiKeluar[
                                                              'imageName'],
                                                          widget.namaGudang);
                                                  setState(() {
                                                    itemBuktiKeluar['photo'] =
                                                        '';
                                                    itemBuktiKeluar[
                                                        'imageName'] = '';
                                                    itemBuktiKeluar[
                                                        'firestorage'] = '';
                                                    itemBuktiKeluar['tanggal'] =
                                                        '';
                                                    updatelaporanGudangData();
                                                    // Save the updated data
                                                    laporanHelper
                                                        .saveLaporanGudangToFirestore(
                                                      laporanGudangKeluarData,
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
                                                        itemBuktiKeluar[
                                                            'imageName'],
                                                        widget.namaGudang);
                                                setState(() {
                                                  buktiBarangKeluarItem
                                                      .removeAt(index);
                                                  updatelaporanGudangData();
                                                  // Save the updated data
                                                  laporanHelper
                                                      .saveLaporanGudangToFirestore(
                                                    laporanGudangKeluarData,
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
                                              icon: Icon((itemBuktiKeluar[
                                                              'photo'] ==
                                                          '' &&
                                                      itemBuktiKeluar[
                                                              'imageName'] ==
                                                          '')
                                                  ? Icons.add_photo_alternate
                                                  : Icons.change_circle),
                                              onPressed: () async {
                                                showLoadingOverlay(context);
                                                bool status = await pickImage(
                                                    index, 'pengeluaran');
                                                if (status || !status) {
                                                  hideLoadingOverlay(context);
                                                }
                                                updatelaporanGudangData();
                                                setState(() {
                                                  laporanHelper
                                                      .saveLaporanGudangToFirestore(
                                                    laporanGudangKeluarData,
                                                    currentDate,
                                                  );
                                                });
                                                // Save the updated data
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
                        ((canEdit && dataLoaded) &&
                                (barangKeluarStockItems.isNotEmpty))
                            ? ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    buktiBarangKeluarItem.add({
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
