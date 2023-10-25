import 'package:da4_management_client/analisis/toko_pembukuan_menu.dart';
import 'package:flutter/material.dart';
import '../backend/control.dart';

class ShopPickerAnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Toko'),
      ),
      body: ListView.builder(
        itemCount: TokoID.tokoID.length,
        itemBuilder: (context, index) {
          String id = TokoID.tokoID;
          String name = TokoID.tokoName;
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
                    builder: (context) => TokoPembukuanMenuScreen(
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
