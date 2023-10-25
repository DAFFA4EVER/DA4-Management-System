import 'package:da4_management/pengaturan/module/absen%20module/list_shop_absen_anggota.dart';
import 'package:da4_management/pengaturan/module/absen%20module/absen_rule.dart';
import 'package:flutter/material.dart';
import '../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AbsenModuleScreen extends StatefulWidget {
  @override
  State<AbsenModuleScreen> createState() => _AbsenModuleScreenState();
}

class _AbsenModuleScreenState extends State<AbsenModuleScreen> {
  List<dynamic> absenShiftMap = [];
  bool _changesMade = false;
  bool dataLoaded = false;
  bool editShift = false;
  List<String> shiftNameList = ['off'];
  List<String> roleNameList = [''];
  int penalty = 0;
  String version = '';
  late final Map<String, dynamic> moduleSetting;

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    dataLoaded = true;

    absenShiftMap = moduleSetting['shiftAbsen'];
    roleNameList = List<String>.from(moduleSetting['roleAbsen']);
    penalty = moduleSetting['penalty'];
    for (final shiftName in absenShiftMap) {
      if (shiftNameList.contains(shiftName['shift']) == false) {
        shiftNameList.add(shiftName['shift']);
      }
    }
    version = moduleSetting['version'];
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
          '${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';

      controller.text = formattedTime;
      if (controller.text != formattedTime) {
        _changesMade = true;
      }
    }
  }

  void _showBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          // Your bottom sheet content here
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                  title: Row(
                    children: [
                      Icon(Icons.timelapse),
                      SizedBox(
                        width: 16,
                      ),
                      Text('Edit Shift'),
                    ],
                  ),
                  value: editShift,
                  onChanged: (value) {
                    setState(() {
                      Navigator.pop(context);
                      editShift = value;
                    });
                  }),
              ListTile(
                leading: Icon(Icons.people_rounded),
                title: Text('Edit Anggota'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) =>
                              ShopPickerAbsenAnggotaScreen()));
                },
              ),
              ListTile(
                leading: Icon(Icons.rule),
                title: Text('Edit Aturan'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => AbsenRuleModuleScreen()));
                  // Handle the 'Delete' action here
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> updateModuleAbsen() async {
    moduleSetting['shiftAbsen'] = absenShiftMap;
    moduleSetting['roleAbsen'] = roleNameList;
    moduleSetting['penalty'] = penalty;
    moduleSetting['version'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await ModuleHandler().uploadDataModule(moduleSetting);
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
            actions: [
              IconButton(
                  onPressed: () {
                    _showBottomSheet(context);
                  },
                  icon:
                      (dataLoaded == true) ? Icon(Icons.settings) : Icon(null))
            ],
            title: Text('Edit Module Absen'),
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
                      print(absenShiftMap);
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
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: absenShiftMap.length,
                      itemBuilder: (context, index) {
                        final TextEditingController shiftName =
                            TextEditingController(
                                text: absenShiftMap[index]['shift']);
                        final TextEditingController shiftIn =
                            TextEditingController(
                                text:
                                    absenShiftMap[index]['time'].split('-')[0]);
                        final TextEditingController shiftOut =
                            TextEditingController(
                                text:
                                    absenShiftMap[index]['time'].split('-')[1]);
                        return Card(
                          margin: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      "Shift ",
                                      style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold),
                                    ),
                                    (editShift == true)
                                        ? DropdownButton<String>(
                                            value: shiftName.text,
                                            items: shiftNameList
                                                .map((String option) {
                                              return DropdownMenuItem<String>(
                                                value: option,
                                                child: Text(
                                                  option
                                                          .substring(0, 1)
                                                          .toUpperCase() +
                                                      option
                                                          .substring(1)
                                                          .toLowerCase(),
                                                  style: TextStyle(
                                                      fontSize: 24,
                                                      fontWeight:
                                                          FontWeight.bold),
                                                ),
                                              );
                                            }).toList(), // Convert to a set to remove duplicate values, then convert back to a list
                                            onChanged: (newValue) {
                                              setState(() {
                                                shiftName.text = newValue ??
                                                    shiftNameList.first;
                                                absenShiftMap[index]['shift'] =
                                                    shiftName.text;
                                                print(shiftName.text);
                                              });
                                            },
                                          )
                                        : Text(
                                            shiftName.text
                                                    .substring(0, 1)
                                                    .toUpperCase() +
                                                shiftName.text
                                                    .substring(1)
                                                    .toLowerCase(),
                                            style: TextStyle(
                                                fontSize: 24,
                                                fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceAround,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Masuk',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          shiftIn.text,
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                        (editShift == true)
                                            ? IconButton(
                                                onPressed: () async {
                                                  await _showTimePicker(
                                                      shiftIn, index);
                                                  print('Hey');
                                                  //
                                                  List<String> timeParts =
                                                      absenShiftMap[index]
                                                              ['time']
                                                          .split('-');
                                                  timeParts[0] = shiftIn.text;
                                                  String updatedTimeString =
                                                      timeParts.join('-');
                                                  absenShiftMap[index]['time'] =
                                                      updatedTimeString;
                                                  //
                                                  setState(() {});
                                                },
                                                icon: Icon(Icons.alarm))
                                            : SizedBox.shrink()
                                      ],
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      children: [
                                        Text(
                                          'Keluar',
                                          style: TextStyle(
                                              fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          shiftOut.text,
                                          style: TextStyle(
                                              fontWeight: FontWeight.normal),
                                        ),
                                        (editShift == true)
                                            ? IconButton(
                                                onPressed: () async {
                                                  await _showTimePicker(
                                                      shiftOut, index);
                                                  print('Huy');
                                                  //
                                                  List<String> timeParts =
                                                      absenShiftMap[index]
                                                              ['time']
                                                          .split('-');
                                                  timeParts[1] = shiftOut.text;
                                                  String updatedTimeString =
                                                      timeParts.join('-');
                                                  absenShiftMap[index]['time'] =
                                                      updatedTimeString;
                                                  //
                                                  setState(() {});
                                                },
                                                icon: Icon(Icons.alarm))
                                            : SizedBox.shrink()
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                )),
    );
  }
}
