import 'package:da4_management/absen/absen_todayForm.dart';
import 'package:flutter/material.dart';
import '../backend/absenHandler.dart';
import 'package:intl/intl.dart';
import 'choose_dayAbsen.dart';

class AbsenMenu extends StatelessWidget {
  final String chooseTokoID;
  final String chooseTokoName;

  bool canEdit = false;

  AbsenMenu({required this.chooseTokoID, required this.chooseTokoName});

  String getNamaHari(int idx) {
    switch (idx) {
      case 0:
        return 'Senin';
      case 1:
        return 'Selasa';
      case 2:
        return 'Rabu';
      case 3:
        return 'Kamis';
      case 4:
        return 'Jumat';
      case 5:
        return 'Sabtu';
      case 6:
        return 'Minggu';
      default:
        return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Absensi'),
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
                            builder: (context) => AbsenTodayScreen(
                                  choooseID: chooseTokoID,
                                  currentdate: DateFormat('yyyy-MM-dd')
                                      .format(DateTime.now()),
                                  edit: false,
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.accessibility_new_outlined),
                        SizedBox(height: 8.0),
                        Text('Absen Hari Ini'),
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
                    /*
                    List<dynamic> absenData =
                        await loadJadwalFromFirestore(chooseTokoID);
                    for (int i = 0; 0 < absenData.length; i++) {
                      if (i < 7) {
                        print(
                            "${getNamaHari(i)} <> ${absenData[i][getNamaHari(i)]}");
                      }
                    }
                    */
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) =>
                                ChooseAbsenDay(chooseID: chooseTokoID)));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people),
                        SizedBox(height: 8.0),
                        Text('Edit Jadwal Masuk'),
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
