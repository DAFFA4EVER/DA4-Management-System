import 'package:da4_management/pengaturan/backup/list_laporanBackup.dart';
import 'package:flutter/material.dart';
import '../../backend/control.dart';

class ShopPickerBackupScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Toko'),
      ),
      body: ListView.builder(
        itemCount: TokoID.tokoID.length,
        itemBuilder: (context, index) {
          String id = TokoID.tokoID[index].keys.first;
          String name = TokoID.tokoID[index].values.first;

          return Card(
            child: ListTile(
              title: Text(
                name,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              subtitle: Text(id),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ListLaporanBackupScreen(
                        chooseTokoID: id,
                        chooseTokoName: name,
                        customList: const []),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
