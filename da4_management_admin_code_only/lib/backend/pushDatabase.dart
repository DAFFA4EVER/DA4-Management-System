import 'package:cloud_firestore/cloud_firestore.dart';
import 'defaultMenu.dart';
import 'defaultStock.dart';

class FirestoreUploader {
  Future<int> uploadDataMenu(List<Map<String, dynamic>> data) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final CollectionReference menuCollection =
          FirebaseFirestore.instance.collection('menu');
      final List<Map<String, dynamic>> menuData = data;
      final menuDocRef = menuCollection.doc('menu_data');
      batch.set(menuDocRef, {'data': menuData});

      await batch.commit();

      print('Data uploaded successfully to Firestore.');
      return 0;
    } catch (e) {
      print('Error uploading data to Firestore: $e');
      return 1;
    }
  }

  Future<int> uploadDataStock(List<Map<String, dynamic>> data) async {
    try {
      final batch = FirebaseFirestore.instance.batch();

      final CollectionReference stockCollection =
          FirebaseFirestore.instance.collection('stock');
      final List<Map<String, dynamic>> stockData = data;
      final stockDocRef = stockCollection.doc('stock_data');
      batch.set(stockDocRef, {'data': stockData});

      await batch.commit();

      print('Data uploaded successfully to Firestore.');
      return 0;
    } catch (e) {
      print('Error uploading data to Firestore: $e');
      return 1;
    }
  }

  Future<int> uploadDataDefault(String Option) async {
    try {
      final CollectionReference menuCollection =
          FirebaseFirestore.instance.collection('menu');

      final CollectionReference stockCollection =
          FirebaseFirestore.instance.collection('stock');

      final List<Map<String, dynamic>> menuData = menuMixueDefault;
      final List<Map<String, dynamic>> stockData = stockMixueDefault;

      final batch = FirebaseFirestore.instance.batch();
      // Upload Menu data
      if (Option == 'Menu') {
        final menuDocRef = menuCollection.doc('menu_data');
        batch.set(menuDocRef, {'data': menuData});
      } else {
        // Upload Stock data
        final stockDocRef = stockCollection.doc('stock_data');
        batch.set(stockDocRef, {'data': stockData});
      }
      await batch.commit();

      print('Data uploaded successfully to Firestore.');
      return 0;
    } catch (e) {
      print('Error uploading data to Firestore: $e');
      return 1;
    }
  }
}
