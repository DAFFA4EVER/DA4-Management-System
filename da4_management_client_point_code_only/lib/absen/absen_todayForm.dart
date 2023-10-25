import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../backend/absenHandler.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../backend/buktiDataHandlerAndroid.dart';
import 'package:image_watermark/image_watermark.dart';
import '../backend/moduleDataHandler.dart';

class AbsenTodayScreen extends StatefulWidget {
  final String currentdate;
  final bool edit;

  AbsenTodayScreen({required this.currentdate, required this.edit});

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
  int imgUploadTask = -1;

  @override
  void initState() {
    super.initState();
    DateTime now = DateTime.now();
    if (widget.currentdate == '') {
      currentDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      currentDate = widget.currentdate;
    }
    //currentDate = '2023-07-17';
    canEdit = widget.edit;
    checkLaporanExist();
  }

  String? imagePath;
  String? imageName;

  Future<bool> pickImage(int index, String info, bool masuk) async {
    try {
      imgUploadTask = 0;
      var pickedImage =
          await ImagePicker().pickImage(source: ImageSource.camera);
      if (pickedImage == null) return false;

      final imageName = pickedImage.name;
      final imageFile = File(pickedImage.path);
      final watermarkedImg = await ImageWatermark.addTextWatermark(
        imgBytes: await imageFile.readAsBytes(),

        ///image bytes
        watermarkText:
            '(${info}) ${currentDate} - ${DateFormat.Hms().format(DateTime.now())}',

        ///watermark text
        dstX: 20,

        ///position of watermark x coordinate
        dstY: 30,

        ///y coordinate
        color: const Color.fromARGB(255, 255, 255, 255),

        ///default : Colors.black
      );

      final firestorageURL = await BuktiDataHandlerAndroid.instance
          .uploadImageUint8URL(watermarkedImg, imageName, currentDate);

      if (masuk) {
        setState(() {
          absenItems[index]['photo'] = pickedImage!.path;
          absenItems[index]['imageName'] = imageName;
          absenItems[index]['firestorage'] = firestorageURL;
          absenItems[index]['masuk'] = DateFormat.Hms().format(DateTime.now());
        });
      } else {
        absenItems[index]['photo2'] = pickedImage!.path;
        absenItems[index]['imageName2'] = imageName;
        absenItems[index]['firestorage2'] = firestorageURL;
        absenItems[index]['keluar'] = DateFormat.Hms().format(DateTime.now());
      }
      imgUploadTask = 1;
    } on PlatformException catch (e) {
      print('Error picking image: $e');
      imgUploadTask = -1;
    }
    return true;
  }

  int getHariAngka() {
    DateTime now = DateTime.now();
    return now.weekday - 1;
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
      if (await laporanHelper.checkLaporanExist(currentDate) == false) {
        absenData = laporanHelper.laporanTemplate(currentDate);
      } else {
        absenData = await laporanHelper.loadLaporanFromFirestore(currentDate);
      }
      final tempJadwal = await loadJadwalFromFirestore();
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
      absenData = laporanHelper.laporanTemplate(currentDate);
    }
  }

  void updateabsenData() {
    if (canEdit) {
      // Date
      absenData['date'] = currentDate;
      // absen
      absenData['absen'] = absenItems;
      laporanHelper.saveLaporanToFirestore(absenData, currentDate);
    }
  }

  String capitalize(String text) {
    return text.substring(0, 1).toUpperCase() + text.substring(1);
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
                title: const Text('Masih Kosong'),
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
                      laporanHelper.saveLaporanToFirestore(
                          absenData, currentDate);
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
          if (imgUploadTask != 0) {
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

                        laporanHelper.saveLaporanToFirestore(
                            absenData, currentDate);
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
        }
        return true;
      },
      child: Scaffold(
        appBar: AppBar(
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
                            final String waktuPegawai = absen['waktu'];
                            final String photo = absen['photo'] ?? '';
                            final String photo2 = absen['photo2'] ?? '';

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
                                  (absen['role'] != 'off' &&
                                          absen['keluar'] == '')
                                      ? IconButton(
                                          onPressed: () {
                                            showDialog(
                                              context: context,
                                              builder: (BuildContext context) {
                                                return AlertDialog(
                                                  title: Text('Tidak Kerja'),
                                                  content:
                                                      Text('Apa alasannya?'),
                                                  actions: [
                                                    TextButton(
                                                        onPressed: () {
                                                          Navigator.pop(
                                                              context);
                                                          setState(() async {
                                                            bool status =
                                                                await pickImage(
                                                                    index,
                                                                    '${absen['nama']} Izin',
                                                                    true);

                                                            if (status ||
                                                                !status) {
                                                              hideLoadingOverlay(
                                                                  context);
                                                              if (status ==
                                                                  true) {
                                                                absen['masuk'] =
                                                                    'Izin';
                                                                absen['keluar'] =
                                                                    'Izin';
                                                              }
                                                            }
                                                            updateabsenData();

                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                        child:
                                                            const Text('Izin')),
                                                    TextButton(
                                                        onPressed: () {
                                                          setState(() async {
                                                            showLoadingOverlay(
                                                                context);
                                                            bool status =
                                                                await pickImage(
                                                                    index,
                                                                    '${absen['nama']} Sakit',
                                                                    true);

                                                            if (status ||
                                                                !status) {
                                                              hideLoadingOverlay(
                                                                  context);
                                                              if (status ==
                                                                  true) {
                                                                absen['masuk'] =
                                                                    'Sakit';
                                                                absen['keluar'] =
                                                                    'Sakit';
                                                              }
                                                            }
                                                            updateabsenData();

                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                        child: const Text(
                                                            'Sakit')),
                                                    TextButton(
                                                        onPressed: () {
                                                          setState(() async {
                                                            showLoadingOverlay(
                                                                context);
                                                            bool status =
                                                                await pickImage(
                                                                    index,
                                                                    '${absen['nama']} Cuti',
                                                                    true);

                                                            if (status ||
                                                                !status) {
                                                              hideLoadingOverlay(
                                                                  context);
                                                              if (status ==
                                                                  true) {
                                                                absen['masuk'] =
                                                                    'Cuti';
                                                                absen['keluar'] =
                                                                    'Cuti';
                                                              }
                                                            }
                                                            updateabsenData();

                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                        child:
                                                            const Text('Cuti')),
                                                    //
                                                    TextButton(
                                                        onPressed: () {
                                                          setState(() async {
                                                            showLoadingOverlay(
                                                                context);
                                                            bool status =
                                                                await pickImage(
                                                                    index,
                                                                    '${absen['nama']} Alpha',
                                                                    true);

                                                            if (status ||
                                                                !status) {
                                                              hideLoadingOverlay(
                                                                  context);
                                                              if (status ==
                                                                  true) {
                                                                absen['masuk'] =
                                                                    'Alpha';
                                                                absen['keluar'] =
                                                                    'Alpha';
                                                              }
                                                            }
                                                            updateabsenData();

                                                            Navigator.pop(
                                                                context);
                                                          });
                                                        },
                                                        child: const Text(
                                                            'Alpha')),
                                                  ],
                                                );
                                              },
                                            );
                                          },
                                          icon: Icon(Icons.warning),
                                        )
                                      : SizedBox.shrink(),
                                  (absen['masuk'] == '')
                                      ? const Divider()
                                      : SizedBox.shrink(),
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
                                        );
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        (canEdit && (absen['keluar'] == ''))
                                            ? IconButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title:
                                                            Text('Hapus Photo'),
                                                        content: Text(
                                                            'Hapus photo akan merubah jam masuk anda. Yakin?'),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  'Tidak')),
                                                          TextButton(
                                                              onPressed:
                                                                  () async {
                                                                await BuktiDataHandlerAndroid
                                                                    .instance
                                                                    .deleteBukti(
                                                                  currentDate,
                                                                  absen[
                                                                      'imageName'],
                                                                );
                                                                setState(() {
                                                                  absen['photo'] =
                                                                      '';
                                                                  absen['imageName'] =
                                                                      '';
                                                                  absen['masuk'] =
                                                                      '';
                                                                  absen['firestorage'] =
                                                                      '';
                                                                  updateabsenData();

                                                                  LaporanDatabaseHandlerFirestore
                                                                      .instance
                                                                      .saveLaporanToFirestore(
                                                                          absenData,
                                                                          currentDate);
                                                                });
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  'Ya'))
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                icon: const Icon(
                                                  Icons.cancel,
                                                ),
                                              )
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
                                  ],

                                  //(rolePegawai != 'off') ?
                                  Text(
                                    'Masuk',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  //: SizedBox.shrink(),
                                  Text(
                                    absen['masuk'],
                                    style: TextStyle(),
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      (absen['photo'] ==
                                              '') //(rolePegawai != 'off' && absen['photo'] == '')
                                          ? canEdit
                                              ? IconButton(
                                                  icon: Icon((absen['photo'] ==
                                                              '' &&
                                                          absen['imageName'] ==
                                                              '')
                                                      ? Icons
                                                          .add_photo_alternate
                                                      : Icons.change_circle),
                                                  onPressed: () {
                                                    showLoadingOverlay(context);
                                                    setState(() async {
                                                      bool status =
                                                          await pickImage(
                                                              index,
                                                              absen['nama'],
                                                              true);
                                                      if (status || !status) {
                                                        hideLoadingOverlay(
                                                            context);
                                                      }
                                                      updateabsenData();
                                                    });
                                                  },
                                                )
                                              : SizedBox.shrink()
                                          : SizedBox.shrink(),
                                    ],
                                  ),
                                  //const Divider(),
                                  // Keluar Photo
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
                                        );
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
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        (canEdit && (absen['keluar'] == ''))
                                            ? IconButton(
                                                onPressed: () {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title:
                                                            Text('Hapus Photo'),
                                                        content: Text(
                                                            'Hapus photo akan merubah jam masuk anda. Yakin?'),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  'Tidak')),
                                                          TextButton(
                                                              onPressed:
                                                                  () async {
                                                                await BuktiDataHandlerAndroid
                                                                    .instance
                                                                    .deleteBukti(
                                                                  currentDate,
                                                                  absen[
                                                                      'imageName2'],
                                                                );
                                                                setState(() {
                                                                  absen['photo2'] =
                                                                      '';
                                                                  absen['imageName2'] =
                                                                      '';
                                                                  absen['keluar'] =
                                                                      '';
                                                                  absen['firestorage2'] =
                                                                      '';
                                                                  updateabsenData();
                                                                });
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  'Ya'))
                                                        ],
                                                      );
                                                    },
                                                  );
                                                },
                                                icon: const Icon(Icons.cancel),
                                              )
                                            : const SizedBox.shrink(),
                                      ],
                                    ),
                                  ],
                                  (absen['keluar'] ==
                                          '') //(rolePegawai != 'off' && absen['keluar'] == '')
                                      ? Column(
                                          children: [
                                            Text(
                                              'Keluar',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: Icon(
                                                Icons.check,
                                              ),
                                              onPressed: () {
                                                if (absen['masuk'] != '' &&
                                                    absen['keluar'] == '') {
                                                  showDialog(
                                                    context: context,
                                                    builder:
                                                        (BuildContext context) {
                                                      return AlertDialog(
                                                        title:
                                                            Text('Beres Kerja'),
                                                        content: Text(
                                                            'Apakah anda yakin untuk selasai?'),
                                                        actions: [
                                                          TextButton(
                                                              onPressed: () {
                                                                Navigator.pop(
                                                                    context);
                                                              },
                                                              child: const Text(
                                                                  'Tidak')),
                                                          TextButton(
                                                              onPressed: () {
                                                                showLoadingOverlay(
                                                                    context);
                                                                setState(
                                                                    () async {
                                                                  bool status =
                                                                      await pickImage(
                                                                          index,
                                                                          absen[
                                                                              'nama'],
                                                                          false);
                                                                  if (status ||
                                                                      !status) {
                                                                    hideLoadingOverlay(
                                                                        context);
                                                                  }
                                                                  updateabsenData();

                                                                  Navigator.pop(
                                                                      context);
                                                                  setState(() {
                                                                    print(
                                                                        photo2);
                                                                  });
                                                                });
                                                              },
                                                              child: const Text(
                                                                  'Ya'))
                                                        ],
                                                      );
                                                    },
                                                  );
                                                }
                                              },
                                            ),
                                          ],
                                        )
                                      : //(absen['role'] != 'off') ?
                                      Text(
                                          'Keluar',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                  //: SizedBox.shrink(),
                                  //(rolePegawai != 'off') ?
                                  Column(
                                    children: [
                                      Text(
                                        absen['keluar'],
                                        style: TextStyle(),
                                      ),
                                      SizedBox(
                                        height: 10,
                                      )
                                    ],
                                  ),
                                  //: SizedBox.shrink(),
                                  //(absen['role'] != 'off') ?
                                  Padding(
                                    padding: const EdgeInsets.all(8),
                                    child: TextFormField(
                                      enabled: ((absen['masuk'] == '' ||
                                              absen['keluar'] ==
                                                  '') //&& (absen['role'] != 'off')
                                          )
                                          ? true
                                          : false,
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
