import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/gudangDataHandlerFirestore.dart';
import 'package:flutter/services.dart';

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
    }
    canEdit = widget.edit;
    checkLaporanExist();
  }

  String? imagePath;
  String? imageName;

  Future<String> getPreviousStock() async {
    List<String> availableDate = [];
    final gudangList = await laporanHelper.getLaporanGudangList();

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
      if (await laporanHelper.checkLaporanGudangExist(currentDate) == false) {
        if (canEdit) {
          laporanGudangData = laporanHelper.laporanGudangTemplate(currentDate);
        }
      } else {
        laporanGudangData =
            await laporanHelper.loadLaporanGudangFromFirestore(currentDate);
      }
      // get today stock
      previousDate = await getPreviousStock();
      if (await laporanHelper.checkLaporanGudangExist(currentDate) == false) {
        print('Today Not Exist');
        Map<String, dynamic> laporanGudangYesterdayData =
            await laporanHelper.loadLaporanGudangFromFirestore(previousDate);
        barangGudangStockItems = laporanGudangYesterdayData['stokGudang'];
        tanggal = laporanGudangYesterdayData['date'];
      } else {
        print('Today Exist');

        barangGudangStockItems =
            List<Map<String, dynamic>>.from(laporanGudangData['stokGudang']);
        tanggal = laporanGudangData['date'];
      }

      //
      if (laporanGudangData['uploaded'] == true) {
        canEdit = false;
      }
      setState(() {
        dataLoaded = true;
        tokoNama = laporanGudangData['namaToko'];
      });
    } catch (e) {
      laporanGudangData = laporanHelper.laporanGudangTemplate(currentDate);
    }
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
                title: const Text('Data Error'),
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
          title: const Text('Persediaan Stock Gudang'),
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
                  // Stok Gudang
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Stok Gudang Saat Ini',
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
