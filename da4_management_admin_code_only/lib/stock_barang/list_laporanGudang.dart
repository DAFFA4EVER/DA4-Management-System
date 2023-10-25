import 'package:flutter/material.dart';
import '../backend/gudangDataHandlerFirestore.dart';
import 'barang_gudang.dart';
import '../backend/control.dart';

class ListLaporanGudangScreen extends StatefulWidget {
  final String chooseTokoID;
  final String chooseTokoName;
  final List<String> customList;

  ListLaporanGudangScreen(
      {required this.chooseTokoID,
      required this.chooseTokoName,
      required this.customList});

  @override
  _ListLaporanGudangScreenState createState() =>
      _ListLaporanGudangScreenState();
}

class _ListLaporanGudangScreenState extends State<ListLaporanGudangScreen> {
  List<String> laporanList = [];

  bool canEdit = false;
  bool dataLoaded = false;

  @override
  void initState() {
    super.initState();
    loadLaporanList();
    if (loginState.role == 'superadmin') {
      canEdit = true;
    }
  }

  Future<void> loadLaporanList() async {
    var tempList = widget.customList;
    if (widget.customList.isEmpty) {
      tempList = await GudangLaporanDatabaseHandlerFirestore.instance
          .getLaporanGudangList();
    }

    setState(() {
      laporanList = tempList;
      dataLoaded = true;
    });
  }

  Future<bool> getUploadStatus(String selectedDate) async {
    try {
      Map<String, dynamic> jsonData =
          await GudangLaporanDatabaseHandlerFirestore.instance
              .loadLaporanGudangFromFirestore(selectedDate);
      bool isUploaded = jsonData['uploaded'] ?? false;
      return isUploaded;
    } catch (e) {
      print('Error reading JSON file: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Laporan Gudang'),
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
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              itemCount: laporanList.length,
              itemBuilder: (context, index) {
                String selectedDate = laporanList[index];
                String code = widget.chooseTokoName;
                if (widget.customList.isEmpty) {
                  String laporanName = laporanList[index];

                  selectedDate = laporanName.substring(
                    laporanName.lastIndexOf("_") + 1,
                  );
                  code = laporanName.split('_')[1];
                  if (TokoID.isTokoIDExists(code) == false) {
                    code = widget.chooseTokoName;
                  }
                }
                return (selectedDate != widget.chooseTokoID)
                    ? FutureBuilder(
                        future: GudangLaporanDatabaseHandlerFirestore.instance
                            .loadLaporanGudangFromFirestore(selectedDate),
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            // Display a loading indicator while loading laporan data
                            return Card(
                              child: ListTile(
                                leading:
                                    CircleAvatar(backgroundColor: Colors.black),
                                title: Text(code),
                                subtitle: Text(selectedDate),
                                onTap: () {},
                              ),
                            );
                          } else if (snapshot.hasError) {
                            // Display an error message if an error occurs
                            return Center(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Error loading data',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ],
                              ),
                            );
                          } else {
                            bool isFinalized =
                                snapshot.data?['uploaded'] ?? false;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: (isFinalized)
                                        ? Colors.green
                                        : Colors.red),
                                title: Text(code),
                                subtitle: Text(selectedDate),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => GudangLaporanScreen(
                                        currentdate: selectedDate,
                                        edit: canEdit,
                                        namaGudang: 'Mixue',
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          }
                        },
                      )
                    : SizedBox();
              },
            ),
    );
  }
}
