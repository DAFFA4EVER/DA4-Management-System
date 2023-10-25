import 'dart:io';
import 'package:intl/intl.dart';
import 'dart:typed_data';
import 'control.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase/firebase.dart' as fb;
import 'package:image_picker/image_picker.dart';

class BuktiDataHandlerAndroid {
  static final BuktiDataHandlerAndroid instance = BuktiDataHandlerAndroid._();

  BuktiDataHandlerAndroid._(); // Private constructor

  void openImageInNewTab(String imageUrl) async {
    if (await canLaunch(imageUrl)) {
      await launch(imageUrl);
    } else {
      print('Could not launch $imageUrl');
    }
  }

  Future<String?> loadBuktiFromFirestorage(
      String formattedDate, String photoName, String chooseID) async {
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

    String id = '';
    String tokoName = '';
    if (TokoID.isTokoIDExists(chooseID)) {
      id = chooseID;
      tokoName = TokoID.findTokoIDName(id);
    } else {
      print('Error: ID not found. Aborting the process.');
    }
    FirebaseStorage storage = FirebaseStorage.instance;

    Reference ref =
        storage.ref().child('bukti/$tokoName/$formattedDate/$photoName');

    try {
      final photoURL = await ref.getDownloadURL();
      openImageInNewTab(photoURL);
      return photoURL;
    } catch (e) {
      print('Error loading bukti data on $formattedDate: $e');
    }
    return null;
  }

  Future<void> deleteBuktiFolder(String formattedDate, String chooseID) async {
    try {
      String id = '';
      String tokoName = '';
      if (TokoID.isTokoIDExists(chooseID)) {
        id = chooseID;
        tokoName = TokoID.findTokoIDName(id);
      } else {
        print('Error: ID not found. Aborting the process.');
        return;
      }

      FirebaseStorage storage = FirebaseStorage.instance;
      Reference ref = storage.ref('bukti/$tokoName/$formattedDate/');

      // List all files in the directory
      ListResult result = await ref.listAll();

      // Delete each file in the directory
      for (Reference fileRef in result.items) {
        await fileRef.delete();
      }

      print('All files deleted from bukti/$tokoName/$formattedDate/');
    } catch (e) {
      print('Error deleting bukti: $e');
    }
  }

  Future<void> deleteBukti(
      String formattedDate, String photoName, String chooseID) async {
    try {
      String id = '';
      String tokoName = '';
      if (TokoID.isTokoIDExists(chooseID)) {
        id = chooseID;
        tokoName = TokoID.findTokoIDName(id);
      } else {
        print('Error: ID not found. Aborting the process.');
      }
      FirebaseStorage storage = FirebaseStorage.instance;

      Reference ref =
          storage.ref('bukti/$tokoName/$formattedDate/').child(photoName);
      await ref.delete();
    } catch (e) {
      print('Error deleting bukti: $e');
    }
  }

  Future<String> uploadImageURL(PickedFile? imageFile, String fileName,
      String formattedDate, String chooseID) async {
    try {
      // Upload the image file to Firebase Storage
      String id;
      String tokoName = '';
      if (TokoID.isTokoIDExists(chooseID)) {
        id = chooseID;
        tokoName = TokoID.findTokoIDName(id);
      } else {
        print('Error: ID not found. Aborting the process.');
      }
      //final firebaseStorageRef = FirebaseStorage.instance
      //    .ref()
      //    .child('bukti/$tokoName/$formattedDate/$fileName');

      //await firebaseStorageRef.putFile(imageFile);

      // Get the download URL of the uploaded image
      //final downloadURL = await firebaseStorageRef.getDownloadURL();
      String uploadedPhotoUrl = '';
      Reference _reference = FirebaseStorage.instance
          .ref()
          .child('bukti/$tokoName/$formattedDate/$fileName');
      await _reference
          .putData(
        await imageFile!.readAsBytes(),
        SettableMetadata(contentType: 'image/jpeg'),
      )
          .whenComplete(() async {
        await _reference.getDownloadURL().then((value) {
          uploadedPhotoUrl = value;
        });
      });

      return uploadedPhotoUrl;
    } catch (e) {
      print('Error uploading image: $e');
    }
    return '';
  }
}
