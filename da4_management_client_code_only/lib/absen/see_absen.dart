import 'package:flutter/material.dart';
import '../backend/absenHandler.dart';
import 'package:flutter/services.dart';

class AbsenEditScreen extends StatefulWidget {
  final bool edit;
  final String choooseID;
  final String namaHari;
  final int dayIdx;
  final String currentdate;

  AbsenEditScreen(
      {required this.currentdate,
      required this.edit,
      required this.choooseID,
      required this.dayIdx,
      required this.namaHari});

  @override
  _AbsenEditScreenState createState() => _AbsenEditScreenState();
}

class _AbsenEditScreenState extends State<AbsenEditScreen> {
  List<Map<String, dynamic>> absenItems = [];
  List<Map<String, dynamic>> absenData = [];

  //
  List<Map<String, dynamic>> absenShift1 = [];
  List<String> absenShiftMid = [];
  List<Map<String, dynamic>> absenShift2 = [];
  List<String> absenShiftOff = [];
  List<String> absenNameList = [];
  List<String> takenNameList = [];
  bool dataLoaded = false;
  //

  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  String keteranganInput = '';
  late var jadwalData = [];
  bool changed = false;

  @override
  void initState() {
    super.initState();
    currentDate = widget.currentdate;
    canEdit = widget.edit;
    loadAbsenData();
  }

  String? imagePath;
  String? imageName;

  Future<void> loadAbsenData() async {
    absenItems =
        List<Map<String, dynamic>>.from(await loadJadwalFromFirestore());

    absenData = List<Map<String, dynamic>>.from(
        absenItems[widget.dayIdx][widget.namaHari]);

    tokoNama = absenItems[7]['name'];
    tanggal = absenItems[7]['version'];

    for (int i = 0; i < absenData.length; i++) {
      final item = absenData[i];
      for (int p = 0; p < item[item.keys.first].length; p++) {
        final namaItem = item[item.keys.first][p];
        if (item.keys.first == '1') {
          absenShift1.add(namaItem);
          absenNameList.add(namaItem['nama']);
        } else if (item.keys.first == 'mid') {
          absenShiftMid.add(namaItem);
          absenNameList.add(namaItem);
        } else if (item.keys.first == '2') {
          absenShift2.add(namaItem);
          absenNameList.add(namaItem['nama']);
        } else if (item.keys.first == 'off') {
          absenShiftOff.add(namaItem);
          absenNameList.add(namaItem);
        }
      }
    }
    dataLoaded = true;
    setState(() {});
  }

  void updateabsenData() {
    // Shift 1
    absenData[0][absenData[0].keys.first] = absenShift1;
    // Shift Mid
    absenData[1][absenData[1].keys.first] = absenShiftMid;
    // Shift 2
    absenData[2][absenData[2].keys.first] = absenShift2;
    // Shift Off
    absenData[3][absenData[3].keys.first] = absenShiftOff;
    changed = true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (changed) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Perubahan Belum Tersimpan'),
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
        } else {
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
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Absen Hari ${widget.namaHari}'),
        ),
        body: (dataLoaded == false)
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
            : ListView(
                children: [
                  // Tanggal
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(6),
                    child: ListTile(
                      title: const Text(
                        'Version',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        tanggal,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  // Toko Nama
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(6),
                    child: ListTile(
                      title: const Text(
                        'Toko',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Text(
                        tokoNama,
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  // Absen Hari

                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(6),
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text(
                            'Absen Hari',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Text(
                            widget.namaHari,
                            style: const TextStyle(fontSize: 16),
                          ),
                        ),

                        // Absen Shift 1
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: absenShift1.length,
                                itemBuilder: (context, index) {
                                  final absen = absenShift1[index] ??
                                      {}; // Initialize with an empty map if null
                                  String namaPegawai = absen['nama'];
                                  final String rolePegawai = absen['role'];

                                  var cardColor =
                                      Color.fromARGB(255, 240, 255, 140);
                                  if (rolePegawai == 'back') {
                                    cardColor =
                                        Color.fromARGB(255, 143, 227, 246);
                                  } else if (rolePegawai == 'off') {
                                    cardColor =
                                        Color.fromARGB(255, 255, 151, 140);
                                  } else if (rolePegawai == 'kasir') {
                                    cardColor =
                                        Color.fromARGB(255, 200, 255, 168);
                                  }
                                  return Card(
                                    color: cardColor,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Row(children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            namaPegawai,
                                            style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ]),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        const Divider(),
                                        Text(
                                          'Shift 1',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          absenItems[7]['waktu'][0],
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Absen Shift Mid
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: absenShiftMid.length,
                                itemBuilder: (context, index) {
                                  String namaPegawai = absenShiftMid[index] ??
                                      ''; // Initialize with an empty map if null

                                  var cardColor =
                                      Color.fromARGB(255, 240, 255, 140);

                                  return Card(
                                    color: cardColor,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Row(children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            namaPegawai,
                                            style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ]),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        const Divider(),
                                        Text(
                                          'Shift Mid',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          absenItems[7]['waktu'][1],
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Absen Shift 2
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: absenShift2.length,
                                itemBuilder: (context, index) {
                                  final absen = absenShift2[index] ??
                                      {}; // Initialize with an empty map if null
                                  String namaPegawai = absen['nama'];
                                  final String rolePegawai = absen['role'];

                                  var cardColor =
                                      Color.fromARGB(255, 240, 255, 140);
                                  if (rolePegawai == 'back') {
                                    cardColor =
                                        Color.fromARGB(255, 143, 227, 246);
                                  } else if (rolePegawai == 'off') {
                                    cardColor =
                                        Color.fromARGB(255, 255, 151, 140);
                                  } else if (rolePegawai == 'kasir') {
                                    cardColor =
                                        Color.fromARGB(255, 200, 255, 168);
                                  }
                                  return Card(
                                    color: cardColor,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Row(children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            namaPegawai,
                                            style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ]),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        const Divider(),
                                        Text(
                                          'Shift 2',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        Text(
                                          absenItems[7]['waktu'][2],
                                          style: TextStyle(
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox(
                                          height: 8,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        // Absen Shift Libur
                        Card(
                          elevation: 2,
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              ListView.builder(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: absenShiftOff.length,
                                itemBuilder: (context, index) {
                                  String namaPegawai = absenShiftOff[index];
                                  var cardColor =
                                      Color.fromARGB(255, 255, 151, 140);
                                  return Card(
                                    color: cardColor,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          height: 16,
                                        ),
                                        Row(children: [
                                          SizedBox(
                                            width: 10,
                                          ),
                                          Text(
                                            namaPegawai,
                                            style: TextStyle(
                                                fontSize: 25,
                                                color: Colors.black,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ]),
                                        SizedBox(
                                          height: 8,
                                        ),
                                        const Divider(),
                                        Text(
                                          'Shift Libur',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black,
                                          ),
                                        ),
                                        SizedBox.shrink(),
                                        SizedBox(
                                          height: 8,
                                        )
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
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
