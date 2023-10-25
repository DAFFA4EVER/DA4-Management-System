import 'dart:convert';
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

  Map<String, dynamic> laporanTemplate(String currentDate) {
    Map<String, dynamic> template = {
      'point': true,
      'date': currentDate,
      'absen': [
        //{'nama': 'John Doe', 'masuk': '09:00', 'keluar' : '14:00', 'bukti' : 'imagePath'},
        //{'nama': 'Jane Smith', 'masuk': '09:15', 'keluar' : '14:00', 'bukti' : 'imagePath'},
      ],
      'menu': [
        //{'nama': 'Nasi Goreng', 'jumlah': 5, 'status' : 'cook', 'time' : 10:20, 'order code' : 'BB00011708230001'},
        //{'nama': 'Nasi Goreng Udang', 'jumlah': 5, 'status' : 'cancel', 'time' : 10:20, 'order code' : 'BB00011708230001'},
        //{'nama': 'Mie Ayam', 'jumlah': 3, 'status' : 'wait', 'time' : 10:26, 'order code' : 'BB00011708230002'},
        //{'nama': 'Mie Ayam Baso', 'jumlah': 2, 'status' : 'done', 'time' : 10:26, 'order code' : 'BB00011708230002'},
      ],
      'order list': [], //'1708230001', '1708230002'
      'pengeluaran': [
        // {'nama' : 'sendok', 'jumlah': 5, 'bukti' : 'imagePath'},
        // {'nama' : 'garpu', 'jumlah': 2, 'bukti' : 'imagePath'},
      ],
      'pemasukan external': [
        // {'nama' : 'grab', 'jumlah': 50000, 'order code' : 'BB00011708230001'},
        // {'nama' : 'cash', 'jumlah': 20000, 'order code' : 'BB00011708230001'},
        // {'nama' : 'bca', 'jumlah': 20000, 'order code' : 'BB00011708230002'},
      ],
      'stokToko': [
        // {'nama' : 'Ice Cream Cone', 'qty': 5, 'unit' : 'CTN'},
        // {'nama' : 'Kiwi Jam', 'qty': 5, 'unit' : 'CTN'},
      ],
      'idToko': TokoID.tokoID,
      'namaToko': TokoID.tokoName,
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
    saveLaporanToFirestore(template, currentDate);
    return template;
  }

  Future<List<String>> getLaporanList() async {
    CollectionReference collectionRef =
        FirebaseFirestore.instance.collection(TokoID.tokoName);

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

  Future<bool> checkLaporanExist(String formattedDate) async {
    String id = TokoID.tokoID;
    String filename = 'report_${id}_$formattedDate';

    final DocumentReference laporanDocument =
        FirebaseFirestore.instance.collection(TokoID.tokoName).doc(filename);

    final DocumentSnapshot laporanSnapshot = await laporanDocument.get();

    return laporanSnapshot.exists;
  }

  Future<Map<String, dynamic>> loadLaporanFromFirestore(
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

    String id = TokoID.tokoID;
    String filename = 'report_${id}_$formattedDate';

    final DocumentReference laporanDocument =
        FirebaseFirestore.instance.collection(TokoID.tokoName).doc(filename);

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
      return {'0': '0'};
    }
  }

  void saveLaporanToFirestore(
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

      //String laporanData = jsonEncode(laporan);

      String id = TokoID.tokoID;
      String filename = 'report_${id}_$formattedDate';

      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection(TokoID.tokoName);

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

  void updateLaporanMenuInFirestore(
      Map<String, dynamic> updatedFields, String formattedDate) async {
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

      String id = TokoID.tokoID;
      String filename = 'report_${id}_$formattedDate';

      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection(TokoID.tokoName);

      final laporanDocRef = laporanCollection.doc(filename);

      Map<String, dynamic> firestoreData = {
        'menu': updatedFields['menu'],
        'pemasukan external': updatedFields['pemasukan external'],
        'order list': updatedFields['order list'],
      };

      batch.update(laporanDocRef, firestoreData);

      await batch.commit();

      //print('Report data on $formattedDate updated successfully');
    } catch (e) {
      //print('Error updating report data on $formattedDate: $e');
    }
  }

  Future<void> deleteLaporan(String formattedDate) async {
    try {
      String id = TokoID.tokoID;
      String filename = 'report_${id}_$formattedDate';

      final CollectionReference laporanCollection =
          FirebaseFirestore.instance.collection(TokoID.tokoName);

      final laporanDocRef = laporanCollection.doc(filename);

      await laporanDocRef.delete();
    } catch (e) {
      print('Error deleting laporan: $e');
    }
  }
}
