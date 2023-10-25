import 'package:flutter/material.dart';
import '../../../backend/moduleDataHandler.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class MenuItemModuleScreen extends StatefulWidget {
  @override
  State<MenuItemModuleScreen> createState() => _MenuItemModuleScreenState();
}

class _MenuItemModuleScreenState extends State<MenuItemModuleScreen> {
  bool _changesMade = false;
  bool dataLoaded = false;

  List<String> menuNameList = [''];

  String version = '';

  late final Map<String, dynamic> moduleSetting;

  @override
  void initState() {
    super.initState();
    getModuleSetting();
  }

  void setUpModule() {
    menuNameList = List<String>.from(moduleSetting['menu']);

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

  // menu
  Future<void> _showEditMenuDialog(BuildContext context, int index) async {
    final currentContext = context;
    final TextEditingController namaController =
        TextEditingController(text: menuNameList[index]);
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
                menuNameList[index] = namaController.text;
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showAddMenuDialog(BuildContext context) async {
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
                menuNameList.add(namaController.text);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteMenuDialog(BuildContext context, int index) async {
    final currentContext = context;
    final String namaPegawai = menuNameList[index];
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
                menuNameList.removeAt(index);
                Navigator.of(context).pop();
                setState(() {});
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> updateModuleMenu() async {
    moduleSetting['menu'] = menuNameList;

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
            title: Text('Edit Module Menu'),
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
                                      updateModuleMenu();
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

                    // menu
                    Card(
                      margin: const EdgeInsets.all(16),
                      child: Column(children: [
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Text(
                            'Daftar Jenis Menu',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: menuNameList.length,
                            itemBuilder: (context, index) {
                              final menuName = menuNameList[index];
                              final int idx = index;
                              return Card(
                                elevation: 2,
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '    ${capitalize(menuName)}',
                                      style: TextStyle(fontSize: 16),
                                    ),
                                    Row(
                                      children: [
                                        IconButton(
                                          icon: Icon(Icons.edit),
                                          onPressed: () {
                                            _showEditMenuDialog(context, idx);
                                          },
                                        ),
                                        IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _showDeleteMenuDialog(context, idx);
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
                            _showAddMenuDialog(context);
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
