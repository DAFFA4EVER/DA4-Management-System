import 'package:flutter/material.dart';
import '../../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class LaporanTokoModuleScreen extends StatefulWidget {
  @override
  State<LaporanTokoModuleScreen> createState() =>
      _LaporanTokoModuleScreenState();
}

class _LaporanTokoModuleScreenState extends State<LaporanTokoModuleScreen> {
  bool _changesMade = false;
  bool dataLoaded = false;

  List<String> pemasukkanNameList = [''];
  List<String> pengeluaranNameList = [''];

  String version = '';

  late final Map<String, dynamic> moduleSetting;

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    pengeluaranNameList = List<String>.from(moduleSetting['pengeluaran']);
    pemasukkanNameList = List<String>.from(moduleSetting['pemasukkan']);

    version = moduleSetting['version'];
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

  // Pemasukkan
  Future<void> _showEditPemasukkanDialog(
      BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaController =
        TextEditingController(text: pemasukkanNameList[index]);
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Anggota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
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
              child: Text('Ganti'),
              onPressed: () {
                pemasukkanNameList[index] = namaController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPemasukkanDialog(BuildContext context) async {
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
                pemasukkanNameList.add(namaController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeletePemasukkanDialog(
      BuildContext context, int index) async {
    final currentContext = context;
    final String namaPegawai = pemasukkanNameList[index];
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
                pemasukkanNameList.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  // Pengeluaran
  Future<void> _showEditPengeluaranDialog(
      BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaController =
        TextEditingController(text: pengeluaranNameList[index]);
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Anggota'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
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
              child: Text('Ganti'),
              onPressed: () {
                pengeluaranNameList[index] = namaController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddPengeluaranDialog(BuildContext context) async {
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
                pengeluaranNameList.add(namaController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeletePengeluaranDialog(
      BuildContext context, int index) async {
    final currentContext = context;
    final String namaPegawai = pengeluaranNameList[index];
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
                pengeluaranNameList.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateModuleToko() async {
    moduleSetting['pengeluaran'] = pengeluaranNameList;
    moduleSetting['pemasukkan'] = pemasukkanNameList;

    moduleSetting['version'] = version;

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
            actions: [],
            title: Text('Edit Module Laporan Toko'),
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
                                      updateModuleToko();
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
                          version,
                          style: const TextStyle(fontSize: 16),
                        ),
                      ),
                    ),
                    // Pengeluaran
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Jenis Pengeluaran',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pengeluaranNameList.length,
                            itemBuilder: (context, index) {
                              final pengeluaranName =
                                  pengeluaranNameList[index];
                              final int idx = index;
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(pengeluaranName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditPengeluaranDialog(
                                                context, idx);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeletePengeluaranDialog(
                                                context, idx);
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
                            _showAddPengeluaranDialog(context);
                          },
                          child: const Icon(Icons.add),
                        )
                      ]),
                    ),
                    // Pemasukkan
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Jenis Pemasukkan',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: pemasukkanNameList.length,
                            itemBuilder: (context, index) {
                              final pemasukkanName = pemasukkanNameList[index];
                              final int idx = index;
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(pemasukkanName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditPemasukkanDialog(
                                                context, idx);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeletePemasukkanDialog(
                                                context, idx);
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
                            _showAddPemasukkanDialog(context);
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
