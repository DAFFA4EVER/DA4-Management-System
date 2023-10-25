import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/absenHandler.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../backend/buktiDataHandlerAndroid.dart';
import 'package:path/path.dart' as Path;
import 'package:image_watermark/image_watermark.dart';
import '../backend/moduleDataHandler.dart';
import '../backend/control.dart';

class AbsenTodayScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;
  final String choooseID;

  AbsenTodayScreen(
      {required this.currentdate, required this.edit, required this.choooseID});

  @override
  _AbsenTodayScreenState createState() => _AbsenTodayScreenState();
}

class _AbsenTodayScreenState extends State<AbsenTodayScreen> {
  List<Map<String, dynamic>> absenItems = [];

  final laporanHelper = LaporanDatabaseHandlerFirestore.instance;
  Map<String, dynamic> absenData = {};
  late String currentDate;
  late bool canEdit;
  String tokoNama = '';
  String tanggal = '';
  String kosongMessage = '';
  String keteranganInput = '';
  late var jadwalData = [];
  bool dataLoaded = false;
  List<dynamic> absenShiftModule = [];
  List<String> absenRoleModule = [];
  Map<String, dynamic> moduleSetting = {};
  List<String> shiftNameList = ['off'];
  bool _changesMade = false;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    if (widget.currentdate == '') {
      currentDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      currentDate = widget.currentdate;
    }

    canEdit = false;
    if (loginState.role == 'superadmin') {
      canEdit = true;
    }
    print(canEdit);
    //currentDate = '2023-07-05';
    checkLaporanExist();
  }

  void setUpModule() {
    absenShiftModule = moduleSetting['shiftAbsen'];
    absenRoleModule = List<String>.from(moduleSetting['roleAbsen']);

    for (final shiftName in absenShiftModule) {
      if (shiftNameList.contains(shiftName['shift']) == false) {
        shiftNameList.add(shiftName['shift']);
      }
    }
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

  String? imagePath;
  String? imageName;

  Future<bool> pickImage(int index) async {
    try {
      var pickedImage =
          await ImagePicker().getImage(source: ImageSource.gallery);
      if (pickedImage == null) return false;

      final imageName = Path.basename(pickedImage!.path);

      final imageFile = File(pickedImage.path);

      final watermarkedImg = await ImageWatermark.addTextWatermark(
        imgBytes: await imageFile.readAsBytes(),

        ///image bytes
        watermarkText:
            '${currentDate} - ${DateFormat.Hms().format(DateTime.now())}',

        ///watermark text
        dstX: 20,

        ///position of watermark x coordinate
        dstY: 30,

        ///y coordinate
        color: const Color.fromARGB(255, 255, 255, 255),

        ///default : Colors.black
      );
      final watermarkImgFile = base64Encode(watermarkedImg);
      final firestorageURL = await BuktiDataHandlerAndroid.instance
          .uploadImageURL(
              File(watermarkImgFile), currentDate, widget.choooseID);

      setState(() {
        absenItems[index]['photo'] = pickedImage!.path;
        absenItems[index]['imageName'] = imageName;
        absenItems[index]['firestorage'] = firestorageURL;
        absenItems[index]['masuk'] = DateFormat.Hms().format(DateTime.now());
      });
    } on PlatformException catch (e) {
      print('Error picking image: $e');
    }
    return true;
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

  Future<void> createAbsenItem() async {
    if (absenData['absen'].length == 0) {
      List<dynamic> todayJadwal =
          jadwalData[getHariAngka()][getNamaHari(getHariAngka())];

      for (int p = 0; p < todayJadwal.length; p++) {
        Map<String, dynamic> schedule = todayJadwal[p];
        String key = schedule.keys.first; // Get the first key in the schedule

        int h =
            absenShiftModule.indexWhere((element) => element['shift'] == key);

        if (h == -1) {
          h = absenShiftModule.length - 1;
        }
        if (key == '1') {
          for (int i = 0; i < schedule[key].length; i++) {
            String nama = schedule[key][i]['nama'];
            String role = schedule[key][i]['role'];

            absenItems.add({
              'nama': nama,
              'role': role,
              'shift': key,
              'photo': '',
              'imageName': '',
              'firestorage': '',
              'waktu': absenShiftModule[h]['time'],
              'masuk': '',
              'keluar': '',
              'keterangan': '',
            });
          }
        } else if (key == 'mid') {
          for (int i = 0; i < schedule[key].length; i++) {
            String nama = schedule[key][i];
            absenItems.add({
              'nama': nama,
              'shift': key,
              'role': key,
              'photo': '',
              'imageName': '',
              'firestorage': '',
              'waktu': absenShiftModule[h]['time'],
              'masuk': '',
              'keluar': '',
              'keterangan': '',
            });
          }
        } else if (key == '2') {
          for (int i = 0; i < schedule[key].length; i++) {
            String nama = schedule[key][i]['nama'];
            String role = schedule[key][i]['role'];
            absenItems.add({
              'nama': nama,
              'role': role,
              'shift': key,
              'photo': '',
              'imageName': '',
              'firestorage': '',
              'waktu': absenShiftModule[h]['time'],
              'masuk': '',
              'keluar': '',
              'keterangan': '',
            });
          }
        } else if (key == 'off') {
          for (int i = 0; i < schedule[key].length; i++) {
            String nama = schedule[key][i];
            absenItems.add({
              'nama': nama,
              'shift': key,
              'role': key,
              'photo': '',
              'imageName': '',
              'firestorage': '',
              'waktu': absenShiftModule[h]['time'],
              'masuk': '',
              'keluar': '',
              'keterangan': '',
            });
          }
        }
      }
    }
  }

  Future<void> checkLaporanExist() async {
    try {
      if (await laporanHelper.checkLaporanExist(
              currentDate, widget.choooseID) ==
          false) {
        absenData =
            laporanHelper.laporanTemplate(currentDate, widget.choooseID);
      } else {
        absenData = await laporanHelper.loadLaporanFromFirestore(
            currentDate, widget.choooseID);
      }
      final tempJadwal = await loadJadwalFromFirestore(widget.choooseID);
      await getModuleSetting();
      setState(() {
        tokoNama = absenData['namaToko'];
        tanggal = absenData['date'];
        jadwalData = tempJadwal;
        absenItems = List<Map<String, dynamic>>.from(absenData['absen']);

        createAbsenItem();
        dataLoaded = true;
      });
    } catch (e) {
      //absenData = laporanHelper.laporanTemplate(currentDate, widget.choooseID);
    }
  }

  void updateabsenData() {
    if (canEdit) {
      // Date
      absenData['date'] = currentDate;
      // absen
      absenData['absen'] = absenItems;

      laporanHelper.saveLaporanToFirestore(
          absenData, currentDate, widget.choooseID);
    }
  }

  Future<void> _showTimePicker(
      TextEditingController controller, int index) async {
    TimeOfDay initialTime = TimeOfDay.now();

    if (controller.text.isNotEmpty) {
      List<String> timeParts = controller.text.split(':');
      int hour = int.tryParse(timeParts[0]) ?? 0;
      int minute = int.tryParse(timeParts[1]) ?? 0;
      initialTime = TimeOfDay(hour: hour, minute: minute);
    }

    final TimeOfDay? selectedTime = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (selectedTime != null) {
      final formattedTime =
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}:00';

      controller.text = formattedTime;
      if (controller.text != formattedTime) {
        _changesMade = true;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
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

        return true;
      },
      child: Scaffold(
        appBar: AppBar(
          actions: [
            (canEdit == true)
                ? IconButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Konfirmasi Perubahan'),
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
                    icon: Icon(Icons.save))
                : SizedBox.shrink(),
          ],
          title: const Text('Absen Hari Ini'),
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
                    margin: const EdgeInsets.all(16),
                    child: ListTile(
                      title: const Text(
                        'Tanggal',
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
                            "Absen Hari ${getNamaHari(getHariAngka())}",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: absenItems.length,
                          itemBuilder: (context, index) {
                            final absen = absenItems[index] ??
                                {}; // Initialize with an empty map if null
                            final String namaPegawai = absen['nama'];
                            final String rolePegawai = absen['role'];
                            final TextEditingController keteranganController =
                                TextEditingController(
                                    text: absen['keterangan']);
                            final String shiftPegawai = absen['shift'];

                            final String photo = absen['photo'] ?? '';
                            final String photo2 = absen['photo2'] ?? '';

                            final String waktuPegawai = absen['waktu'];

                            final TextEditingController masukWaktuController =
                                TextEditingController(text: absen['masuk']);
                            final TextEditingController keluarWaktuController =
                                TextEditingController(text: absen['keluar']);

                            if (absen['imageName2'] == null) {
                              absen['imageName2'] = '';
                            }
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
                                    Text(
                                      namaPegawai,
                                      style: TextStyle(
                                        fontSize: 25,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ]),

                                  Row(children: [
                                    SizedBox(
                                      width: 10,
                                    ),
                                    Text(
                                      capitalize(rolePegawai),
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.normal,
                                      ),
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
                                  //(absen['role'] != 'off') ?

                                  //: SizedBox.shrink(),
                                  if (photo.isNotEmpty) ...[
                                    const Divider(),
                                    InkWell(
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.photo,
                                              ),
                                              Text(
                                                absen['imageName'],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        showLoadingOverlay(context);
                                        final imageData =
                                            await BuktiDataHandlerAndroid
                                                .instance
                                                .loadBuktiFromFirestorage(
                                                    currentDate,
                                                    absen['imageName'],
                                                    widget.choooseID);
                                        if (imageData != null) {
                                          hideLoadingOverlay(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: Container(
                                                    child: Image.memory(
                                                        imageData)),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Close'))
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  Column(
                                    children: [
                                      Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      (canEdit == false)
                                          ? Text(
                                              absen['masuk'],
                                              style: TextStyle(),
                                            )
                                          : Column(
                                              children: [
                                                Text(
                                                  absen['masuk'],
                                                  style: TextStyle(),
                                                ),
                                                IconButton(
                                                    onPressed: () async {
                                                      await _showTimePicker(
                                                          masukWaktuController,
                                                          index);
                                                      print('Hey');
                                                      //
                                                      absenItems[index]
                                                              ['masuk'] =
                                                          masukWaktuController
                                                              .text;

                                                      print(absenItems[index]
                                                          ['masuk']);
                                                      //
                                                      setState(() {});
                                                    },
                                                    icon: Icon(Icons.alarm))
                                              ],
                                            ),
                                    ],
                                  ),

                                  const Divider(),
                                  if (photo2.isNotEmpty) ...[
                                    InkWell(
                                      child: Column(
                                        children: [
                                          SizedBox(
                                            height: 10,
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.photo,
                                              ),
                                              Text(
                                                absen['imageName2'],
                                                textAlign: TextAlign.center,
                                                style: TextStyle(),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                            height: 10,
                                          ),
                                        ],
                                      ),
                                      onTap: () async {
                                        showLoadingOverlay(context);
                                        final imageData =
                                            await BuktiDataHandlerAndroid
                                                .instance
                                                .loadBuktiFromFirestorage(
                                                    currentDate,
                                                    absen['imageName2'],
                                                    widget.choooseID);
                                        if (imageData != null) {
                                          hideLoadingOverlay(context);
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                content: Container(
                                                    child: Image.memory(
                                                        imageData)),
                                                actions: [
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.pop(context);
                                                      },
                                                      child:
                                                          const Text('Close'))
                                                ],
                                              );
                                            },
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  Column(
                                    children: [
                                      Text(
                                        'Keluar',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      (canEdit == false)
                                          ? Text(
                                              absen['keluar'],
                                              style: TextStyle(),
                                            )
                                          : Column(
                                              children: [
                                                Text(
                                                  absen['keluar'],
                                                  style: TextStyle(),
                                                ),
                                                IconButton(
                                                    onPressed: () async {
                                                      await _showTimePicker(
                                                          keluarWaktuController,
                                                          index);
                                                      print('Hey');
                                                      //
                                                      absenItems[index]
                                                              ['keluar'] =
                                                          keluarWaktuController
                                                              .text;

                                                      print(absenItems[index]
                                                          ['keluar']);
                                                      //
                                                      setState(() {});
                                                    },
                                                    icon: Icon(Icons.alarm))
                                              ],
                                            ),
                                      SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  const Divider(),
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextFormField(
                                      enabled: false,
                                      controller: keteranganController,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold),
                                      decoration: const InputDecoration(
                                          labelText: 'Keterangan',
                                          labelStyle: TextStyle()),
                                      onChanged: (value) {
                                        absen['keterangan'] = value;
                                        updateabsenData();
                                      },
                                    ),
                                  ),
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
