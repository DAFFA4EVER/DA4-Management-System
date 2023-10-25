import 'package:da4_management/analisis/detail%20gudang/detail_SO.dart';
import 'package:da4_management/analisis/detail%20gudang/detail_stockFirst.dart';
import 'package:da4_management/backend/gudangDataHandlerFirestore.dart';
import '../export/pdf_laporanGudang.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../stock_barang/list_laporanGudang.dart';
//import 'detail gudang/detail_stockAll.dart';
import 'detail gudang/detail_stockCurrent.dart';
import 'detail gudang/detail_stockMasuk.dart';
import 'detail gudang/detail_stockKeluar.dart';
import 'detail gudang/detail_bayar.dart';

class PembukuanGudangScreen extends StatefulWidget {
  final List<String> listDate;
  final String chooseTokoID;
  final String chooseTokoName;

  PembukuanGudangScreen({
    required this.chooseTokoID,
    required this.chooseTokoName,
    required this.listDate,
  });

  @override
  _PembukuanGudangScreenState createState() => _PembukuanGudangScreenState();
}

class _PembukuanGudangScreenState extends State<PembukuanGudangScreen> {
  bool dataLoaded = false;
  //List<dynamic> tempStockGudangData = [];
  List<dynamic> tempFirstStockGudangData = [];
  List<dynamic> tempCurrentStockGudangData = [];
  List<dynamic> tempMasukGudangData = [];
  List<dynamic> tempKeluarGudangData = [];
  List<dynamic> tempBayarGudangData = [];
  List<dynamic> tempSOGudangData = [];

  int totalBayarGudangData = 0;
  int totalSOGudangData = 0;
  int processProgress = 0;

  @override
  void initState() {
    super.initState();
    pembukuanProcess();
  }

  Future<void> pembukuanProcess() async {
    for (int i = 0; i < widget.listDate.length; i++) {
      // read data from server
      final tempGudangData = await GudangLaporanDatabaseHandlerFirestore
          .instance
          .loadLaporanGudangFromFirestore(widget.listDate[i]);
      setState(() {
        processProgress = i;
      });

      // add total stock data
      /*
      for (final menuItem in tempGudangData['stokGudang']) {
        final existingIndex = tempStockGudangData.indexWhere(
          (item) => item['id'] == menuItem['id'],
        );
        if (existingIndex == -1) {
          Map<String, dynamic> inputData = {
            'id': menuItem['id'],
            'nama': menuItem['nama'],
            'qty': menuItem['qty'],
            'unit': menuItem['unit'],
            'quantity': menuItem['quantity'],
            'price': menuItem['price'],
          };
          tempStockGudangData.add(inputData);
        } else {
          tempStockGudangData[existingIndex]['quantity'] +=
              menuItem['quantity'];
        }
      }
      */
      // add barang masuk

      for (final menuItem in tempGudangData['barangMasuk']) {
        final existingIndex = tempMasukGudangData.indexWhere(
          (item) => item['id'] == menuItem['id'],
        );
        if (existingIndex == -1) {
          Map<String, dynamic> inputData = {
            'id': menuItem['id'],
            'nama': menuItem['nama'],
            'qty': menuItem['qty'],
            'unit': menuItem['unit'],
            'quantity': menuItem['quantity'],
            'price': menuItem['price'],
          };
          tempMasukGudangData.add(inputData);
        } else {
          tempMasukGudangData[existingIndex]['quantity'] +=
              menuItem['quantity'];
        }
      }
      // add barang keluar
      for (final menuItem in tempGudangData['barangKeluar']) {
        final existingIndex = tempKeluarGudangData.indexWhere(
          (item) => item['id'] == menuItem['id'],
        );
        if (existingIndex == -1) {
          Map<String, dynamic> inputData = {
            'id': menuItem['id'],
            'nama': menuItem['nama'],
            'qty': menuItem['qty'],
            'unit': menuItem['unit'],
            'quantity': menuItem['quantity'],
            'price': menuItem['price'],
          };
          tempKeluarGudangData.add(inputData);
        } else {
          tempKeluarGudangData[existingIndex]['quantity'] +=
              menuItem['quantity'];
        }
      }
      // total bayar
      for (final bayarItem in tempGudangData['buktiBayar']) {
        if (bayarItem['jumlah'] != null) {
          totalBayarGudangData += bayarItem['jumlah'] as int;
        }
        bayarItem['tanggal'] = widget.listDate[i];
        tempBayarGudangData.add(bayarItem);
      }
      // total harga so
      for (final soItem in tempGudangData['strukSO']) {
        if (soItem['jumlah'] != null) {
          totalSOGudangData += soItem['jumlah'] as int;
        }
        soItem['tanggal'] = widget.listDate[i];
        tempSOGudangData.add(soItem);
      }
      // first stock
      if (i == 0) {
        tempFirstStockGudangData = tempGudangData['stokGudang'];
      }
      // current stock
      if ((i + 1) == widget.listDate.length) {
        tempCurrentStockGudangData = tempGudangData['stokGudang'];
      }
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
                        builder: (context) => ListLaporanGudangScreen(
                            chooseTokoID: widget.chooseTokoID,
                            chooseTokoName: widget.chooseTokoName,
                            customList: widget.listDate)))
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
                    'Laporan Gudang ${widget.chooseTokoName}',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ),
              ),
            )
          : Text(''),
      appBar: AppBar(
        actions: [
          dataLoaded
              ? IconButton(
                  onPressed: () {
                    PembukuanGudangPDFScreen(
                            listFirstStockGudangData: tempFirstStockGudangData,
                            chooseTokoID: widget.chooseTokoID,
                            chooseTokoName: widget.chooseTokoName,
                            listBayarGudangData: tempBayarGudangData,
                            listCurrentStockGudangData:
                                tempCurrentStockGudangData,
                            listMasukGudangData: tempMasukGudangData,
                            listKeluarGudangData: tempKeluarGudangData,
                            listSOGudangData: tempSOGudangData,
                            //listStockGudangData: tempStockGudangData,
                            listDate: widget.listDate,
                            totalBayarGudangData: totalBayarGudangData,
                            totalSOGudangData: totalSOGudangData)
                        .createPdfAndPrint();
                  },
                  icon: Icon(Icons.print))
              : Text('')
        ],
        title: Text('Pembukuan'),
      ),
      body: dataLoaded
          ? ListView(
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
                          'Laporan Gudang ${widget.chooseTokoName}',
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
                    // Pembayaran
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.all(4),
                      child: ListTile(
                        title: const Text(
                          'Total Pembayaran',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatPrice(totalBayarGudangData),
                              style: const TextStyle(fontSize: 16),
                            ),
                            Center(
                              child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                GudangBayarStockScreen(
                                                  bayarSOItems:
                                                      tempBayarGudangData,
                                                  namaGudang:
                                                      widget.chooseTokoName,
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
                    // Harga SO
                    Card(
                      elevation: 2,
                      margin: const EdgeInsets.all(4),
                      child: ListTile(
                        title: const Text(
                          'Total Harga SO',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              formatPrice(totalSOGudangData),
                              style: const TextStyle(fontSize: 16),
                            ),
                            Center(
                              child: TextButton(
                                  onPressed: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                GudangSOStockScreen(
                                                  bayarSOItems:
                                                      tempSOGudangData,
                                                  namaGudang:
                                                      widget.chooseTokoName,
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
                    // Detail First Stock
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => GudangFirstStockScreen(
                                    selectedStockItems:
                                        tempFirstStockGudangData))));
                      },
                      child: const Card(
                        elevation: 2,
                        margin: EdgeInsets.all(4),
                        child: ListTile(
                          title: Text(
                            'Stock Gudang Awal',
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

                    // Detail Current Stock
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => GudangCurrentStockScreen(
                                    selectedStockItems:
                                        tempCurrentStockGudangData))));
                      },
                      child: const Card(
                        elevation: 2,
                        margin: EdgeInsets.all(4),
                        child: ListTile(
                          title: Text(
                            'Stock Gudang Terakhir',
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

                    // Detail Masuk Stock
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => GudangMasukStockScreen(
                                    selectedStockItems: tempMasukGudangData))));
                      },
                      child: const Card(
                        elevation: 2,
                        margin: EdgeInsets.all(4),
                        child: ListTile(
                          title: Text(
                            'Total Stock Masuk Gudang',
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

                    // Detail Keluar Stock
                    InkWell(
                      onTap: () {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: ((context) => GudangKeluarStockScreen(
                                    selectedStockItems:
                                        tempKeluarGudangData))));
                      },
                      child: const Card(
                        elevation: 2,
                        margin: EdgeInsets.all(4),
                        child: ListTile(
                          title: Text(
                            'Total Stock Keluar Gudang',
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
                  ],
                ),
              ],
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
