import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/gudangDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:html' as html;

class GudangLaporanBackupScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String namaGudang;

  GudangLaporanBackupScreen(
      {required this.currentdate,
      required this.edit,
      required this.namaGudang});

  @override
  _GudangLaporanBackupScreenState createState() =>
      _GudangLaporanBackupScreenState();
}

class _GudangLaporanBackupScreenState extends State<GudangLaporanBackupScreen> {
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

      setState(() {
        dataLoaded = true;
      });
    } catch (e) {
      //laporanGudangData = laporanHelper.laporanGudangTemplate(currentDate);
    }
  }

  Future<void> saveDataAsJson() async {
    final jsonData = jsonEncode(laporanGudangData);

    final blob = html.Blob([jsonData]);
    final blobUrl = html.Url.createObjectUrlFromBlob(blob);

    final anchor = html.AnchorElement(href: blobUrl)
      ..target = 'blank'
      ..download = 'report_gudang_${widget.currentdate}_backup.json'
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
                      Clipboard.setData(
                          ClipboardData(text: jsonEncode(laporanGudangData)));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Copied to clipboard')),
                      );
                    },
                  )
                : SizedBox.shrink(),
          ],
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
                        widget.currentdate,
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
                        widget.namaGudang,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.all(16),
                    color: Colors.black,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: SelectableText(jsonEncode(laporanGudangData), style: TextStyle(color: Colors.white)),
                    ),
                  )
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
