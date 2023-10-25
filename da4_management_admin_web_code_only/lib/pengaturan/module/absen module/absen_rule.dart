import 'package:flutter/material.dart';
import '../../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AbsenRuleModuleScreen extends StatefulWidget {
  @override
  State<AbsenRuleModuleScreen> createState() => _AbsenRuleModuleScreenState();
}

class _AbsenRuleModuleScreenState extends State<AbsenRuleModuleScreen> {
  List<dynamic> absenShiftMap = [];
  bool _changesMade = false;
  bool dataLoaded = false;
  bool editShift = false;
  List<String> shiftNameList = ['off'];
  List<String> roleNameList = [''];
  Map<String, int> timeTolerance = {};
  int penalty = 0;
  String version = '';
  late final Map<String, dynamic> moduleSetting;

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  Future<void> updateModuleAbsen() async {
    moduleSetting['shiftAbsen'] = absenShiftMap;
    moduleSetting['roleAbsen'] = roleNameList;
    moduleSetting['penalty'] = penalty;
    moduleSetting['version'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    moduleSetting['waktuToleransi'] = timeTolerance;
    await ModuleHandler().uploadDataModule(moduleSetting);
  }

  void setUpModule() {
    dataLoaded = true;

    absenShiftMap = moduleSetting['shiftAbsen'];
    roleNameList = List<String>.from(moduleSetting['roleAbsen']);
    penalty = moduleSetting['penalty'];
    version = moduleSetting['version'];
    timeTolerance = Map<String, int>.from(moduleSetting['waktuToleransi']);
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

  Future<void> _showTimePicker(TextEditingController controller) async {
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
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
      setState(() {
        controller.text = formattedTime;
        if (controller.text != formattedTime) {
          _changesMade = true;
        }
      });
    }
  }

  String capitalize(String text) {
    return text.substring(0, 1).toUpperCase() + text.substring(1);
  }

  // Role
  Future<void> _showEditRoleDialog(BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaRoleController =
        TextEditingController(text: roleNameList[index]);
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Nama Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaRoleController,
                onChanged: (value) {},
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ganti'),
              onPressed: () {
                roleNameList[index] = namaRoleController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddRoleDialog(BuildContext context) async {
    final currentContext = context;
    final TextEditingController namaRoleController = TextEditingController();
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Role'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Role'),
                controller: namaRoleController,
                onChanged: (value) {},
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Tambah'),
              onPressed: () {
                roleNameList.add(namaRoleController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteRoleDialog(BuildContext context, int index) async {
    final currentContext = context;
    final String namaRolePegawai = roleNameList[index];
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Role ${capitalize(namaRolePegawai)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Apakah anda yakin untuk menghapus Role ${capitalize(namaRolePegawai)}')
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                roleNameList.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  // Shift
  Future<void> _showEditShiftDialog(BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaShiftController =
        TextEditingController(text: absenShiftMap[index]['shift']);
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Nama Shift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: namaShiftController,
                onChanged: (value) {},
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Ganti'),
              onPressed: () {
                absenShiftMap[index]['shift'] = namaShiftController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddShiftDialog(BuildContext context) async {
    final currentContext = context;
    final TextEditingController namaShiftController = TextEditingController();
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Shift'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Shift'),
                controller: namaShiftController,
                onChanged: (value) {},
              )
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Tambah'),
              onPressed: () {
                absenShiftMap.add(
                    {'shift': namaShiftController.text, 'time': '00:00-00:00'});
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteShiftDialog(BuildContext context, int index) async {
    final currentContext = context;
    final String namaShiftPegawai = absenShiftMap[index]['shift'];
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus Shift ${capitalize(namaShiftPegawai)}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Apakah anda yakin untuk menghapus Shift ${capitalize(namaShiftPegawai)}')
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Hapus'),
              onPressed: () {
                absenShiftMap.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
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
        return true;
      },
      child: Scaffold(
          appBar: AppBar(
            actions: [],
            title: Text('Edit Aturan Absen'),
          ),
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
                                      updateModuleAbsen();
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
                      print(penalty);
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
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
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
                          version,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Keterlambatan',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Masuk Toleransi
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: timeTolerance['masuk'].toString(),
                            decoration: InputDecoration(
                                labelText: 'Toleransi masuk (menit)'),
                            inputFormatters: [],
                            onChanged: (value) {
                              timeTolerance['masuk'] = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        // Istirahat Toleransi
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: timeTolerance['istirahat'].toString(),
                            decoration: InputDecoration(
                                labelText: 'Toleransi istirahat (menit)'),
                            inputFormatters: [],
                            onChanged: (value) {
                              timeTolerance['istirahat'] =
                                  int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        // Keluar Toleransi
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: timeTolerance['keluar'].toString(),
                            decoration: InputDecoration(
                                labelText: 'Toleransi keluar (menit)'),
                            inputFormatters: [],
                            onChanged: (value) {
                              timeTolerance['keluat'] =
                                  int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                        // Denda
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextFormField(
                            keyboardType: TextInputType.number,
                            initialValue: penalty.toString(),
                            decoration: InputDecoration(
                                labelText: 'Denda (Rupiah)/menit'),
                            inputFormatters: [],
                            onChanged: (value) {
                              penalty = int.tryParse(value) ?? 0;
                            },
                          ),
                        ),
                      ]),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Shift',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: absenShiftMap.length,
                            itemBuilder: (context, index) {
                              final shiftName = absenShiftMap[index]['shift'];

                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    Shift ${capitalize(shiftName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            print(index);
                                            _showEditShiftDialog(
                                                context, index);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeleteShiftDialog(
                                                context, index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ElevatedButton(
                          onPressed: () {
                            _showAddShiftDialog(context);
                            setState(() {});
                          },
                          child: const Icon(Icons.add),
                        )
                      ]),
                    ),
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Role',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: roleNameList.length,
                            itemBuilder: (context, index) {
                              final shiftName = roleNameList[index];
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(shiftName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditRoleDialog(context, index);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeleteRoleDialog(
                                                context, index);
                                          },
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ElevatedButton(
                          onPressed: () {
                            _showAddRoleDialog(context);
                            setState(() {});
                          },
                          child: const Icon(Icons.add),
                        )
                      ]),
                    ),
                  ],
                )),
    );
  }
}
