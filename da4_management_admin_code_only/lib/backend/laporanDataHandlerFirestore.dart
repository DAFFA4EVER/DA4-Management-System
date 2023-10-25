import 'dart:convert';
import '../backend/getAppPath.dart';
import 'package:intl/intl.dart';
import 'control.dart';
import '../backend/dataEncryption.dart';
import '../backend/dataDecryption.dart';
import '../backend/keyToken.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LaporanDatabaseHandlerFirestore {
  static final LaporanDatabaseHandlerFirestore instance =
      LaporanDatabaseHandlerFirestore._();

  LaporanDatabaseHandlerFirestore._(); // Private constructor

  Map<String, dynamic> laporanTemplate(String currentdate, String chooseID) {
    String id = '';
    String tokoName = '';
    if (TokoID.isTokoIDExists(chooseID)) {
      id = chooseID;
      tokoName = TokoID.findTokoIDName(id);
    }
    Map<String, dynamic> template = {
      'date': currentdate,
      'absen': [
        //{'nama': 'John Doe', 'masuk': '09:00', 'keluar' : '14:00', 'bukti' : 'imagePath'},
        //{'nama': 'Jane Smith', 'masuk': '09:15', 'keluar' : '14:00', 'bukti' : 'imagePath'},
      ],
      'menu': [
        //{'nama': 'Nasi Goreng', 'jumlah': 5},
        //{'nama': 'Mie Ayam', 'jumlah': 3},
      ],
      'pengeluaran': [
        // {'nama' : 'sendok', 'jumlah': 5, 'bukti' : 'imagePath'},
        // {'nama' : 'garpu', 'jumlah': 2, 'bukti' : 'imagePath'},
      ],
      'pemasukan external': [
        // {'nama' : 'grab', 'jumlah': 50000, 'bukti' : 'imagePath'},
        // {'nama' : 'bca', 'jumlah': 20000, 'bukti' : 'imagePath'},
      ],
      'stokToko': [
        // {'nama' : 'Ice Cream Cone', 'qty': 5, 'unit' : 'CTN'},
        // {'nama' : 'Kiwi Jam', 'qty': 5, 'unit' : 'CTN'},
      ],
      'idToko': id,
      'namaToko': tokoName,
      'clientSession': loginState.username,
      'adminSession': '',
      'total': 0,
      'cash': 0,
      'struk': [
        {
          'photo': '',
          'imageName': '',
          'firestorage': '',
          'nama': '',
          'jumlah': 0,
          'cash': 0
        }
      ], // bukti
      'penanggungJawab': '',
      'setor': [
        {
          'bank': '',
          'rekening': '',
          'jumlah': 0,
          'nama': '',
          'photo': '',
          'imageName': '',
          'firestorage': ''
        }
      ],
      'sudahSetor': false,
      'uploaded': false,
      'uploadTime': '',
    };
    return template;
  }

  Future<List<String>> getLaporanList(String chooseTokoName) async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(chooseTokoName);

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

  Future<bool> checkLaporanExist(String formattedDate, String chooseID) async {
    final getAppPath = GetAppPath();
    await getAppPath.initializeApplicationPath();

    String id;
    String tokoName;
    if (TokoID.isTokoIDExists(chooseID)) {
      id = chooseID;
      tokoName = TokoID.findTokoIDName(id);
    } else {
      print('Error: ID not found. Aborting the process.');
      return false;
    }

    String filename = 'report_${id}_$formattedDate';

    final DocumentReference laporanDocument =
        FirebaseFirestore.instance.collection(tokoName).doc(filename);

    final DocumentSnapshot laporanSnapshot = await laporanDocument.get();

    return laporanSnapshot.exists;
  }

  Future<Map<String, dynamic>> loadLaporanFromFirestore(
      String formattedDate, String chooseID) async {
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

    String id;
    String tokoName;
    if (TokoID.isTokoIDExists(chooseID)) {
      id = chooseID;
      tokoName = TokoID.findTokoIDName(id);
    } else {
      print('Error: ID not found. Aborting the process.');
      return {'0': '0'}; // Return an empty map to indicate the error
    }

    String filename = 'report_${id}_$formattedDate';

    final DocumentReference laporanDocument =
        FirebaseFirestore.instance.collection(tokoName).doc(filename);
    Map<String, dynamic> laporanData = {};
    try {
      final DocumentSnapshot laporanSnapshot = await laporanDocument.get();
      if (laporanSnapshot.exists) {
        final laporanDataEncrpyted =
            laporanSnapshot.data() as Map<String, dynamic>;
        if (laporanDataEncrpyted['data'] != null) {
          laporanData = jsonDecode(decryptData(
              laporanDataEncrpyted['data'].toString(), KeyToken.laporan));
        }else{
          laporanData = laporanSnapshot.data() as Map<String, dynamic>;
        }
        return laporanData;
      } else {
        return {};
      }
    } catch (e) {
      print('Error loading report data on $formattedDate: $e');
      return {'0': '0'}; // Return an empty map to indicate the error
    }
  }

  void saveLaporanToFirestore(Map<String, dynamic> laporan,
      String formattedDate, String chooseID) async {
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

    String id;
    String tokoName;
    if (TokoID.isTokoIDExists(chooseID)) {
      id = chooseID;
      tokoName = TokoID.findTokoIDName(id);
    } else {
      print('Error: ID not found. Aborting the process.');
      return; // Abort the process
    }

    try {
      final batch = FirebaseFirestore.instance.batch();

      //String laporanData = jsonEncode(laporan);

      String filename = 'report_${id}_$formattedDate';

      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection(tokoName);

      final laporanDocRef = laporanCollection.doc(filename);

      //batch.set(
      //    laporanDocRef, {'data': encryptData(laporanData, KeyToken.laporan)});
      
      Map<String, dynamic> firestoreData = {};

      laporan.forEach((key, value) {
        firestoreData[key] = value;
      });

      batch.set(laporanDocRef, firestoreData);

      await batch.commit();
      //print('Report data on $formattedDate saved successfully: $filePath');
    } catch (e) {
      //print('Error saving report data on $formattedDate: $e');
    }
  }

  Future<void> deleteLaporan(String formattedDate, String chooseID) async {
    try {
      String id;
      String tokoName;
      if (TokoID.isTokoIDExists(chooseID)) {
        id = chooseID;
        tokoName = TokoID.findTokoIDName(id);
      } else {
        print('Error: ID not found. Aborting the process.');
        return; // Abort the process
      }
      String filename = 'report_${id}_$formattedDate';
      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection(tokoName);

      final laporanDocRef = laporanCollection.doc(filename);

      await laporanDocRef.delete();
    } catch (e) {
      print('Error deleting laporan: $e');
    }
  }
}
