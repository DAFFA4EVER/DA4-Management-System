import 'package:flutter/material.dart';
import 'see_absen.dart';
import 'package:intl/intl.dart';

class ChooseAbsenDay extends StatelessWidget {
  final String chooseID;

  ChooseAbsenDay({required this.chooseID});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lihat Jadwal Absen'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 0,
                                namaHari: 'Senin')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Senin'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 1,
                                namaHari: 'Selasa')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Selasa'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 2,
                                namaHari: 'Rabu')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Rabu'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 3,
                                namaHari: 'Kamis')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Kamis'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 4,
                                namaHari: 'Jumat')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Jumat'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 5,
                                namaHari: 'Sabtu')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Sabtu'),
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
                            builder: (context) => AbsenEditScreen(
                                currentdate: DateFormat('yyyy-MM-dd')
                                    .format(DateTime.now()),
                                edit: true,
                                choooseID: chooseID,
                                dayIdx: 6,
                                namaHari: 'Minggu')));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.swap_horizontal_circle),
                        SizedBox(height: 8.0),
                        Text('Minggu'),
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
