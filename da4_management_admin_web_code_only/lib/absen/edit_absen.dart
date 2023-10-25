import 'package:flutter/material.dart';
import '../backend/absenHandler.dart';
import 'package:flutter/services.dart';
import '../backend/moduleDataHandler.dart';

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
  List<Map<String, dynamic>> absenShiftList = [];
  List<String> absenNameList = [];
  List<String> absenRoleList = [];
  //

  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  String keteranganInput = '';
  late var jadwalData = [];
  bool changed = false;
  bool dataLoaded = false;
  Map<String, dynamic> moduleSetting = {};

  @override
  void initState() {
    super.initState();
    currentDate = widget.currentdate;
    canEdit = widget.edit;
    loadAbsenData();
  }

  String? imagePath;
  String? imageName;

  void setUpModule() {
    //dataLoaded = true;
    absenRoleList = List<String>.from(moduleSetting['roleAbsen']);
    setState(() {});
  }

  Future<void> getModuleSetting() async {
    if ((await ModuleHandler().checkModuleExist()) == true) {
      moduleSetting = await ModuleHandler().getModuleData();
    } else {
      await ModuleHandler().uploadModuleDataDefault();
      moduleSetting = await ModuleHandler().getModuleData();
    }
    setUpModule();
  }

  Future<void> loadAbsenData() async {
    try {
      await getModuleSetting();
      absenItems = List<Map<String, dynamic>>.from(
          await loadJadwalFromFirestore(widget.choooseID));

      absenData = List<Map<String, dynamic>>.from(
          absenItems[widget.dayIdx][widget.namaHari]);

      tokoNama = absenItems[7]['name'];
      tanggal = absenItems[7]['version'];

      absenNameList = List<String>.from(absenItems[7]['pegawai']);

      for (int i = 0; i < absenData.length; i++) {
        final item = absenData[i];
        for (int p = 0; p < item[item.keys.first].length; p++) {
          late var namaItem;
          final waktuKerja = moduleSetting['shiftAbsen']
              .where((element) => element['shift'] == item.keys.first)
              .toList()[0];
          if (item[item.keys.first][p].runtimeType == String) {
            namaItem = {
              'nama': item[item.keys.first][p],
              'shift': item.keys.first,
              'role': item.keys.first,
              'waktu': waktuKerja['time'],
            };
          } else {
            namaItem = item[item.keys.first][p];
            //namaItem['shift'] = item.keys.first;

            namaItem['shift'] = item.keys.first;
            namaItem['waktu'] = waktuKerja['time'];
          }

          absenShiftList.add(namaItem);
        }
      }
      updateabsenData();

      dataLoaded = true;
      setState(() {});
    } catch (e) {
      print(e);
    }
  }

  int getHariAngka() {
    DateTime now = DateTime.now();
    return now.weekday - 1;
  }

  String capitalize(String text) {
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

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

  void updateabsenData() {
    // Shift 1
    List<Map<String, dynamic>> absenShift1 = [];
    List<Map<String, dynamic>> absenShift2 = [];
    List<String> absenShiftMid = [];
    List<String> absenShiftOff = [];

    for (final absenName in absenShiftList) {
      if (absenName['shift'] == '1') {
        absenShift1.add(absenName);
      } else if (absenName['shift'] == '2') {
        absenShift2.add(absenName);
      } else if (absenName['shift'] == 'off') {
        absenShiftOff.add(absenName['nama']);
      } else if (absenName['shift'] == 'mid') {
        absenShiftMid.add(absenName['nama']);
      }
    }
    absenData[0][absenData[0].keys.first] = absenShift1;
    // Shift Mid
    absenData[1][absenData[1].keys.first] = absenShiftMid;
    // Shift 2
    absenData[2][absenData[2].keys.first] = absenShift2;
    // Shift Off
    absenData[3][absenData[3].keys.first] = absenShiftOff;

    // To the absenItem data
    absenItems[widget.dayIdx][widget.namaHari] = absenData;

    changed = true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (canEdit) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Masih Sama'),
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
                      //laporanHelper.saveLaporanToFirestore(
                      //    absenData, currentDate, widget.choooseID);
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
                content: const Text(
                    'Perubahan belum tersimpan. Anda yakin ingin keluar?'),
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

                      //laporanHelper.saveLaporanToFirestore(
                      //    absenData, currentDate, widget.choooseID);
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
        bottomNavigationBar: (dataLoaded == true)
            ? Card(
                color: Theme.of(context).primaryColor,
                elevation: 2,
                margin: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: const Text('Konfirmasi Perubahan Jadwal'),
                          content: Text(
                              'Apakah anda sudah yakin data yang dimasukkan valid?'),
                          actions: [
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    Navigator.pop(context);
                                  });
                                },
                                child: Text('Tidak')),
                            TextButton(
                                onPressed: () {
                                  setState(() {
                                    updateabsenData();
                                    absenItems[7]['version'] = currentDate;
                                    updateJadwalToFirestore(
                                        widget.choooseID, absenItems);
                                    Navigator.pop(
                                      context,
                                    );
                                    Navigator.pop(
                                      context,
                                    );
                                  });
                                },
                                child: Text('Ya'))
                          ],
                        );
                      },
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      'Simpan',
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
                  ),
                ),
              )
            : SizedBox.shrink(),
        appBar: AppBar(
          title: Text('Edit Absen Hari ${getNamaHari(widget.dayIdx)}'),
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
                  // Version
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
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
                    margin: const EdgeInsets.all(16),
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
                  // Absen
                  Card(
                    elevation: 2,
                    margin: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            "Absen Hari ${getNamaHari(widget.dayIdx)}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: absenShiftList.length,
                          itemBuilder: (context, index) {
                            final absen = absenShiftList[index] ??
                                {}; // Initialize with an empty map if null

                            String namaPegawai = absen['nama'];
                            String rolePegawai = absen['role'];

                            final String shiftPegawai = absen['shift'];

                            final String waktuPegawai = absen['waktu'];
                            //print(absen['waktu']);
                            return Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    height: 16,
                                  ),
                                  Row(children: [
                                    SizedBox(
                                      width: 10,
                                    ),
                                    DropdownButton<String>(
                                      value: namaPegawai,
                                      hint: Text('Pilih Orang'),
                                      style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold),
                                      items: absenNameList
                                          .map((String option) {
                                            return DropdownMenuItem<String>(
                                              value: option,
                                              child: Text(option),
                                            );
                                          })
                                          .toSet()
                                          .toList(), // Convert to a set to remove duplicate values, then convert back to a list
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          namaPegawai = newValue ?? '';
                                          absenShiftList[index]['nama'] =
                                              namaPegawai;

                                          updateabsenData();
                                        });
                                      },
                                    ),
                                  ]),

                                  Row(children: [
                                    SizedBox(
                                      width: 10,
                                    ),
                                    (rolePegawai != 'off' &&
                                            rolePegawai != 'mid')
                                        ? DropdownButton<String>(
                                            value: rolePegawai,
                                            hint: Text('Pilih Role'),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal),
                                            items: absenRoleList
                                                .map((String option) {
                                                  return DropdownMenuItem<
                                                      String>(
                                                    value: option,
                                                    child: Text(
                                                        capitalize(option)),
                                                  );
                                                })
                                                .toSet()
                                                .toList(), // Convert to a set to remove duplicate values, then convert back to a list
                                            onChanged: (String? newValue) {
                                              setState(() {
                                                rolePegawai = newValue ?? '';
                                                absenShiftList[index]['role'] =
                                                    rolePegawai;

                                                updateabsenData();
                                              });
                                            },
                                          )
                                        : Text(
                                            capitalize(rolePegawai),
                                            style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.normal),
                                          ),
                                  ]),
                                  Text(
                                    'Shift ' + capitalize(shiftPegawai),
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  Text(
                                    waktuPegawai,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                                  SizedBox(
                                    height: 8,
                                  ),
                                  //(absen['role'] != 'off') ?

                                  //: SizedBox.shrink(),

                                  //: SizedBox.shrink(),
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
