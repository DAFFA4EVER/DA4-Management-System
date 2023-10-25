import 'package:cloud_firestore/cloud_firestore.dart';


class ModuleHandler {
  Map<String, dynamic> moduleMixueDefault = {
    'menu': ['Fruit Tea', 'Ice Cream', 'Milk Tea', 'Original Tea'],
    //
    'barang': ['Bahan Baku Resep', 'Alat Masak', 'Alat Konsumsi'],
    //
    'unit': ['CTN', 'PCS'],
    //
    'pengeluaran': [
      'Listrik',
      'Gaji',
      'ATK',
      'Bahan Baku Tambahan',
      'Service',
      'Peralatan',
      'Rumah Tangga',
      'Entertainment',
      'Promosi',
      'Transportasi',
      'Admin Grab',
      'Admin Gojek',
      'Admin Bank',
      'Admin Lainnya',
      'Penyusutan',
      'Beban Ongkos Kirim',
      'Beban Produksi',
      'Lainnya',
    ],
    //
    'pemasukkan': [
      'Grab',
      'Gojek',
      'QRIS',
      'OVO',
      'GoPay',
      'Card',
      'Lainnya',
    ],
    // Setting absen
    'shiftAbsen': [
      {'shift': '1', 'time': '08:00-16:00'},
      {'shift': 'mid', 'time': '12:00-20:00'},
      {'shift': '2', 'time': '14:00-22:00'},
      {'shift': 'off', 'time': '00:00-00:00'}
    ],
    'waktuToleransi': {
      'masuk': 15,
      'keluar': 15,
      'istirahat': 15
    }, // dalam menit
    'penalty': 68, // dalam rupiah
    'roleAbsen': ['kasir', 'back'],
    'version': '',
  };

  Future<int> uploadDataModule(Map<String, dynamic> data) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final CollectionReference moduleCollection =
          FirebaseFirestore.instance.collection('module');
      final Map<String, dynamic> moduleData = data;
      final moduleDocRef = moduleCollection.doc('module_data');
      batch.set(moduleDocRef, {'data': moduleData});

      await batch.commit();

      print('Data uploaded successfully to Firestore.');
      return 0;
    } catch (e) {
      print('Error uploading data to Firestore: $e');
      return 1;
    }
  }

  Future<int> uploadModuleDataDefault() async {
    try {
      final CollectionReference moduleCollection =
          FirebaseFirestore.instance.collection('module');

      final Map<String, dynamic> moduleData = moduleMixueDefault;

      final batch = FirebaseFirestore.instance.batch();
      final moduleDocRef = moduleCollection.doc('module_data');
      batch.set(moduleDocRef, {'data': moduleData});

      await batch.commit();

      print('Data module uploaded successfully to Firestore.');
      return 0;
    } catch (e) {
      print('Error uploading data to Firestore: $e');
      return 1;
    }
  }

  Future<bool> checkModuleExist() async {

    final DocumentReference moduleDocument =
        FirebaseFirestore.instance.collection('module').doc('module_data');

    final DocumentSnapshot moduleSnapshot = await moduleDocument.get();

    return moduleSnapshot.exists;
  }

  Future<Map<String, dynamic>> getModuleData() async {
    final DocumentReference moduleDocument =
        FirebaseFirestore.instance.collection('module').doc('module_data');

    try {
      final DocumentSnapshot moduleSnapshot = await moduleDocument.get();

      if (moduleSnapshot.exists) {
        final Map<String, dynamic> moduleData =
            moduleSnapshot.data() as Map<String, dynamic>;
        return moduleData['data'];
      } else {
        print('Module document does not exist in Firestore.');
      }
    } catch (e) {
      print('Error retrieving module data from Firestore: $e');
    }

    return {};
  }
}
