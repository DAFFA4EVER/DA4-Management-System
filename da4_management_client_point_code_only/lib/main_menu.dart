import 'package:da4_management_client_point/analisis/analisisMenu.dart';
import 'package:da4_management_client_point/pembelian/pembelian.dart';
import 'pengaturan/pengaturanMenu.dart';
import 'barang/barangMenu.dart';
import 'laporan/laporanMenu.dart';
import 'package:flutter/material.dart';
import 'backend/control.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'main.dart';

class MainMenu extends StatelessWidget {
  void _logout(BuildContext context) async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
            TextButton(
              child: Text('Logout'),
              onPressed: () async {
                try {
                  await FirebaseAuth.instance.signOut();
                  // Perform any additional logout logic here

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  print('Logout error: $e');
                  showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Error'),
                        content: Text('Logout failed.'),
                        actions: [
                          TextButton(
                            child: Text('OK'),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                        ],
                      );
                    },
                  );
                }
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
      bottomNavigationBar:
          Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
        IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => PengaturanMenu(),maintainState: false), (route) => false,
            );
          },
          icon: Icon(
            Icons.settings,
          ),
        ),
        Card(
          color: Theme.of(context).colorScheme.onBackground,
          child: IconButton(
            onPressed: () {},
            icon: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.background,
            ),
          ),
        ),
        IconButton(
          onPressed: () {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => PembelianMenu(),maintainState: false), (route) => false,
            );
          },
          icon: Icon(Icons.food_bank),
        ),
      ]),
      appBar: AppBar(
        title: const Text('Management Client'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: InkWell(
                onTap: () {},
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Text(
                    '${TokoID.tokoName}',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),
            /*
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AbsenMenu()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.people),
                        SizedBox(height: 8.0),
                        Text('Absensi'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            */
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AnalisisMenu()));
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.analytics),
                        SizedBox(height: 8.0),
                        Text('Analisis'),
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
                      MaterialPageRoute(builder: (context) => LaporanMenu()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.sell),
                        SizedBox(height: 8.0),
                        Text('Laporan'),
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
                      MaterialPageRoute(builder: (context) => BarangMenu()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_cart),
                        SizedBox(height: 8.0),
                        Text('Stock Barang'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
