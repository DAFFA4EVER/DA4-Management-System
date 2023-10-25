import 'package:da4_management_client_point/backend/control.dart';
import 'package:flutter/material.dart';
import 'absen_todayForm.dart';
import 'package:intl/intl.dart';
import 'choose_dayAbsen.dart';

class AbsenMenu extends StatelessWidget {
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
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => ChooseAbsenDay(
                                  chooseID: TokoID.tokoID,
                                )));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people),
                        SizedBox(height: 8.0),
                        Text('Lihat Jadwal Masuk'),
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
