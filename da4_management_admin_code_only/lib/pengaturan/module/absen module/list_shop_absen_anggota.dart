import 'package:flutter/material.dart';
import '../../../backend/control.dart';
import 'absen_anggota.dart';

class ShopPickerAbsenAnggotaScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Anggota Toko'),
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
                    builder: (context) => AbsenAnggotaModuleScreen(
                      chooseTokoID: id,
                      chooseTokoName: name,
                    ),
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
