import 'package:flutter/material.dart';
import '../backend/control.dart';
import 'laporanMenu.dart';

class ShopPickerScreen extends StatelessWidget {
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
          bool isPointShop = false;
          if (id.substring(2, 3) == '1') {
            isPointShop = true;
          }
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
                    builder: (context) => LaporanMenu(
                      chooseTokoID: id,
                      chooseTokoName: name,
                      isPoint: isPointShop,
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
