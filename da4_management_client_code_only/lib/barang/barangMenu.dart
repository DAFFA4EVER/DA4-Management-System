import 'package:da4_management_client/barang/barang_Gudang.dart';
import 'package:da4_management_client/barang/barang_Toko.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

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
                    DateTime now = DateTime.now();
                    DateTime yesterday = now.subtract(Duration(days: 1));

                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => GudangLaporanScreen(
                                  edit: false,
                                  currentdate: DateFormat('yyyy-MM-dd')
                                      .format(yesterday),
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
                        Text('Stock Barang di Gudang'),
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
                            builder: (context) => GudangTokoScreen(
                                  currentdate: DateFormat('yyyy-MM-dd').format(
                                      DateTime.now()
                                          .subtract(Duration(days: 1))),
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.store),
                        SizedBox(height: 8.0),
                        Text('Stock Barang di Toko'),
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
