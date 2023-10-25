import 'package:da4_management/stock_barang/barang_gudang.dart';
import 'package:da4_management/stock_barang/barang_keluar.dart';
import 'package:flutter/material.dart';
import 'list_laporanGudang.dart';
import 'package:intl/intl.dart';
import 'barang_masuk.dart';

class BarangMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Stock Barang'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GudangLaporanScreen(
                                  currentdate: DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()),
                                  edit: true,
                                  namaGudang: 'Mixue',
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warehouse),
                        SizedBox(height: 8.0),
                        Text('Laporan Gudang'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GudangMasukScreen(
                                  currentdate: DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()),
                                  edit: true,
                                  namaGudang: 'Mixue',
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_shopping_cart),
                        SizedBox(height: 8.0),
                        Text('Barang Masuk'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GudangKeluarScreen(
                                  currentdate: DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()),
                                  edit: true,
                                  namaGudang: 'Mixue',
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart_checkout),
                        SizedBox(height: 8.0),
                        Text('Barang Keluar'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ListLaporanGudangScreen(
                                  chooseTokoID: '',
                                  chooseTokoName: 'Mixue',
                                  customList: const [],
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.list),
                        SizedBox(height: 8.0),
                        Text('List Laporan Gudang'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
