import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter_google_drive/src/http_client.dart';
import 'package:flutter_google_drive/src/mime_type.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'package:googleapis_auth/googleapis_auth.dart' as auth;
import 'package:http/http.dart' as http;


class DriveOperations {
  DriveOperations._();

  static final ins = DriveOperations._();

  DriveApi? driveApi;

  List<File> driveFiles = [];
  late auth.AutoRefreshingAuthClient _client;

  // Future<AccessCredentials> obtainCredentials() async {
  //   final client = http.Client();
  //
  //   try {
  //     return await obtainAccessCredentialsViaUserConsent(
  //       ClientId('....apps.googleusercontent.com', '...'),
  //       [DriveApi.driveFileScope],
  //       client,
  //       _prompt,
  //     );
  //   } finally {
  //     client.close();
  //   }
  // }
  //
  // void _prompt(String url) {
  //   print('Please go to the following URL and grant access:');
  //   print('  => $url');
  //   print('');
  // }

  Future<void> setDrive() async {

    // final data = await obtainCredentials();
    final clientId = auth.ClientId(
        "544566185873-jv1uthmce9s0kcqh059qabt6kl97dcgh.apps.googleusercontent.com", "AIzaSyDeh69HD5cYwQ0QRx3HNQYdSxxyIzTgas8");
    //
    // // Use Google User Consent authentication
    // _client = await auth.;
    // await auth.clientViaUserConsent(clientId, DriveApi.driveFileScope, (url) async {
    //   if (await canLaunch(url)) {
    //     await launch(url);
    //   }
    // });
    final client = auth.clientViaApiKey('544566185873-jv1uthmce9s0kcqh059qabt6kl97dcgh.apps.googleusercontent.com');
    // final googleAuthData = await GoogleSignIn(
    //   scopes: [DriveApi.driveFileScope],
    // ).signIn();
    //
    // if (googleAuthData == null) {
    //   return;
    // }
    //
    // // log(googleAuthData.id, name: 'ID');
    //
    // final client = GoogleHttpClient(await googleAuthData.authHeaders);
    driveApi = DriveApi(client);
  }

  Future<List<File>> getRootDirectoryFiles() async {
    driveFiles = [];
    final lst = await DriveOperations.ins.driveApi?.files.list(q: "'me' in owners");
    for (int i = 0; i < (lst?.files?.length ?? 0); i++) {
      checkFileTypeAndAddToList(lst?.files?[i] ?? File());
    }
    return driveFiles;
  }

  void checkFileTypeAndAddToList(File file) {
    String fileName = (file.name ?? '').toLowerCase();
    if ((fileName.endsWith('jpg') ||
        fileName.endsWith('jpeg') ||
        fileName.endsWith('png') ||
        fileName.endsWith('svg') ||
        fileName.endsWith('pdf') ||
        fileName.endsWith('doc') ||
        fileName.endsWith('docx') ||
        file.mimeType == GoogleDriveMimeType.folderMimeType)) {
      driveFiles.add(file);
    }
  }

  Future<FileList?> filesInFolder(String folderName, String mimeType) async {
    final folderId = await _getFolderId(folderName, mimeType);
    final files = await DriveOperations.ins.driveApi?.files.list(
      spaces: 'drive',
      q: "'$folderId' in parents",
    );
    return files;
  }

  Future<String?> _getFolderId(String folderName, String folderType) async {
    try {
      final found = await DriveOperations.ins.driveApi?.files.list(
        q: "mimeType = '$folderType' and name = '$folderName'",
        $fields: "files(id, name)",
      );
      final files = found?.files;
      if (files == null) {
        return null;
      }

      if (files.isNotEmpty) {
        return files.first.id;
      }
    } catch (e) {
      print(e);
    }
    return null;
  }

  Future<io.File> downloadGoogleDriveFile(String fName, String gdID) async {
    Completer<void> completer = Completer();
    final file = await driveApi?.files.get(gdID, downloadOptions: DownloadOptions.fullMedia) as Media;

    log(file.contentType.toString(), name: 'Apu');
    log(file.length.toString(), name: 'Apu1');

    final directory = Platform.isAndroid ? await getExternalStorageDirectory() : await getApplicationSupportDirectory();
    print(directory?.path);
    io.File saveFile = io.File('${directory?.path}/${DateTime.now().millisecondsSinceEpoch}$fName');
    List<int> dataStore = [];
    file.stream.listen((data) {
      print("DataReceived: ${data.length}");
      dataStore.insertAll(dataStore.length, data);
    }, onDone: () async {
      print("Task Done");
      await saveFile.writeAsBytes(dataStore);
      completer.complete();
    }, onError: (error) {
      print("Some Error");
    });

    await completer.future;
    return saveFile;
  }
}
