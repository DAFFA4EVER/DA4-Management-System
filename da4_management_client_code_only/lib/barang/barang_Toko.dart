import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/services.dart';

class GudangTokoScreen extends StatefulWidget {
  final String currentdate;

  GudangTokoScreen({required this.currentdate});

  @override
  _GudangTokoScreenState createState() => _GudangTokoScreenState();
}

class _GudangTokoScreenState extends State<GudangTokoScreen> {
  String? selectedPenanggungJawab;
  List<String> penanggungJawabList = [];
  List<Map<String, dynamic>> absenItems = [];
  List<Map<String, dynamic>> selectedStockItems = [];
  final laporanHelper = LaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> laporanData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  DateTime yesterday = DateTime.now().subtract(Duration(days: 1));
  bool uploaded = false;
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

    canEdit = false;
    checkLaporanExist();
  }

  Future<String> getPreviousStock() async {
    List<String> availableDate = [];
    final gudangList = await laporanHelper.getLaporanList();

    for (final item in gudangList) {
      String selectedDate = item.substring(
        item.lastIndexOf("_") + 1,
      );
      availableDate.add(selectedDate);
    }
   if (currentDate == availableDate.last) {
      return availableDate[availableDate.length - 2];
    } else {
      return DateTime.parse(currentDate).subtract(Duration(days: 1)).toString();
    }
  }

  Future<void> checkLaporanExist() async {
    
    try {
      if (await laporanHelper.checkLaporanExist(currentDate) == false) {
        laporanData = laporanHelper.laporanTemplate(currentDate);
      } else {
        laporanData = await laporanHelper.loadLaporanFromFirestore(currentDate);
      }
      previousDate = await getPreviousStock();
      if (await laporanHelper.checkLaporanExist(currentDate) == false) {
        if (canEdit) {
          print('Today Not Exist');
          Map<String, dynamic> laporanTokoYesterdayData =
              await laporanHelper.loadLaporanFromFirestore(previousDate);
          selectedStockItems = laporanTokoYesterdayData['stokToko'];

          tanggal = laporanTokoYesterdayData['date'];
        }
      } else {
        print('Today Exist');

        selectedStockItems =
            List<Map<String, dynamic>>.from(laporanData['stokToko']);

        tanggal = laporanData['date'];
      }

      selectedStockItems =
          List<Map<String, dynamic>>.from(laporanData['stokToko']);

      canEdit = false;

      setState(() {
        tokoNama = laporanData['namaToko'];

        absenItems = List<Map<String, dynamic>>.from(laporanData['absen']);
        dataLoaded = true;
      });
    } catch (e) {
      laporanData = laporanHelper.laporanTemplate(currentDate);
    }
  }

  void getListJawab() {
    penanggungJawabList = absenItems
        .where((item) => item['shift'] == 'Shift 2')
        .map((item) => item['nama'])
        .toList()
        .map((dynamic value) => value.toString())
        .toList();

    if (penanggungJawabList.isEmpty) {
      penanggungJawabList.add('Belum absen');
    }

    selectedPenanggungJawab = penanggungJawabList[0];
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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
                      laporanHelper.saveLaporanToFirestore(
                          laporanData, currentDate);
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

                      laporanHelper.saveLaporanToFirestore(
                          laporanData, currentDate);
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
          title: const Text('Persediaan Stock Toko'),
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
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    enabled: canEdit,
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
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
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
