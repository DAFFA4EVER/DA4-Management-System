import 'package:da4_management/backend/keyToken.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import '../../backend/control.dart';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import '../../backend/buktiDataHandlerAndroid.dart';

class LaporanTodayBackupScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String chooseTokoID;

  LaporanTodayBackupScreen(
      {required this.currentdate,
      required this.edit,
      required this.chooseTokoID});

  @override
  _LaporanTodayBackupScreenState createState() =>
      _LaporanTodayBackupScreenState();
}

class _LaporanTodayBackupScreenState extends State<LaporanTodayBackupScreen> {
  final rupiahController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
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

  Future<void> saveDataAsJson() async {
    final jsonData = jsonEncode(laporanData);

    final directory = await getExternalStorageDirectory();
    final backupDirectory = Directory(
        '${directory!.path}/da4 backup/laporan/${widget.chooseTokoID}');

    if (!backupDirectory.existsSync()) {
      backupDirectory.createSync(recursive: true);
    }
    print(directory);
    final file = File(
        '${backupDirectory.path}/report_${widget.chooseTokoID}_${widget.currentdate}_backup.json');

    await file.writeAsString(jsonData);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Data saved as JSON in da4 backup folder')),
    );
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
      setState(() {
        if (available) {
          dataLoaded = true;
        }
      });
    } catch (e) {
      print(e);
    }
  }

  Future<void> showActionDialog(BuildContext context, String option) async {
    final currentContext = context;
    List<String> tokoList = [];
    for (final nameToko in TokoID.tokoID) {
      tokoList.add(nameToko.keys.first);
    }
    return showDialog<void>(
      barrierDismissible: false,
      context: currentContext,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Masukkan password untuk menghapus $option'),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Cancelled'),
                  duration: Duration(seconds: 3),
                ));
              },
              child: Text(
                'Cancel',
                style: TextStyle(),
              ),
            ),
            TextButton(
              child: Text(
                'Hapus',
                style: TextStyle(color: Colors.red),
              ),
              onPressed: () {
                Navigator.of(context).pop();
                String enteredPassword = _passwordController.text;

                if (laporanData['imageData'] == null) {
                  laporanData['imageData'] == true;
                }

                if (option == 'image' &&
                    (enteredPassword == KeyToken.confirm) &&
                    (laporanData['imageData'] == true)) {
                  print('Delete image laporan?');
                  BuktiDataHandlerAndroid.instance
                      .deleteBuktiFolder(currentDate, widget.chooseTokoID);
                  laporanData['imageData'] = false;
                  LaporanDatabaseHandlerFirestore.instance
                      .saveLaporanToFirestore(
                          laporanData, currentDate, widget.chooseTokoID);

                  setState(() {
                    dataLoaded = false;
                    checkLaporanExist();
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Delete image laporan success'),
                      duration: Duration(seconds: 3),
                    ));
                    Navigator.pop(context);
                  });
                } else if (option == 'laporan' &&
                    (enteredPassword == KeyToken.confirm)) {
                  print('Delete laporan?');
                  BuktiDataHandlerAndroid.instance
                      .deleteBuktiFolder(currentDate, widget.chooseTokoID);
                  LaporanDatabaseHandlerFirestore.instance
                      .deleteLaporan(currentDate, widget.chooseTokoID);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Delete laporan success'),
                    duration: Duration(seconds: 3),
                  ));
                  Navigator.pop(context);
                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text('Wrong password'),
                    duration: Duration(seconds: 3),
                  ));
                }
              },
            ),
          ],
        );
      },
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
                ? PopupMenuButton<String>(
                    icon:
                        Icon(Icons.more_vert), // This is the icon of the button
                    onSelected: (String result) async {
                      switch (result) {
                        case 'Copy':
                          Clipboard.setData(
                              ClipboardData(text: jsonEncode(laporanData)));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Copied to clipboard')),
                          );
                          break;
                        case 'Hapus Laporan':
                          await showActionDialog(context, 'laporan');

                          break;
                        case 'Hapus Foto':
                          await showActionDialog(context, 'image');

                          // Handle the 'Hapus Foto' option here
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                      PopupMenuItem<String>(
                        value: 'Copy',
                        child: Text('Copy'),
                      ),
                      PopupMenuItem<String>(
                        value: 'Hapus Laporan',
                        child: Text('Hapus Laporan'),
                      ),
                      PopupMenuItem<String>(
                        value: 'Hapus Foto',
                        child: Text('Hapus Foto'),
                      ),
                    ],
                  )
                : SizedBox.shrink(),
          ],
          title: const Text('Laporan Data'),
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
                : ListView(children: [
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
                          'Toko',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Text(
                          widget.chooseTokoID,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      color: Colors.black,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: SelectableText(jsonEncode(laporanData),
                            style: TextStyle(color: Colors.white)),
                      ),
                    )
                  ]),
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
