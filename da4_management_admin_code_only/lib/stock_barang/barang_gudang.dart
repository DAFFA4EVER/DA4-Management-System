import 'package:da4_management/backend/control.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/gudangDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import '../main_menu.dart';
import '../backend/buktiDataHandlerAndroid.dart';

class GudangLaporanScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String namaGudang;

  GudangLaporanScreen(
      {required this.currentdate,
      required this.edit,
      required this.namaGudang});

  @override
  _GudangLaporanScreenState createState() => _GudangLaporanScreenState();
}

class _GudangLaporanScreenState extends State<GudangLaporanScreen> {
  final rupiahController = TextEditingController();
  final TextEditingController penanggungJawabController =
      TextEditingController();
  List<Map<String, dynamic>> buktiSOItem = [];
  List<Map<String, dynamic>> buktiBayarSOItem = [];
  List<Map<String, dynamic>> buktiBarangMasukItem = [];
  List<Map<String, dynamic>> barangMasukStockItems = [];

  List<Map<String, dynamic>> barangGudangStockItems = [];

  List<Map<String, dynamic>> barangPrediksiStockItems = [];

  List<Map<String, dynamic>> buktiBarangKeluarItem = [];
  List<Map<String, dynamic>> barangKeluarStockItems = [];

  final laporanHelper = GudangLaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> laporanGudangData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String errorMessage = '';
  DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  bool udahUpload = false;
  bool errorStock = false;
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
      //currentDate = '2023-07-18';
    }

    canEdit = widget.edit;
    checkLaporanExist();
  }

  String? imagePath;
  String? imageName;

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
    print(currentDate);
    try {
      if (await laporanHelper.checkLaporanGudangExist(currentDate) == false) {
        print("P1");
        if (canEdit) {
          print("P2");
          laporanGudangData = laporanHelper.laporanGudangTemplate(currentDate);
        }
      } else {
        print("P3");
        laporanGudangData =
            await laporanHelper.loadLaporanGudangFromFirestore(currentDate);
      }
      // get yesterday stock
      previousDate = await getPreviousStock();
      print(previousDate);
      print(await laporanHelper.checkLaporanGudangExist(currentDate));
      if ((await laporanHelper.checkLaporanGudangExist(currentDate) == true) &&
          laporanGudangData['stokGudang'].isNotEmpty) {
        print("B");
        barangGudangStockItems =
            List<Map<String, dynamic>>.from(laporanGudangData['stokGudang']);
        print("C");
      } else {
        print("D");
        Map<String, dynamic> laporanGudangYesterdayData =
            await laporanHelper.loadLaporanGudangFromFirestore(previousDate);
        barangGudangStockItems = List<Map<String, dynamic>>.from(
            laporanGudangYesterdayData['stokGudang']);
      }
      tanggal = laporanGudangData['date'];
      print(tanggal);
      barangMasukStockItems =
          List<Map<String, dynamic>>.from(laporanGudangData['barangMasuk']);

      barangKeluarStockItems =
          List<Map<String, dynamic>>.from(laporanGudangData['barangKeluar']);

      //
      //laporanGudangData['uploaded'] = false;
      if (laporanGudangData['uploaded'] == true) {
        canEdit = false;
        udahUpload = true;
      }
      if (loginState.role == 'superadmin') {
        canEdit = true;
      }
      setState(() {
        tokoNama = laporanGudangData['namaToko'];

        buktiBarangKeluarItem =
            List<Map<String, dynamic>>.from(laporanGudangData['buktiKeluar']);
        //
        buktiSOItem =
            List<Map<String, dynamic>>.from(laporanGudangData['strukSO']);
        buktiBarangMasukItem =
            List<Map<String, dynamic>>.from(laporanGudangData['buktiMasuk']);
        buktiBayarSOItem =
            List<Map<String, dynamic>>.from(laporanGudangData['buktiBayar']);
        predictStokGudang();
        penanggungJawabController.text = laporanGudangData['penanggungJawab'];
        laporanGudangData['adminSession'] = loginState.username;
        dataLoaded = true;
      });
    } catch (e) {
      //laporanGudangData = laporanHelper.laporanGudangTemplate(currentDate);
    }
  }

  bool checkValidField() {
    // Keluar
    if (errorStock == true) {
      errorMessage = 'Permintaan barang keluar tidak valid';
      return true;
    }
    if (barangKeluarStockItems.isNotEmpty) {
      // bukti keluar
      if (buktiBarangKeluarItem.isEmpty) {
        errorMessage = 'Data bukti barang masuk belum lengkap';
        return true;
      }
      if (buktiBarangKeluarItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['keterangan'] == '')) {
        errorMessage = 'Data bukti barang masuk belum lengkap';
        return true;
      }
    }
    // bukti masuk
    if (barangMasukStockItems.isNotEmpty) {
      if (buktiBarangMasukItem.isEmpty) {
        errorMessage = 'Data bukti barang masuk belum lengkap';
        return true;
      }
      if (buktiBarangMasukItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['keterangan'] == '')) {
        errorMessage = 'Data bukti barang masuk belum lengkap';
        return true;
      }
      // bukti so
      if (buktiSOItem.isEmpty) {
        errorMessage = 'Data bukti SO belum lengkap';
        return true;
      }
      if (buktiSOItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['harga'] == '')) {
        errorMessage = 'Data bukti SO belum lengkap';
        return true;
      }
      // bukti bayar
      if (buktiBayarSOItem.isEmpty) {
        errorMessage = 'Data bukti pembayaran SO belum lengkap';
        return true;
      }

      if (buktiBayarSOItem.any((item) =>
          item['photo'] == '' ||
          item['imageName'] == '' ||
          item['nama'] == '' ||
          item['harga'] == '')) {
        errorMessage = 'Data bukti pembayaran SO belum lengkap';
        return true;
      }
    }
    if (laporanGudangData['penanggungJawab'] == '') {
      errorMessage = 'Data penanggung jawab belum lengkap';
      return true;
    }
    return false;
  }

  void predictStokGudang() {
    try {
      // get current stok gudang
      if (udahUpload == false) {
        for (final selectedItem in barangGudangStockItems) {
          Map<String, dynamic> inputData = {
            'id': selectedItem['id'],
            'nama': selectedItem['nama'],
            'qty': selectedItem['qty'],
            'unit': selectedItem['unit'],
            'quantity': selectedItem['quantity'],
            'price': selectedItem['price'],
          };
          barangPrediksiStockItems.add(inputData);
        }

        // add the barang masuk
        for (final selectedItem in barangMasukStockItems) {
          final String itemName = selectedItem['id'];
          final existingItemIndex = barangPrediksiStockItems.indexWhere(
            (item) => item['id'] == itemName,
          );
          if (existingItemIndex == -1) {
            Map<String, dynamic> inputData = {
              'id': selectedItem['id'],
              'nama': selectedItem['nama'],
              'qty': selectedItem['qty'],
              'unit': selectedItem['unit'],
              'quantity': selectedItem['quantity'],
              'price': selectedItem['price'],
            };
            barangPrediksiStockItems.add(inputData);
          } else {
            barangPrediksiStockItems[existingItemIndex]['quantity'] +=
                selectedItem['quantity'];
          }
        }
        if (barangKeluarStockItems.isNotEmpty) {
          // substract the barang keluar
          for (final selectedItem in barangKeluarStockItems) {
            final String itemName = selectedItem['id'];
            final existingItemIndex = barangPrediksiStockItems.indexWhere(
              (item) => item['id'] == itemName,
            );
            if (existingItemIndex == -1) {
              errorStock = true;
            } else {
              barangPrediksiStockItems[existingItemIndex]['quantity'] -=
                  selectedItem['quantity'];
              if (barangPrediksiStockItems[existingItemIndex]['quantity'] < 0) {
                errorStock = true;
              }
            }
          }
        }

        laporanGudangData['prediksi'] =
            List<Map<String, dynamic>>.from(barangPrediksiStockItems);
      }
      barangPrediksiStockItems =
          List<Map<String, dynamic>>.from(laporanGudangData['prediksi']);
    } catch (e) {
      print(e);
      // Handle the exception
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (checkValidField()) {
          if (canEdit) {
            showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  title: const Text('Peringatan'),
                  content: Text(errorMessage),
                  actions: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context); // Close the dialog
                      },
                      child: const Text('Tetap'),
                    ),
                    TextButton(
                      onPressed: () {
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
          title: const Text('Laporan Gudang'),
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
                  // Stock Gudang
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Stock Gudang Saat Ini',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: barangGudangStockItems.length,
                          itemBuilder: (context, index) {
                            final stock = barangGudangStockItems[index];
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
                                    enabled: false,
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
                                        //stock['quantity'] = int.tryParse(value) ?? 0;
                                        //updatelaporanGudangData();
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
                                    enabled: false,
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
                                        //stock['quantity'] = int.tryParse(value) ?? 0;
                                        //updatelaporanGudangData();
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
                  // Barang Keluar
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
                                    enabled: false,
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
                                        //updatelaporanGudangData();
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
                  // Prediksi
                  (laporanGudangData['uploaded'] == false)
                      ? Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 12),
                                child: Text(
                                  'Prediksi Stock Gudang',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: barangPrediksiStockItems.length,
                                itemBuilder: (context, index) {
                                  final stock = barangPrediksiStockItems[index];
                                  final quantity = stock['quantity'] ?? 0;
                                  return Card(
                                    child: ListTile(
                                      title: Text(stock['nama']),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                              "${stock['unit']} (${stock['qty']})"),
                                          Text(formatPrice(stock['price'])),
                                        ],
                                      ),
                                      trailing: SizedBox(
                                        width: 60,
                                        child: TextFormField(
                                          keyboardType: TextInputType.number,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly,
                                          ],
                                          enabled: false,
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
                                              //stock['quantity'] = int.tryParse(value) ?? 0;
                                              //updatelaporanGudangData();
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
                        )
                      : const SizedBox.shrink(),
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
                                      enabled: false,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Penanggung Jawab',
                                      ),
                                      onChanged: (value) {
                                        //itemBuktiMasuk['nama'] = value;
                                        //updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: keteranganController,
                                      enabled: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Keterangan',
                                      ),
                                      onChanged: (value) {
                                        //itemBuktiMasuk['keterangan'] = value;
                                        //updatelaporanGudangData();
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
                                  ],
                                ],
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
                                      enabled: false,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Penanggung Jawab',
                                      ),
                                      onChanged: (value) {
                                        //itemBuktiKeluar['nama'] = value;
                                        //updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      controller: keteranganController,
                                      enabled: false,
                                      decoration: const InputDecoration(
                                        labelText: 'Keterangan',
                                      ),
                                      onChanged: (value) {
                                        //itemBuktiKeluar['keterangan'] = value;
                                        //updatelaporanGudangData();
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
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      enabled: false,
                                      controller: namaController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Nama SO',
                                      ),
                                      onChanged: (value) {
                                        itemBuktiSO['nama'] = value;
                                        //updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Total Harga',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      formatPrice(itemBuktiSO['jumlah']),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
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
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
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
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextField(
                                      enabled: false,
                                      controller: namaController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                        labelText: 'Penanggung Jawab',
                                      ),
                                      onChanged: (value) {
                                        itemBayarSO['nama'] = value;
                                        // updatelaporanGudangData();
                                      },
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      'Total Harga',
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: Text(
                                      formatPrice(itemBayarSO['jumlah']),
                                      style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold),
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
                                  ],
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
                        (udahUpload == false)
                            ? Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: TextField(
                                  controller: penanggungJawabController,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(
                                    labelText: 'Penanggung Jawab',
                                  ),
                                  onChanged: (value) {
                                    laporanGudangData['penanggungJawab'] =
                                        value;
                                    setState(() {});
                                  },
                                ),
                              )
                            : Text(
                                laporanGudangData['penanggungJawab'],
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
                  (laporanGudangData['uploaded'] == false)
                      ? Card(
                          color: Theme.of(context).primaryColor,
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: InkWell(
                            onTap: () {
                              (checkValidField() == false)
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
                                                    udahUpload = false;
                                                    Navigator.pop(context);
                                                  });
                                                },
                                                child: const Text('Tidak')),
                                            TextButton(
                                                onPressed: () {
                                                  setState(() {
                                                    udahUpload = true;
                                                    laporanGudangData[
                                                            'uploaded'] =
                                                        udahUpload;

                                                    laporanGudangData[
                                                            'stokGudang'] =
                                                        barangPrediksiStockItems;

                                                    GudangLaporanDatabaseHandlerFirestore
                                                        .instance
                                                        .saveLaporanGudangToFirestore(
                                                            laporanGudangData,
                                                            currentDate);

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
                                (checkValidField() == false)
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
