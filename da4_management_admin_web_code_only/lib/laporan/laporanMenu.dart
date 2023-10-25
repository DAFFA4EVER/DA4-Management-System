import 'package:da4_management/laporan/laporan_point_currentDateForm.dart';
import 'package:flutter/material.dart';
import 'laporan_currentDateForm.dart';
import 'list_laporan.dart';
import 'package:intl/intl.dart';
import '../backend/control.dart';
import 'package:da4_management/laporan/laporan_readySetor.dart';

class LaporanMenu extends StatelessWidget {
  final String chooseTokoID;
  final String chooseTokoName;
  final bool isPoint;

  bool canEdit = false;

  LaporanMenu(
      {required this.chooseTokoID,
      required this.chooseTokoName,
      required this.isPoint});

  @override
  Widget build(BuildContext context) {
    if (loginState.role == 'superadmin') {
      canEdit = true;
    }
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
                    if (canEdit == true) {
                      if (isPoint == false) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LaporanTodayScreen(
                                      edit: canEdit,
                                      chooseTokoID: chooseTokoID,
                                      currentdate: DateFormat('yyyy-MM-dd')
                                          .format(DateTime.now()),
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LaporanTodayPointScreen(
                                      edit: canEdit,
                                      chooseTokoID: chooseTokoID,
                                      currentdate: DateFormat('yyyy-MM-dd')
                                          .format(DateTime.now()),
                                    )));
                      }
                    } else {
                      if (isPoint == false) {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LaporanSetorScreen(
                                      edit: canEdit,
                                      chooseTokoID: chooseTokoID,
                                      currentdate: DateFormat('yyyy-MM-dd')
                                          .format(DateTime.now()),
                                    )));
                      } else {
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => LaporanTodayPointScreen(
                                      edit: canEdit,
                                      chooseTokoID: chooseTokoID,
                                      currentdate: DateFormat('yyyy-MM-dd')
                                          .format(DateTime.now()),
                                    )));
                      }
                    }
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.today),
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
                            builder: (context) => ListLaporanScreen(
                                  chooseTokoID: chooseTokoID,
                                  chooseTokoName: chooseTokoName,
                                  customList: const [],
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month),
                        SizedBox(height: 8.0),
                        Text('Semua Laporan'),
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
