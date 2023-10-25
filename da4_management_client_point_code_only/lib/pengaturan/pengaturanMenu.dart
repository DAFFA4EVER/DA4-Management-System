import 'package:da4_management_client_point/main_menu.dart';
import 'package:da4_management_client_point/pembelian/choosePrintStruk.dart';
import 'package:da4_management_client_point/pembelian/pembelian.dart';
import 'package:flutter/material.dart';
import 'list_menu_page.dart';
import 'list_stock_page.dart';

class PengaturanMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => MainMenu()),
            (route) => false,
          );
          return true;
        },
        child: Scaffold(
          bottomNavigationBar:
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
            Card(
              color: Theme.of(context).colorScheme.onBackground,
              child: IconButton(
                onPressed: () {},
                icon: Icon(
                  Icons.settings,
                  color: Theme.of(context).colorScheme.background,
                ),
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
            IconButton(
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                      builder: (context) => PembelianMenu(),
                      maintainState: false),
                  (route) => false,
                );
              },
              icon: Icon(Icons.food_bank),
            ),
          ]),
          appBar: AppBar(
            title: const Text('Pengaturan'),
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ListMenuScreen()));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.menu_book),
                            SizedBox(height: 8.0),
                            Text('Lihat Menu Toko'),
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
                        Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => ListStockScreen()));
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_cart),
                            SizedBox(height: 8.0),
                            Text('Lihat Barang'),
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
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => PrintStrukPage(),
                              maintainState: false),
                        );
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.print),
                            SizedBox(height: 8.0),
                            Text('Printer Setting'),
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
