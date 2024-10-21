

part of 'flutter_google_drive.dart';

class ShowFiles extends StatefulWidget {
  const ShowFiles({super.key});

  @override
  State<ShowFiles> createState() => _ShowFilesState();
}

class _ShowFilesState extends State<ShowFiles> {
  List<File> driveFiles = [];
  List<String> selectedFile = [];
  bool isLoading = false;

  List<String> _fileName = [];
  List<String> _mimeType = [];

  @override
  void initState() {
    performInitialOperation();
    super.initState();
  }

  Future<void> performInitialOperation() async {
    setState(() {
      isLoading = true;
    });
    await DriveOperations.ins.setDrive().then((r) async {
      driveFiles = await DriveOperations.ins.getRootDirectoryFiles();
      setState(() {
        isLoading = false;
      });
    });
  }

  bool isDoc(String fileName) {
    final name = fileName.toLowerCase();
    return name.endsWith('doc') || name.endsWith('docx') || name.endsWith('pdf');
  }

  IconData getIcon(File file) {
    final name = file.name?.toLowerCase() ?? '';
    if (file.mimeType == GoogleDriveMimeType.folderMimeType) {
      return Icons.folder_copy_rounded;
    } else if (name.endsWith('pdf')) {
      return Icons.picture_as_pdf;
    } else if ((name.endsWith('doc') || name.endsWith('docx'))) {
      return Icons.file_copy;
    } else {
      return Icons.image;
    }
  }

  Future<void> handleOnTap(int index) async {
    if (driveFiles[index].mimeType != GoogleDriveMimeType.folderMimeType) {
      setState(() {
        if (selectedFile.contains(driveFiles[index].id)) {
          selectedFile.removeWhere((e) => e == driveFiles[index].id);
        } else {
          selectedFile.add(driveFiles[index].id ?? '');
        }
      });
    } else {
      _fileName.add(driveFiles[index].name ?? '');
      _mimeType.add(driveFiles[index].mimeType ?? '');
      setState(() {
        isLoading = true;
      });
      final fileList = await DriveOperations.ins.filesInFolder(driveFiles[index].name ?? '', driveFiles[index].mimeType ?? '');
      driveFiles = fileList?.files ?? [];
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> getFilesInFolder(String name, String mimeType) async {
    setState(() {
      isLoading = true;
    });
    selectedFile = [];
    final fileList = await DriveOperations.ins.filesInFolder(name, mimeType);
    driveFiles = fileList?.files ?? [];
    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _fileName.isEmpty ? true : false,
      onPopInvokedWithResult: (value, res) async {
        if (_fileName.isEmpty) {
          // Navigator.of(context).pop([]);
        } else {
          if (_fileName.length > 1) {
            await getFilesInFolder(_fileName[_fileName.length - 2], _mimeType[_mimeType.length - 2]);
          } else {
            setState(() {
              isLoading = true;
            });
            driveFiles = await DriveOperations.ins.getRootDirectoryFiles();
            setState(() {
              isLoading = false;
            });
          }
          _fileName.removeLast();
          _mimeType.removeLast();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          leading: BackButton(
            onPressed: () async{
              if (_fileName.isEmpty) {
                Navigator.of(context).pop([]);
              } else {
                if (_fileName.length > 1) {
                  await getFilesInFolder(_fileName[_fileName.length - 2], _mimeType[_mimeType.length - 2]);
                } else {
                  setState(() {
                    isLoading = true;
                  });
                  driveFiles = await DriveOperations.ins.getRootDirectoryFiles();
                  setState(() {
                    isLoading = false;
                  });
                }
                _fileName.removeLast();
                _mimeType.removeLast();
              }
            },
            color: Colors.black,
          ),
          title: const Text(
            'Choose File',
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
              child: Column(
                children: [
                  SizedBox(height: MediaQuery.of(context).padding.top),
                  const SizedBox(height: 20),

                  ///
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ...List.generate(
                            driveFiles.length,
                            (i) {
                              return Padding(
                                padding: const EdgeInsets.all(7.0),
                                child: ListTile(
                                  onTap: () async {
                                    await handleOnTap(i);
                                  },
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8.0)
                                  ),
                                  tileColor: selectedFile.contains(driveFiles[i].id ?? '') ? Colors.blue.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                                  leading: Icon(getIcon(driveFiles[i])),
                                  title: Padding(
                                    padding: const EdgeInsets.only(left: 8.0),
                                    child: Text(
                                      driveFiles[i].name ?? '',
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                              );
                            },
                          )
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: selectedFile.isNotEmpty
                        ? () async {
                            io.File file;
                            setState(() {
                              isLoading = true;
                            });
                            List<io.File> fileList = [];
                            for (int i = 0; i < selectedFile.length; i++) {
                              file = await DriveOperations.ins.downloadGoogleDriveFile(
                                  driveFiles.firstWhere((e) => e.id == selectedFile[i]).name ?? '', selectedFile[i]);
                              fileList.add(file);
                            }
                            setState(() {
                              isLoading = false;
                            });
                            Navigator.of(context).pop([fileList]);
                          }
                        : null,
                    child: const Text('Proceed'),
                  )
                ],
              ),
            ),
            if (isLoading) const CircularProgressIndicatorWithBackdrop(),
          ],
        ),
      ),
    );
  }
}
