import 'package:flutter/material.dart';
import '../../../backend/moduleDataHandler.dart';
import '../../../backend/absenHandler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AbsenAnggotaModuleScreen extends StatefulWidget {
  final String chooseTokoID;
  final String chooseTokoName;

  AbsenAnggotaModuleScreen(
      {required this.chooseTokoID, required this.chooseTokoName});

  @override
  State<AbsenAnggotaModuleScreen> createState() =>
      _AbsenAnggotaModuleScreenState();
}

class _AbsenAnggotaModuleScreenState extends State<AbsenAnggotaModuleScreen> {
  List<dynamic> absenShiftMap = [];
  bool _changesMade = false;
  bool dataLoaded = false;
  bool editShift = false;
  List<String> shiftNameList = ['off'];
  List<String> roleNameList = [''];
  int penalty = 0;
  String tanggal = '';
  Map<String, dynamic> absenData = {};
  late final Map<String, dynamic> moduleSetting;
  late var jadwalData = [];
  List<String> listPegawai = [];
  List<Map<String, dynamic>> listGajiPegawai = [];

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    absenShiftMap = moduleSetting['shiftAbsen'];
    roleNameList = List<String>.from(moduleSetting['roleAbsen']);
    penalty = moduleSetting['penalty'];
    listPegawai = List<String>.from(jadwalData[7]['pegawai']);
    tanggal = jadwalData[7]['version'];
    listGajiPegawai = List<Map<String, dynamic>>.from(jadwalData[7]['gaji']);

    dataLoaded = true;
    setState(() {});
  }

  Future<void> getModuleSetting() async {
    if ((await ModuleHandler().checkModuleExist()) == true) {
      moduleSetting = await ModuleHandler().getModuleData();
    } else {
      await ModuleHandler().uploadModuleDataDefault();
      moduleSetting = await ModuleHandler().getModuleData();
    }
    jadwalData = await loadJadwalFromFirestore(widget.chooseTokoID);
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

  Future<void> _showEditDialog(BuildContext context, int index) async {
    final currentContext = context;
    int p = index;
    final TextEditingController namaController =
        TextEditingController(text: listPegawai[index]);
    if (namaController.text != listGajiPegawai[index]) {
      p = listGajiPegawai
          .indexWhere((element) => element['nama'] == namaController.text);
    }
    final TextEditingController gajiPokokController =
        TextEditingController(text: listGajiPegawai[p]['gaji'].toString());
    final TextEditingController gajiTunjanganController =
        TextEditingController(text: listGajiPegawai[p]['tunjangan'].toString());
    final TextEditingController gajiBonusController =
        TextEditingController(text: listGajiPegawai[p]['bonus'].toString());

    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Anggota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Nama
              TextFormField(
                controller: namaController,
                decoration: InputDecoration(labelText: 'Nama'),
                onChanged: (value) {},
              ),
              // Gaji Pokok
              TextFormField(
                controller: gajiPokokController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Gaji Pokok (Rupiah)'),
                onChanged: (value) {},
              ),
              // Gaji Tunjangan
              TextFormField(
                controller: gajiTunjanganController,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: 'Gaji Tunjangan (Rupiah)'),
                onChanged: (value) {},
              ),
              // Gaji Bonus
              TextFormField(
                controller: gajiBonusController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: 'Gaji Bonus (Rupiah)'),
                onChanged: (value) {},
              ),
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
                listPegawai[index] = namaController.text;
                listGajiPegawai[p]['gaji'] =
                    int.tryParse(gajiPokokController.text);
                listGajiPegawai[p]['tunjangan'] =
                    int.tryParse(gajiTunjanganController.text);
                listGajiPegawai[p]['bonus'] =
                    int.tryParse(gajiBonusController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddDialog(BuildContext context) async {
    final currentContext = context;
    final TextEditingController namaController = TextEditingController();
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Tambah Anggota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Nama'),
                controller: namaController,
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
                listPegawai.add(namaController.text);
                listGajiPegawai.add({
                  'nama': namaController.text,
                  'gaji': 1600000,
                  'tunjangan': 500000,
                  'bonus': 100000
                });
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(BuildContext context, int index) async {
    final currentContext = context;
    final String namaPegawai = listPegawai[index];
    int p = index;
    if (namaPegawai != listGajiPegawai[index]) {
      p = listGajiPegawai
          .indexWhere((element) => element['nama'] == namaPegawai);
    }
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Hapus ${namaPegawai}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Apakah anda yakin untuk menghapus ${namaPegawai}')
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
                listPegawai.removeAt(index);
                listGajiPegawai.removeAt(p);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showConfirmationDialog(BuildContext context) async {
    final currentContext = context;
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Konfirmasi'),
          content: Text(
            'Apakah anda yakin?',
            textAlign: TextAlign.left,
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
                print('Cancel');
              },
            ),
            TextButton(
              child: Text('Tidak'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                print('Tidak');
              },
            ),
            TextButton(
              child: Text('Ya'),
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pop();
                print('Done');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateModuleAbsen() async {
    moduleSetting['shiftAbsen'] = absenShiftMap;
    moduleSetting['roleAbsen'] = roleNameList;
    moduleSetting['penalty'] = penalty;
    jadwalData[7]['pegawai'] = listPegawai;
    jadwalData[7]['version'] = DateFormat('yyyy-MM-dd').format(DateTime.now());
    jadwalData[7]['gaji'] = listGajiPegawai;
    await ModuleHandler().uploadDataModule(moduleSetting);
    updateJadwalToFirestore(
        widget.chooseTokoID, List<Map<String, dynamic>>.from(jadwalData));
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
            title: Text('Edit Anggota Absen'),
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
                          tanggal,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    Card(
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
                          widget.chooseTokoName,
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
                            'Daftar Anggota',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: listPegawai.length,
                            itemBuilder: (context, index) {
                              final pegawaiName = listPegawai[index];
                              final int idx = index;
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(pegawaiName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditDialog(context, idx);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeleteDialog(context, idx);
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
                            _showAddDialog(context);
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
