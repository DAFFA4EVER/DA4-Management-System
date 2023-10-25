import 'dart:convert';
import 'package:intl/intl.dart';
import 'control.dart';
import '../backend/dataEncryption.dart';
import '../backend/dataDecryption.dart';
import '../backend/keyToken.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

List<Map<String, dynamic>> defaultJadwal = [
  {
    //0
    'Senin': [
      {
        '1': [
          {'nama': 'Refa', 'role': 'back'},
          {'nama': 'Dwiana', 'role': 'kasir'}
        ]
      },
      {'mid': []},
      {
        '2': [
          {'nama': 'Siti', 'role': 'kasir'},
          {'nama': 'Farhan', 'role': 'back'}
        ]
      },
      {
        'off': ['Iqbal']
      }
    ]
  },
  {
    //1
    'Selasa': [
      {
        '1': [
          {'nama': 'Iqbal', 'role': 'back'},
          {'nama': 'Siti', 'role': 'kasir'}
        ]
      },
      {'mid': []},
      {
        '2': [
          {'nama': 'Dwiana', 'role': 'kasir'},
          {'nama': 'Refa', 'role': 'back'}
        ]
      },
      {
        'off': ['Farhan']
      }
    ]
  },
  {
    //2
    'Rabu': [
      {
        '1': [
          {'nama': 'Iqbal', 'role': 'back'},
          {'nama': 'Dwiana', 'role': 'kasir'}
        ]
      },
      {'mid': []},
      {
        '2': [
          {'nama': 'Siti', 'role': 'kasir'},
          {'nama': 'Farhan', 'role': 'back'}
        ]
      },
      {
        'off': ['Refa']
      }
    ]
  },
  {
    //3
    'Kamis': [
      {
        '1': [
          {'nama': 'Iqbal', 'role': 'back'},
          {'nama': 'Farhan', 'role': 'kasir'}
        ]
      },
      {'mid': []},
      {
        '2': [
          {'nama': 'Dwiana', 'role': 'kasir'},
          {'nama': 'Refa', 'role': 'back'}
        ]
      },
      {
        'off': ['Siti']
      }
    ]
  },
  {
    //4
    'Jumat': [
      {
        '1': [
          {'nama': 'Refa', 'role': 'back'},
          {'nama': 'Iqbal', 'role': 'kasir'}
        ]
      },
      {'mid': []},
      {
        '2': [
          {'nama': 'Siti', 'role': 'kasir'},
          {'nama': 'Farhan', 'role': 'back'}
        ]
      },
      {
        'off': ['Dwiana']
      }
    ]
  },
  {
    //5
    'Sabtu': [
      {
        '1': [
          {'nama': 'Iqbal', 'role': 'back'},
          {'nama': 'Siti', 'role': 'kasir'}
        ]
      },
      {
        'mid': ['Farhan']
      },
      {
        '2': [
          {'nama': 'Dwiana', 'role': 'kasir'},
          {'nama': 'Refa', 'role': 'back'}
        ]
      },
      {'off': []}
    ]
  },
  {
    //6
    'Minggu': [
      {
        '1': [
          {'nama': 'Farhan', 'role': 'back'},
          {'nama': 'Siti', 'role': 'kasir'}
        ]
      },
      {
        'mid': ['Refa']
      },
      {
        '2': [
          {'nama': 'Dwiana', 'role': 'kasir'},
          {'nama': 'Iqbal', 'role': 'back'}
        ]
      },
      {'off': []}
    ]
  }, //7
  {
    'id': '',
    'name': '',
    'waktu': ['08:50-18:00', '12:00-21:00', '13:00-21:00'],
    'version': '',
    'pegawai': ['Refa', 'Dwiana', 'Iqbal', 'Siti', 'Farhan'],
    'gaji': [
      {'nama': 'Refa', 'gaji': 1600000, 'tunjangan': 500000, 'bonus': 100000},
      {'nama': 'Dwiana', 'gaji': 1600000, 'tunjangan': 500000, 'bonus': 100000},
      {'nama': 'Iqbal', 'gaji': 1600000, 'tunjangan': 500000, 'bonus': 100000},
      {'nama': 'Siti', 'gaji': 1600000, 'tunjangan': 500000, 'bonus': 100000},
      {'nama': 'Farhan', 'gaji': 1600000, 'tunjangan': 500000, 'bonus': 100000}
    ]
  }
];

List<Map<String, dynamic>> getAbsenTemplate(String currentDate) {
  List<Map<String, dynamic>> absenTemplate = [
    //{'nama': 'John Doe', 'masuk': '09:00', 'keluar' : '14:00', 'bukti' : 'imagePath'},
    //{'nama': 'Jane Smith', 'masuk': '09:15', 'keluar' : '14:00', 'bukti' : 'imagePath'},
  ];
  return absenTemplate;
}

Future<List<dynamic>> loadJadwalFromFirestore(String chooseID) async {
  String id = '';
  String tokoName = '';
  if (TokoID.isTokoIDExists(chooseID)) {
    id = chooseID;
    tokoName = TokoID.findTokoIDName(id);
  } else {
    print('Error: ID not found. Aborting the process.');
  }

  String filename = 'jadwal_${id}';

  final DocumentReference jadwalDocument =
      FirebaseFirestore.instance.collection('jadwal').doc(filename);

  try {
    final DocumentSnapshot jadwalSnapshot = await jadwalDocument.get();
    if (jadwalSnapshot.exists) {
      final jadwalDataEncrpyted = jadwalSnapshot.data() as Map<String, dynamic>;
      List<dynamic> laporanData = jsonDecode(
          decryptData(jadwalDataEncrpyted['data'].toString(), KeyToken.jadwal));
      return laporanData;
    } else {
      return [];
    }
  } catch (e) {
    print('Error loading jadwal data on : $e');
    return [];
  }
}

Future<int> updateJadwalToFirestore(
    String chooseID, List<Map<String, dynamic>> newJadwalData) async {
  String id = '';
  String tokoName = '';

  if (TokoID.isTokoIDExists(chooseID)) {
    id = chooseID;
    tokoName = TokoID.findTokoIDName(id);
  } else {
    print('Error: ID not found. Aborting the process.');
  }

  try {
    final batch = FirebaseFirestore.instance.batch();
    String jadwalData = jsonEncode(newJadwalData);

    String filename = 'jadwal_${id}';

    final CollectionReference laporanCollection =
        FirebaseFirestore.instance.collection('jadwal');

    final laporanDocRef = laporanCollection.doc(filename);

    batch
        .set(laporanDocRef, {'data': encryptData(jadwalData, KeyToken.jadwal)});

    await batch.commit();
    return 0;
    //print('Report data on saved successfully: ');
  } catch (e) {
    return 1;
    //print('Error saving report data on : $e');
  }
}
