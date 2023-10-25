import 'package:flutter/material.dart';
import 'laporan_point_currentDateForm.dart';
import 'list_laporan.dart';
import 'package:intl/intl.dart';

class LaporanMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Laporan'),
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
                            builder: (context) => LaporanTodayPointScreen(
                                  currentdate: DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()),
                                  edit: true,
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_task),
                        SizedBox(height: 8.0),
                        Text('Laporan Hari Ini'),
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
                            builder: (context) => ListLaporanScreen()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month),
                        SizedBox(height: 8.0),
                        Text('Lihat Semua Laporan'),
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
