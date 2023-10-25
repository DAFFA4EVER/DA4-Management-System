import 'package:da4_management/backend/moduleDataHandler.dart';
import 'package:da4_management/backend/absenHandler.dart';
import 'package:flutter/material.dart';
import '../backend/pushDatabase.dart';
import '../backend/keyToken.dart';
import '../backend/control.dart';

class UploadMenu extends StatefulWidget {
  @override
  _UploadMenuState createState() => _UploadMenuState();
}

class _UploadMenuState extends State<UploadMenu> {
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  void showLoadingOverlay() {
    setState(() {
      _isLoading = true;
    });
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Stack(
          children: [
            Opacity(
              opacity: 0.3,
              child: ModalBarrier(dismissible: false, color: Colors.black),
            ),
            Center(
              child: CircularProgressIndicator(),
            ),
          ],
        );
      },
    );
  }

  void hideLoadingOverlay() {
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context, rootNavigator: true).pop();
  }

  Future<void> _showPasswordDialog(BuildContext context, String option) async {
    final currentContext = context;
    final TextEditingController tokoName =
        TextEditingController(text: TokoID.tokoID[0].keys.first);
    List<String> tokoList = [];
    for (final nameToko in TokoID.tokoID) {
      tokoList.add(nameToko.keys.first);
    }
    return showDialog<void>(
      context: currentContext,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Enter Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Password',
                ),
              ),
              (option == 'Jadwal')
                  ? DropdownButton<String>(
                      value: tokoName.text,
                      items: tokoList
                          .map((String option) {
                            return DropdownMenuItem<String>(
                              value: option,
                              child: Text(
                                option,
                                style: TextStyle(
                                    fontSize: 24, fontWeight: FontWeight.bold),
                              ),
                            );
                          })
                          .toSet()
                          .toList(), // Convert to a set to remove duplicate values, then convert back to a list
                      onChanged: (String? newValue) {
                        setState(() {});
                      },
                    )
                  : SizedBox.shrink()
            ],
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Upload'),
              onPressed: () {
                Navigator.of(context).pop();
                String enteredPassword = _passwordController.text;
                if (option == 'Module') {
                  _uploadProcess(
                      currentContext, option, enteredPassword, true, '');
                } else if (option == 'Jadwal') {
                  print('Jadwal2');
                  _uploadProcess(
                      currentContext, option, enteredPassword, false, 'BB0001');
                } else {
                  _uploadProcess(
                      currentContext, option, enteredPassword, false, '');
                }
              },
            ),
          ],
        );
      },
    );
  }

  void _uploadProcess(BuildContext context, String option, String password,
      bool module, String tokoID) async {
    String info = '';
    int success = 4;
    showLoadingOverlay();
    if (password == KeyToken.confirm) {
      if ((module == false) && (option != "Jadwal")) {
        success = await FirestoreUploader().uploadDataDefault(option);
      } else if ((module == false) && (option == 'Jadwal')) {
        print('Jadwal1');
        success = await updateJadwalToFirestore(tokoID, defaultJadwal);
      } else {
        success = await ModuleHandler().uploadModuleDataDefault();
        _passwordController.text = '';
      }
    }

    if (success == 0) {
      hideLoadingOverlay();
      info = '$option database uploaded successfully';
    } else if (success == 1) {
      hideLoadingOverlay();
      info = 'Failed to upload $option database';
    } else if (success == 2) {
      hideLoadingOverlay();
      info = '$option data does not exist';
    } else if (success == 3) {
      hideLoadingOverlay();
      info = 'Error uploading $option database';
    } else if (success == 4) {
      hideLoadingOverlay();
      info = 'Wrong password';
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: success == 0 ? Text('Upload Success') : Text('Error'),
          content: Text(info),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Default Database'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () async {
                    _showPasswordDialog(context, "Menu");
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.menu_book),
                        SizedBox(height: 8.0),
                        Text('Menu Toko'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () async {
                    _showPasswordDialog(context, "Stock");
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
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () async {
                    _showPasswordDialog(context, 'Module');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.view_module_rounded),
                        SizedBox(height: 8.0),
                        Text('Module'),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: Card(
                child: InkWell(
                  onTap: () async {
                    _showPasswordDialog(context, 'Jadwal');
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.calendar_month),
                        SizedBox(height: 8.0),
                        Text('Jadwal'),
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
