import 'package:da4_management_client_point/analisis/toko_pembukuan_menu.dart';
import 'package:flutter/material.dart';
import '../backend/control.dart';

class ShopPickerAnalysisScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Pilih Toko'),
        ),
        body: Card(
          child: ListTile(
            title: Text(
              TokoID.tokoName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(TokoID.tokoID),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TokoPembukuanMenuScreen(
                    chooseTokoID: TokoID.tokoID,
                    chooseTokoName: TokoID.tokoName,
                    isPoint: true,
                  ),
                ),
              );
            },
          ),
        ));
  }
}
