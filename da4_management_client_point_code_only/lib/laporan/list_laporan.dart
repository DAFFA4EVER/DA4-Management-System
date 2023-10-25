import 'package:da4_management_client_point/laporan/laporan_point_currentDateForm.dart';
import 'package:flutter/material.dart';
import '../backend/laporanDataHandlerFirestore.dart';
import '../backend/control.dart';
import 'package:intl/intl.dart';

class ListLaporanScreen extends StatefulWidget {
  @override
  _ListLaporanScreenState createState() => _ListLaporanScreenState();
}

class _ListLaporanScreenState extends State<ListLaporanScreen> {
  List<String> laporanList = [];

  bool canEdit = false;

  @override
  void initState() {
    super.initState();
    loadLaporanList();
    if (loginState.role == 'superadmin' || loginState.role == 'admin') {
      canEdit = true;
    }
  }

  Future<void> loadLaporanList() async {
    final tempList =
        await LaporanDatabaseHandlerFirestore.instance.getLaporanList();
    setState(() {
      laporanList = tempList;
    });
  }

  Future<void> showConfirmationDialog(String laporanPath) async {
    String laporanName = laporanPath.split('/').last;
    String selectedDate = laporanName.substring(
      laporanName.lastIndexOf("_") + 1,
      laporanName.lastIndexOf("."),
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
                    .deleteLaporan(selectedDate);
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
      body: Scrollbar(
        child: ListView.builder(
          itemCount: laporanList.length,
          itemBuilder: (context, index) {
            String laporanName = laporanList[index];
      
            String selectedDate = laporanName.substring(
              laporanName.lastIndexOf("_") + 1,
            );
      
            String code = laporanName.split('_')[1];
            if (code == TokoID.tokoID) {
              code = TokoID.tokoName;
            }
      
            return (selectedDate != TokoID.tokoID)
                ? FutureBuilder(
                    future: LaporanDatabaseHandlerFirestore.instance
                        .loadLaporanFromFirestore(
                      selectedDate,
                    ),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        // Display a loading indicator while loading laporan data
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: Colors.black),
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
                                    fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                            ],
                          ),
                        );
                      } else {
                        bool isFinalized = snapshot.data?['uploaded'] ?? false;
                        return Card(
                          child: ListTile(
                            leading: CircleAvatar(
                                backgroundColor:
                                    (isFinalized) ? Colors.green : Colors.red),
                            title: Text(code),
                            subtitle: Text(selectedDate),
                            onTap: () {
                              Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => LaporanTodayPointScreen(
                                            currentdate: selectedDate,
                                            edit: true,
                                          )));
                            },
                          ),
                        );
                      }
                    },
                  )
                : SizedBox();
          },
        ),
      ),
    );
  }
}
