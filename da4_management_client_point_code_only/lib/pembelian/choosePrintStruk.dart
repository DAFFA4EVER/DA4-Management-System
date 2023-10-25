import 'dart:async';
import 'package:da4_management_client_point/backend/control.dart';
import 'package:da4_management_client_point/backend/laporanDataHandlerFirestore.dart';
import 'package:da4_management_client_point/pembelian/printState.dart';
import 'package:blue_thermal_printer/blue_thermal_printer.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PrintStrukPage extends StatefulWidget {
  @override
  _PrintStrukPageState createState() => _PrintStrukPageState();
}

class PrintingStruk {
  final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
  bool printSuccess = false;
  BlueThermalPrinter bluetoothPrint = BlueThermalPrinter.instance;
  final List<Map<String, dynamic>> menuItem;
  final Map<String, dynamic> pembayaranItem;
  final bool copy;
  final List<Map<String, dynamic>> pembayaranItemsBackup;
  final List<Map<String, dynamic>> lastMenuItemsBackup;
  final List<String> listOrderCodeBackup;
  final String currentDate;
  Map<String, dynamic> laporanData = {};

  PrintingStruk(
      this.menuItem,
      this.pembayaranItem,
      this.pembayaranItemsBackup,
      this.lastMenuItemsBackup,
      this.listOrderCodeBackup,
      this.currentDate,
      this.copy);

  Future<void> printReceipt(BuildContext context) async {
    try {
      bool? isConnected = await bluetoothPrint.isConnected;
      if (isConnected == null || !isConnected) {
        // Wait for the connection to complete or timeout after 10 seconds
        await bluetoothPrint.connect(printState.printer);
      }

      // Size
      // 0: Normal
      // 1: Normal - Bold
      // 2: Medium - Bold
      // 3: Large - Bold

      // Align
      // 0: Left
      // 1: Center
      // 2: Right

      if ((await bluetoothPrint.isConnected)!) {
        bluetoothPrint.printNewLine();
        bluetoothPrint.printCustom("${TokoID.tokoName}", 3, 1);

        bluetoothPrint.printNewLine();
        bluetoothPrint.printCustom("${pembayaranItem['order']}", 1, 1);
        bluetoothPrint.printNewLine();
        bluetoothPrint.printCustom("Struk", 1, 1);
        if (copy) {
          bluetoothPrint.printCustom("(Copy)", 1, 1);
        }
        bluetoothPrint.printNewLine();
        bluetoothPrint.printCustom(
            "No. ${pembayaranItem['order'].substring(pembayaranItem['order'].length - 4)}",
            1,
            1);
        bluetoothPrint.printNewLine();
        for (var item in menuItem) {
          bluetoothPrint.printLeftRight(
              "${item['name']} (${item['type']})", "x${item['quantity']}", 0);
          bluetoothPrint.printLeftRight("", f.format(item['jual']), 0);
          bluetoothPrint.printNewLine();
        }

        bluetoothPrint.printNewLine();
        bluetoothPrint.printLeftRight(
            "Total", f.format(pembayaranItem['jumlah']), 0);
        bluetoothPrint.printLeftRight(
            "Payment Type", pembayaranItem['type'], 0);
        bluetoothPrint.printLeftRight(
            "Date", DateFormat('yyyy-MM-dd').format(DateTime.now()), 0);
        bluetoothPrint.printLeftRight("Order Time", pembayaranItem['time'], 0);
        bluetoothPrint.printNewLine();
        bluetoothPrint.printCustom("Terima Kasih", 1, 1);
        bluetoothPrint.printCustom("Selamat Menikmati", 1, 1);
        bluetoothPrint.printNewLine();
        bluetoothPrint.printNewLine();

        // Wait for the disconnect to complete or timeout after 10 seconds
        printState.printingDone();
        printSuccess = true;
      }
    } catch (e) {
      print('<------------------------>');
      print(printSuccess);
      print('<------------------------>');

      print("Connection to printer timed out!");
      // Attempt to disconnect from the printer here
      if ((await bluetoothPrint.isConnected)!) {
        await bluetoothPrint.disconnect();
      }
      printState.resetState();
    }
  }
}

class _PrintStrukPageState extends State<PrintStrukPage> {
  BlueThermalPrinter bluetoothPrint = BlueThermalPrinter.instance;
  List<BluetoothDevice> availableDevices = [];
  String deviceMsg = "";
  bool printSuccess = false;
  final f = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ');
  Map<String, dynamic> laporanData = {};

  @override
  void initState() {
    super.initState();
    initPrinter();
  }

  void initPrinter() async {
    try {
      availableDevices = await bluetoothPrint.getBondedDevices();
      setState(() {});
    } catch (e) {
      print('Error fetching bonded devices: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pilih Printer Struk'),
      ),
      body: availableDevices.isEmpty
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
          : Scrollbar(
              child: ListView.builder(
                itemCount: availableDevices.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    leading: Icon(Icons.print),
                    title: Text("${availableDevices[index].name}"),
                    subtitle: Text("${availableDevices[index].address}"),
                    onTap: () async {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (context) {
                          return AlertDialog(
                              title: Text(
                                  'Connecting to ${availableDevices[index].name}'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Center(child: CircularProgressIndicator()),
                                ],
                              ));
                        },
                      );
                      printState.printerDefault(availableDevices[index]);
                      Navigator.pop(context);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
    );
  }
}
