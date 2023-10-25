import 'package:da4_management_client_point/main_menu.dart';
import 'package:da4_management_client_point/pembelian/add_pesanan.dart';
import 'package:da4_management_client_point/pembelian/choosePrintStruk.dart';
import 'package:da4_management_client_point/pembelian/list_pesanan.dart';
import '../pengaturan/pengaturanMenu.dart';
import 'package:da4_management_client_point/pembelian/printState.dart';
import 'package:flutter/material.dart';

class PembelianMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
                builder: (context) => MainMenu(), maintainState: false),
            (route) => false,
          );
          return true;
        },
        child: Scaffold(
          bottomNavigationBar:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PengaturanMenu(),
                      maintainState: false),
                  (route) => false,
                );
              },
              icon: Icon(
                Icons.settings,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => MainMenu(), maintainState: false),
                  (route) => false,
                );
              },
              icon: Icon(
                Icons.home,
              ),
            ),
            Card(
              color: Theme.of(context).colorScheme.onBackground,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.food_bank,
                  color: Theme.of(context).colorScheme.background,
                ),
              ),
            ),
          ]),
          appBar: AppBar(
            title: const Text('Pembelian'),
          ),
          body: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        if (printState.printer.name != '' &&
                            printState.printer.address != '') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ListPesanan(
                                      currentdate: '',
                                      edit: true,
                                    )),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PrintStrukPage(),
                                maintainState: false),
                          );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.list_alt),
                            SizedBox(height: 8.0),
                            Text('List Pesanan'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Card(
                    child: InkWell(
                      onTap: () {
                        if (printState.printer.name != '' &&
                            printState.printer.address != '') {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => AddPesanan()),
                          );
                        } else {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => PrintStrukPage(),
                                maintainState: false),
                          );
                        }
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add),
                            SizedBox(height: 8.0),
                            Text('Tambah Pesanan'),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ));
  }
}
