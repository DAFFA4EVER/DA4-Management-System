import 'dart:convert';
import '../backend/getAppPath.dart';
import 'package:intl/intl.dart';
import 'control.dart';
import '../backend/dataEncryption.dart';
import '../backend/dataDecryption.dart';
import '../backend/keyToken.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class GudangLaporanDatabaseHandlerFirestore {
  static final GudangLaporanDatabaseHandlerFirestore instance =
      GudangLaporanDatabaseHandlerFirestore._();

  GudangLaporanDatabaseHandlerFirestore._(); // Private constructor

  Map<String, dynamic> laporanGudangTemplate(String currentdate) {
    Map<String, dynamic> template = {
      'date': currentdate,
      'barangKeluar': [
        // {'nama': 'Ice Cream Cone', 'qty': 5, 'unit': 'CTN', 'bukti': 'imagePath', 'toko': '', 'orang': ''},
        // {'nama': 'Ice Cream Cone', 'qty': 5, 'unit': 'CTN', 'bukti': 'imagePath', 'toko': '', 'orang': ''},
      ],
      'barangMasuk': [
        // {'nama': 'Ice Cream Cone', 'qty': 5, 'unit': 'CTN'},
        // {'nama': 'Ice Cream Cone', 'qty': 5, 'unit': 'CTN'},
      ],
      'stokGudang': [
        // {'nama': 'Ice Cream Cone', 'qty': 5, 'unit': 'CTN'},
        // {'nama': 'Kiwi Jam', 'qty': 5, 'unit': 'CTN'},
      ],
      'namaToko': 'Mixue',
      'adminSession': loginState.username,
      'strukSO': [
        // {'photo': '', 'imageName': '', 'firestorage': '', 'nama': '', 'tanggal': '', 'harga': '',}
      ],
      'penanggungJawab': '',
      'buktiBayar': [
        // {'photo': '', 'imageName': '', 'firestorage': '', 'nama': '', 'tanggal': '', 'harga': '',}
      ],
      'buktiMasuk': [
        // {'photo': '', 'imageName': '', 'firestorage': '', 'nama': '', 'tanggal': ''}
      ],
      'buktiKeluar': [
        // {'photo': '', 'imageName': '', 'firestorage': '', 'nama': '', 'tanggal': ''}
      ],
      'uploaded': false,
      'uploadTime': '',
    };
    return template;
  }

  Future<List<String>> getLaporanGudangList() async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection('Gudang Mixue');

    try {
      QuerySnapshot querySnapshot = await collectionRef.get();

      List<String> documentNames =
          querySnapshot.docs.map((doc) => doc.id).toList();

      return documentNames;
    } catch (e) {
      print('Error retrieving document names: $e');
      return [];
    }
  }

  Future<bool> checkLaporanGudangExist(String formattedDate) async {
    final getAppPath = GetAppPath();
    await getAppPath.initializeApplicationPath();

    String filename = 'report_gudang_$formattedDate';

    final DocumentReference laporanDocument =
        FirebaseFirestore.instance.collection('Gudang Mixue').doc(filename);

    final DocumentSnapshot laporanSnapshot = await laporanDocument.get();

    return laporanSnapshot.exists;
  }

  Future<Map<String, dynamic>> loadLaporanGudangFromFirestore(
      String formattedDate) async {
    if (formattedDate == '') {
      DateTime now = DateTime.now();
      formattedDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      try {
        DateFormat('yyyy-MM-dd').parse(formattedDate);
      } catch (e) {
        DateTime now = DateTime.now();
        formattedDate = DateFormat('yyyy-MM-dd').format(now);
      }
    }

    String filename = 'report_gudang_$formattedDate';

    final DocumentReference laporanDocument =
        FirebaseFirestore.instance.collection('Gudang Mixue').doc(filename);

    try {
      final DocumentSnapshot laporanSnapshot = await laporanDocument.get();
      if (laporanSnapshot.exists) {
        //final laporanDataEncrypted =
        final laporanData = laporanSnapshot.data() as Map<String, dynamic>;
        //Map<String, dynamic> laporanData = jsonDecode(decryptData(
        //    laporanDataEncrypted['data'].toString(), KeyToken.laporan));
        return laporanData;
      } else {
        return {};
      }
    } catch (e) {
      print('Error loading report data on $formattedDate: $e');
      return {'0': '0'}; // Return an empty map to indicate the error
    }
  }

  void saveLaporanGudangToFirestore(
      Map<String, dynamic> laporan, String formattedDate) async {
    if (formattedDate == '') {
      DateTime now = DateTime.now();
      formattedDate = DateFormat('yyyy-MM-dd').format(now);
    } else {
      try {
        DateFormat('yyyy-MM-dd').parse(formattedDate);
      } catch (e) {
        DateTime now = DateTime.now();
        formattedDate = DateFormat('yyyy-MM-dd').format(now);
      }
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      String laporanData = jsonEncode(laporan);

      String filename = 'report_gudang_$formattedDate';

      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection('Gudang Mixue');

      final laporanDocRef = laporanCollection.doc(filename);

      //batch.set(
      //    laporanDocRef, {'data': encryptData(laporanData, KeyToken.laporan)});

      Map<String, dynamic> firestoreData = {};

      laporan.forEach((key, value) {
        firestoreData[key] = value;
      });

      batch.set(laporanDocRef, firestoreData);

      await batch.commit();
    } catch (e) {
      print('Error saving report data on $formattedDate: $e');
    }
  }

  Future<void> deleteLaporanGudang(String formattedDate) async {
    try {
      String filename = 'report_gudang_$formattedDate';
      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection('Gudang Mixue');

      final laporanDocRef = laporanCollection.doc(filename);

      await laporanDocRef.delete();
    } catch (e) {
      print('Error deleting laporan: $e');
    }
  }
}
