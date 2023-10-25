import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'control.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path_provider/path_provider.dart';

class BuktiDataHandlerAndroid {
  static final BuktiDataHandlerAndroid instance = BuktiDataHandlerAndroid._();

  BuktiDataHandlerAndroid._(); // Private constructor

  Future<Uint8List?> loadBuktiFromFirestorage(
      String formattedDate, String photoName) async {
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

    FirebaseStorage storage = FirebaseStorage.instance;

    Reference ref = storage
        .ref()
        .child('bukti/${TokoID.tokoName}/$formattedDate/$photoName');

    try {
      final photoSnapshot = ref.getData();
      return photoSnapshot;
    } catch (e) {
      print('Error loading bukti data on $formattedDate: $e');
      return null;
    }
  }

  Future<void> deleteBukti(String formattedDate, String photoName) async {
    try {
      FirebaseStorage storage = FirebaseStorage.instance;

      Reference ref = storage
          .ref('bukti/${TokoID.tokoName}/$formattedDate/')
          .child(photoName);
      await ref.delete();
    } catch (e) {
      print('Error deleting bukti: $e');
    }
  }

  Future<String> uploadImageURL(File imageFile, String formattedDate) async {
    try {
      // Upload the image file to Firebase Storage
      final fileName = imageFile.path.split('/').last;
      final firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('bukti/${TokoID.tokoName}/$formattedDate/$fileName');
      await firebaseStorageRef.putFile(imageFile);

      // Get the download URL of the uploaded image
      final downloadURL = await firebaseStorageRef.getDownloadURL();

      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
    }
    return '';
  }
/*
   Future<Uint8List> ComporessImgUint8List(Uint8List list) async {
    var result = await FlutterImageCompress.compressWithList(
      list,
      minHeight: 1920,
      minWidth: 1080,
      quality: 96,
      rotate: 135,
      format: CompressFormat.jpeg
    );
    return result;
  }
*/
  Future<String> uploadImageUint8URL(
      Uint8List imageFile, String fileName, String formattedDate) async {
    try {
      // Create a temporary file from the Uint8List
      final tempDir = await getTemporaryDirectory();
      final tempImagePath = '${tempDir.path}/temp_image.jpg';
      await File(tempImagePath).writeAsBytes(imageFile);
      final tempImageFile = File(tempImagePath);

      // Upload the image file to Firebase Storage
      final firebaseStorageRef = FirebaseStorage.instance
          .ref()
          .child('bukti/${TokoID.tokoName}/$formattedDate/$fileName');
      await firebaseStorageRef.putFile(tempImageFile);

      // Get the download URL of the uploaded image
      final downloadURL = await firebaseStorageRef.getDownloadURL();

      // Delete the temporary file
      await tempImageFile.delete();

      return downloadURL;
    } catch (e) {
      print('Error uploading image: $e');
    }
    return '';
  }
}
