import 'package:flutter/material.dart';
import '../../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class GudangBarangModuleScreen extends StatefulWidget {
  @override
  State<GudangBarangModuleScreen> createState() =>
      _GudangBarangModuleScreenState();
}

class _GudangBarangModuleScreenState extends State<GudangBarangModuleScreen> {
  bool _changesMade = false;
  bool dataLoaded = false;

  List<String> barangNameList = [''];
  List<String> unitNameList = [''];

  String version = '';

  late final Map<String, dynamic> moduleSetting;

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    unitNameList = List<String>.from(moduleSetting['unit']);
    barangNameList = List<String>.from(moduleSetting['barang']);

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

  // barang
  Future<void> _showEditBarangDialog(BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaController =
        TextEditingController(text: barangNameList[index]);
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
                barangNameList[index] = namaController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddBarangDialog(BuildContext context) async {
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
                barangNameList.add(namaController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteBarangDialog(BuildContext context, int index) async {
    final currentContext = context;
    final String namaPegawai = barangNameList[index];
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
                barangNameList.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  // unit
  Future<void> _showEditUnitDialog(BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaController =
        TextEditingController(text: unitNameList[index]);
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
                unitNameList[index] = namaController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddUnitDialog(BuildContext context) async {
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
                unitNameList.add(namaController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteUnitDialog(BuildContext context, int index) async {
    final currentContext = context;
    final String namaPegawai = unitNameList[index];
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
                unitNameList.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateModuleBarang() async {
    moduleSetting['unit'] = unitNameList;
    moduleSetting['barang'] = barangNameList;

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
            title: Text('Edit Module Barang Gudang'),
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
                                      updateModuleBarang();
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
                    // unit
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Jenis Unit',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: unitNameList.length,
                            itemBuilder: (context, index) {
                              final unitName = unitNameList[index];
                              final int idx = index;
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(unitName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditUnitDialog(context, idx);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeleteUnitDialog(context, idx);
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
                            _showAddUnitDialog(context);
                          },
                          child: const Icon(Icons.add),
                        )
                      ]),
                    ),
                    // barang
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Jenis Barang',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: barangNameList.length,
                            itemBuilder: (context, index) {
                              final barangName = barangNameList[index];
                              final int idx = index;
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(barangName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditBarangDialog(context, idx);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeleteBarangDialog(
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
                            _showAddBarangDialog(context);
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
