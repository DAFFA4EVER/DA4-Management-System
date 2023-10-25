import 'package:da4_management/laporan/laporan_point_currentDateForm.dart';
import 'package:flutter/material.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import 'laporan_readySetor.dart';
import '../backend/control.dart';

class ListLaporanScreen extends StatefulWidget {
  final String chooseTokoID;
  final String chooseTokoName;
  final List<String> customList;

  ListLaporanScreen(
      {required this.chooseTokoID,
      required this.chooseTokoName,
      required this.customList});

  @override
  _ListLaporanScreenState createState() => _ListLaporanScreenState();
}

class _ListLaporanScreenState extends State<ListLaporanScreen> {
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
      tempList = await LaporanDatabaseHandlerFirestore.instance
          .getLaporanList(widget.chooseTokoName);
    }

    setState(() {
      laporanList = tempList;
      dataLoaded = true;
    });
  }

  Future<bool> getUploadStatus(String selectedDate) async {
    try {
      Map<String, dynamic> jsonData = await LaporanDatabaseHandlerFirestore
          .instance
          .loadLaporanFromFirestore(selectedDate, widget.chooseTokoID);
      bool isUploaded = jsonData['uploaded'] ?? false;
      return isUploaded;
    } catch (e) {
      print('Error reading JSON file: $e');
      return false;
    }
  }

  Future<void> showConfirmationDialog(String laporanPath) async {
    String laporanName = laporanPath.split('/').last;
    String selectedDate = laporanName.substring(
      laporanName.lastIndexOf("_") + 1,
    );
    String message = 'Are you sure you want to delete this laporan?';

    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () async {
                await LaporanDatabaseHandlerFirestore.instance
                    .deleteLaporan(selectedDate, widget.chooseTokoID);
                Navigator.of(context).pop();
                loadLaporanList(); // Refresh the laporan list after deletion
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('List Laporan'),
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
                        future: LaporanDatabaseHandlerFirestore.instance
                            .loadLaporanFromFirestore(
                                selectedDate, widget.chooseTokoID),
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
                                snapshot.data?['sudahSetor'] ?? false;
                            bool isPoint = snapshot.data?['point'] ?? false;
                            return Card(
                              child: ListTile(
                                leading: CircleAvatar(
                                    backgroundColor: (isFinalized)
                                        ? Colors.green
                                        : Colors.red),
                                title: Text(code),
                                subtitle: Text(selectedDate),
                                onTap: () {
                                  print(isPoint);
                                  if (isPoint) {
                                    print('Point Screen');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LaporanTodayPointScreen(
                                          currentdate: selectedDate,
                                          edit: canEdit,
                                          chooseTokoID: widget.chooseTokoID,
                                        ),
                                      ),
                                    );
                                  } else {
                                    print('Non Point Screen');
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            LaporanSetorScreen(
                                          currentdate: selectedDate,
                                          edit: canEdit,
                                          chooseTokoID: widget.chooseTokoID,
                                        ),
                                      ),
                                    );
                                  }
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
