//import 'package:benu_management_admin/analisis/detail%20laporan/detail_setor.dart';
import 'package:da4_management_client/analisis/detail%20laporan/detail_pengeluaran.dart';
//import 'package:benu_management_admin/export/pdf_laporanAbsen.dart';
//import 'detail laporan/detail_strukCash.dart';
import 'package:da4_management_client/backend/laporanDataHandlerFirestore.dart';
import 'package:da4_management_client/laporan/list_laporan.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
//import '../laporan/list_laporan_analisis.dart';
import 'detail laporan/detail_menu.dart';
//import 'detail laporan/detail_pemasukan.dart';
//import '../export/pdf_laporanToko.dart';

class PembukuanTokoPointScreen extends StatefulWidget {
  final String chooseTokoID;
  final String chooseTokoName;
  final List<String> listDate;

  PembukuanTokoPointScreen({
    required this.chooseTokoID,
    required this.chooseTokoName,
    required this.listDate,
  });

  @override
  _PembukuanTokoPointScreenState createState() =>
      _PembukuanTokoPointScreenState();
}

class _PembukuanTokoPointScreenState extends State<PembukuanTokoPointScreen> {
  bool dataLoaded = false;
  List<dynamic> tempMenuLaporanData = [];
  List<dynamic> tempPemasukanLaporanData = [];
  List<dynamic> tempPengeluaranLaporanData = [];
  List<dynamic> tempSetorLaporanData = [];
  List<dynamic> tempStrukCashLaporanData = [];
  List<dynamic> tempAbsenLaporanData = [];

  int totalMenuLaporanData = 0;
  int totalPengeluaranLaporanData = 0;
  int totalPemasukanLaporanData = 0;
  int totalCashLaporanData = 0;
  int setorCashLaporanData = 0;
  int totalStrukLaporanData = 0;
  int processProgress = 0;

  @override
  void initState() {
    super.initState();
    pembukuanProcess();
  }

  Future<void> pembukuanProcess() async {
    for (int i = 0; i < widget.listDate.length; i++) {
      // read data from server
      final tempLaporanData = await LaporanDatabaseHandlerFirestore.instance
          .loadLaporanFromFirestore(widget.listDate[i]);
      setState(() {
        processProgress = i;
      });
      // add menu data
      for (final menuItem in tempLaporanData['menu']) {
        final existingIndex = tempMenuLaporanData.indexWhere(
          (item) => item['id'] == menuItem['id'],
        );
        if (existingIndex == -1) {
          Map<String, dynamic> inputData = {
            'id': menuItem['id'],
            'name': menuItem['name'],
            'type': menuItem['type'],
            'beli': menuItem['beli'],
            'jual': menuItem['jual'],
            'quantity': menuItem['quantity'],
          };
          tempMenuLaporanData.add(inputData);
        } else {
          tempMenuLaporanData[existingIndex]['quantity'] +=
              menuItem['quantity'];
        }
      }
      // add pengeluaran data
      for (final pengeluaranItem in tempLaporanData['pengeluaran']) {
        pengeluaranItem['tanggal'] = widget.listDate[i];
        tempPengeluaranLaporanData.add(pengeluaranItem);
        totalPengeluaranLaporanData += pengeluaranItem['jumlah'] as int;
      }

      // add pemasukan data
      for (final pemasukanItem in tempLaporanData['pemasukan external']) {
        pemasukanItem['tanggal'] = widget.listDate[i];
        tempPemasukanLaporanData.add(pemasukanItem);
        totalPemasukanLaporanData += pemasukanItem['jumlah'] as int;
      }
      // add cash data
      /*
      var inputCashData = {
        'cash': tempLaporanData['cash'],
        'tanggal': widget.listDate[i]
      };
      tempCashLaporanData.add(inputCashData);
      */
      /*
      // Absen
      for (final absenItem in tempLaporanData['absen']) {
        absenItem['tanggal'] = widget.listDate[i];
        tempAbsenLaporanData.add(absenItem);
      }
      // struk
      for (final strukItem in tempLaporanData['struk']) {
        strukItem['cash'] = tempLaporanData['cash'];

        strukItem['tanggal'] = widget.listDate[i];
        if (strukItem['jumlah'] == null) {
          strukItem['jumlah'] = '0';
        }
        strukItem['jumlah'] = strukItem['jumlah'].toString();
        if (strukItem['jumlah'].runtimeType != int) {
          totalStrukLaporanData += int.parse(strukItem['jumlah']) ?? 0;
        } else {
          totalStrukLaporanData += strukItem['jumlah'] as int;
        }
        tempStrukCashLaporanData.add(strukItem);
      }
      totalCashLaporanData += tempLaporanData['cash'] as int;

      // add setor data
      for (final setorItem in tempLaporanData['setor']) {
        setorItem['tanggal'] = widget.listDate[i];
        tempSetorLaporanData.add(setorItem);

        if (setorItem['jumlah'].runtimeType == int) {
          setorCashLaporanData += (setorItem['jumlah']) as int;
        } else {
          setorCashLaporanData +=
              int.parse(setorItem['jumlah'].replaceAll(',', '')) as int;
        }
      }
      */
    }
    for (final item in tempMenuLaporanData) {
      totalMenuLaporanData += (item['jual'] * item['quantity']) as int;
    }
    setState(() {
      dataLoaded = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: dataLoaded
          ? InkWell(
              onTap: () => {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => ListLaporanScreen()))
              },
              child: Card(
                color: Theme.of(context).primaryColor,
                elevation: 2,
                margin: const EdgeInsets.all(4),
                child: ListTile(
                  title: Text(
                    'Lihat Detail',
                    textAlign: TextAlign.center,
                    style: (Theme.of(context).brightness == Brightness.dark)
                        ? TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red)
                        : TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white),
                  ),
                  subtitle: Text(
                    'Laporan ${widget.chooseTokoName}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            )
          : Text(''),
      appBar: AppBar(
        /*
        actions: [
          dataLoaded
              ? IconButton(
                  onPressed: () {
                    PembukuanTokoPointPDFScreen(
                            totalStrukLaporanData: totalStrukLaporanData,
                            chooseTokoID: widget.chooseTokoID,
                            chooseTokoName: widget.chooseTokoName,
                            listMenuLaporanData: tempMenuLaporanData,
                            listPemasukanLaporanData: tempPemasukanLaporanData,
                            listPengeluaranLaporanData:
                                tempPengeluaranLaporanData,
                            listStrukCashLaporanData: tempStrukCashLaporanData,
                            listSetorLaporanData: tempSetorLaporanData,
                            totalMenuLaporanData: totalMenuLaporanData,
                            totalPengeluaranLaporanData:
                                totalPengeluaranLaporanData,
                            totalPemasukanLaporanData:
                                totalPemasukanLaporanData,
                            totalCashLaporanData: totalCashLaporanData,
                            setorCashLaporanData: setorCashLaporanData,
                            listDate: widget.listDate)
                        .createPdfAndPrint();
                  },
                  icon: Icon(Icons.print))
              : Text('')
        ],
        */
        title: Text('Pembukuan'),
      ),
      body: dataLoaded
          ? SelectionArea(
              child: Scrollbar(
                child: ListView(
                  children: [
                    Column(
                      children: [
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Jenis Pembukuan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              'Laporan ${widget.chooseTokoName}',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        Row(
                          children: [
                            // Tanggal
                            Expanded(
                              child: Card(
                                elevation: 2,
                                margin: const EdgeInsets.all(4),
                                child: ListTile(
                                  title: const Text(
                                    'Dari\nTanggal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${widget.listDate[0]}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                            Expanded(
                              child: Card(
                                elevation: 2,
                                margin: const EdgeInsets.all(4),
                                child: ListTile(
                                  title: const Text(
                                    'Sampai\nTanggal',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  subtitle: Text(
                                    '${widget.listDate[widget.listDate.length - 1]}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Durasi',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Text(
                              '${widget.listDate.length} Hari',
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                        ),
                        // Penjualan
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Total Penjualan Menu',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatPrice(totalMenuLaporanData),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    MenuDetailScreen(
                                                        selectedMenuItems:
                                                            tempMenuLaporanData)));
                                      },
                                      child: Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold),
                                      )),
                                )
                              ],
                            ),
                          ),
                        ),
                        // Penjualan Struk
                        /*
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Total Penjualan Sesuai Struk',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatPrice(totalStrukLaporanData),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    TokoStrukCashScreen(
                                                      chooseTokoID:
                                                          widget.chooseTokoID,
                                                      strukCashItems:
                                                          tempStrukCashLaporanData,
                                                    )));
                                      },
                                      child: Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold),
                                      )),
                                )
                              ],
                            ),
                          ),
                        ),
                        */
                        // Pemasukkan
                        /*
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Total Pemasukkan',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatPrice(totalPemasukanLaporanData),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: ((context) =>
                                                    TokoPemasukanScreen(
                                                        pemasukanItems:
                                                            tempPemasukanLaporanData,
                                                        chooseTokoID: widget
                                                            .chooseTokoID))));
                                      },
                                      child: Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold),
                                      )),
                                )
                                
                              ],
                            ),
                          ),
                        ),
                        */
                        // Pengeluaran
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Total Pengeluaran',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatPrice(totalPengeluaranLaporanData),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: ((context) =>
                                                    TokoPengeluaranScreen(
                                                        pengeluaranItems:
                                                            tempPengeluaranLaporanData,
                                                        chooseTokoID: widget
                                                            .chooseTokoID))));
                                      },
                                      child: Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold),
                                      )),
                                )
                              ],
                            ),
                          ),
                        ),
                        // Setor
                        /*
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Total Setor',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatPrice(setorCashLaporanData),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: ((context) =>
                                                    TokoSetorScreen(
                                                        setorItems:
                                                            tempSetorLaporanData,
                                                        chooseTokoID: widget
                                                            .chooseTokoID))));
                                      },
                                      child: Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold),
                                      )),
                                )
                              ],
                            ),
                          ),
                        ),
                        */
                        // Cash
                        /*
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(4),
                          child: ListTile(
                            title: const Text(
                              'Total Cash',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  formatPrice(totalCashLaporanData),
                                  style: const TextStyle(fontSize: 16),
                                ),
                                Center(
                                  child: TextButton(
                                      onPressed: () {
                                        Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (context) =>
                                                    TokoStrukCashScreen(
                                                      chooseTokoID:
                                                          widget.chooseTokoID,
                                                      strukCashItems:
                                                          tempStrukCashLaporanData,
                                                    )));
                                      },
                                      child: Text(
                                        'Lihat Detail',
                                        style: TextStyle(
                                            color: Colors.blueAccent,
                                            fontWeight: FontWeight.bold),
                                      )),
                                )
                              ],
                            ),
                          ),
                        ),
                        */
                        // absensi
                        /*
                        InkWell(
                          onTap: () {
                            PembukuanAbsenPDFScreen(
                                    chooseTokoID: widget.chooseTokoID,
                                    chooseTokoName: widget.chooseTokoName,
                                    listAbsenData: tempAbsenLaporanData,
                                    listDate: widget.listDate)
                                .createPdfAndPrint();
                          },
                          child: const Card(
                            elevation: 2,
                            margin: EdgeInsets.all(4),
                            child: ListTile(
                              title: Text(
                                'Rekap Absensi',
                                style: TextStyle(
                                  color: Colors.blueAccent,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                'Klik untuk melihat',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                          ),
                        ),
                        */
                      ],
                    ),
                  ],
                ),
              ),
            )
          : Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(
                    height: 6,
                  ),
                  Text(
                    'Processing ${processProgress + 1}/${widget.listDate.length}',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
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
}
