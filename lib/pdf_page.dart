// ignore_for_file: prefer_const_constructors

import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart' as dioPrefix;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:get/get.dart';
import 'package:pdf_page/pdf_controller.dart';
import 'package:share_plus/share_plus.dart';

PdfController pdfController = Get.put(PdfController());

class PdfPage extends StatelessWidget {
  static String id = '/pdfPage';
  final Completer<PDFViewController> _controller =
      Completer<PDFViewController>();
  bool isReady = false;
  String errorMessage = '';
  String url = '';

  void initState() {
    if (Get.arguments != null) {
      print('new url entered');
      pdfController.setUrl(Get.arguments['url']);
      downloadPdf().then((f) {
        pdfController.setPath(f.path);
      });
    }
  }

  Future<File> downloadPdf() async {
    Completer<File> completer = Completer();
    print('download file with dio');
    dioPrefix.Dio dio = dioPrefix.Dio();

    try {
      var dir = await getApplicationDocumentsDirectory();
      var filename =
          pdfController.url.substring(pdfController.url.lastIndexOf("/") + 1);
      File file = File("${dir.path}/$filename");
      print(file.toString());

      //check if file exist
      //download the file with dio
      if (await file.exists() == false) {
        print('file not exist, start downloading');
        dioPrefix.Response response = await dio.get(
          pdfController.url,
          onReceiveProgress: showDownloadProgress,
          options: dioPrefix.Options(
              responseType: dioPrefix.ResponseType.bytes,
              followRedirects: false,
              validateStatus: (status) {
                return status! < 500;
              }),
        );
        var raf = file.openSync(mode: FileMode.write);
        raf.writeFromSync(response.data);
        await raf.close();
      }
      print('file exist or done downloaded');
      completer.complete(file);
    } catch (e) {
      print('Error parsing asset file!');
      Get.defaultDialog(
        title: "Error",
        content: Text(e.toString()),
        confirm: ElevatedButton(
          onPressed: () {
            Get.back();
            Get.back();
          },
          child: Text('GO BACK'),
        ),
      );
    }
    return completer.future;
  }

  void showDownloadProgress(received, total) {
    if (total != -1) {
      pdfController
          .setProgress((received / total * 100).toStringAsFixed(0) + "%");
      print((received / total * 100).toStringAsFixed(0) + "%");
    }
  }

  void SelectedItem(BuildContext context, item) async {
    switch (item) {
      case 0:
        print('change dark mode');
        pdfController.setNightMode();
        Get.back();
        Get.toNamed(PdfPage.id);
        break;
      case 1:
        print('change swipe mode');
        pdfController.setSwipeHorizontal();
        Get.back();
        Get.toNamed(PdfPage.id);
        break;
      //TODO: share pdf
      case 2:
        print('share file using share_plus');
        Share.shareFiles(
          [pdfController.path],
          text: 'Look，I have share my PDF with you.',
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    initState();
    return Scaffold(
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      appBar: AppBar(
        title: Text("PDF View"),
        actions: [
          PopupMenuButton<int>(
            onSelected: (item) => SelectedItem(context, item),
            itemBuilder: (context) => [
              PopupMenuItem<int>(
                value: 0,
                child: Row(
                  children: [
                    pdfController.isNightMode
                        ? Icon(Icons.light_mode)
                        : Icon(Icons.dark_mode),
                    pdfController.isNightMode
                        ? Text("  Light Mode")
                        : Text("  Dark Mode"),
                  ],
                ),
              ),
              PopupMenuItem<int>(
                value: 1,
                child: Row(
                  children: [
                    pdfController.isSwipeHorizontal
                        ? Icon(Icons.swap_vert)
                        : Icon(Icons.swap_horiz),
                    pdfController.isSwipeHorizontal
                        ? Text("  Swipe Vertical")
                        : Text("  Swipe Horizontal"),
                  ],
                ),
              ),
              //TODO: share pdf
              PopupMenuItem<int>(
                value: 2,
                child: Row(
                  children: const [
                    Icon(Icons.share),
                    Text(
                      "  Share",
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: GetBuilder<PdfController>(
        init: pdfController,
        builder: (controller) => pdfController.path.isEmpty
            ? Center(
                child: Container(
                height: 150.0,
                width: 200.0,
                child: Card(
                    color: Colors.black,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 10.0),
                        Text(
                          'Downloading PDF',
                          style: TextStyle(color: Colors.white),
                        ),
                        SizedBox(height: 10.0),
                        Text(
                          controller.progress,
                          style: TextStyle(color: Colors.white),
                        ),
                      ],
                    )),
              ))
            : PDFView(
                filePath: controller.path,
                enableSwipe: true,
                swipeHorizontal: controller.isSwipeHorizontal,
                autoSpacing: false,
                pageFling: true,
                pageSnap: true,
                defaultPage: controller.currentPage,
                fitPolicy: FitPolicy.BOTH,
                nightMode: controller.isNightMode,
                preventLinkNavigation: false,
                // if set to true the link is handled in flutter
                onRender: (_pages) {
                  controller.setTotalPages(_pages!);
                  isReady = true;
                },
                onError: (error) {
                  errorMessage = error.toString();
                  print(error.toString());
                  Get.defaultDialog(
                    title: "Error",
                    content: Text(errorMessage),
                    confirm: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      child: Text('GO BACK'),
                    ),
                  );
                },
                onPageError: (page, error) {
                  errorMessage = '$page: ${error.toString()}';
                  print('$page: ${error.toString()}');
                  Get.defaultDialog(
                    title: "Error",
                    content: Text(errorMessage),
                    confirm: ElevatedButton(
                      onPressed: () {
                        Get.back();
                        Get.back();
                      },
                      child: Text('GO BACK'),
                    ),
                  );
                },
                onViewCreated: (PDFViewController pdfViewController) {
                  _controller.complete(pdfViewController);
                },
                onLinkHandler: (String? uri) {
                  print('goto uri: $uri');
                },
                onPageChanged: (int? page, int? total) {
                  print('page change: $page/$total');
                  pdfController.setCurrentPages(page!);
                },
              ),
      ),
      floatingActionButton: FutureBuilder<PDFViewController>(
        future: _controller.future,
        builder: (context, AsyncSnapshot<PDFViewController> snapshot) {
          if (snapshot.hasData) {
            return GetBuilder<PdfController>(builder: (pdfController) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  PdfFloatingActionButton(
                    label: Icon(Icons.first_page),
                    onPressed: () async {
                      pdfController.setCurrentPages(0);
                      await snapshot.data!.setPage(pdfController.currentPage);
                    },
                  ),
                  PdfFloatingActionButton(
                    label: Icon(Icons.chevron_left),
                    onPressed: () async {
                      pdfController
                          .setCurrentPages(pdfController.currentPage - 1);
                      await snapshot.data!.setPage(pdfController.currentPage);
                    },
                  ),
                  PdfFloatingActionButton(
                    label: Text(
                        " ${pdfController.currentPage + 1} / ${pdfController.totalPages} "),
                    onPressed: () {
                      String input = '';
                      Get.defaultDialog(
                        title: 'Select page number',
                        content: TextField(
                          keyboardType: TextInputType.number,
                          textAlign: TextAlign.center,
                          onChanged: (i) {
                            input = i;
                          },
                        ),
                        confirm: ElevatedButton(
                          onPressed: () async {
                            Get.back();
                            pdfController.setCurrentPages(int.parse(input) - 1);
                            await snapshot.data!
                                .setPage(pdfController.currentPage);
                          },
                          child: Text('OK'),
                        ),
                      );
                    },
                  ),
                  PdfFloatingActionButton(
                    label: Icon(Icons.chevron_right),
                    onPressed: () async {
                      pdfController
                          .setCurrentPages(pdfController.currentPage + 1);
                      await snapshot.data!.setPage(pdfController.currentPage);
                    },
                  ),
                  PdfFloatingActionButton(
                    label: Icon(Icons.last_page),
                    onPressed: () async {
                      pdfController.setCurrentPages(pdfController.totalPages);
                      await snapshot.data!.setPage(pdfController.currentPage);
                    },
                  ),
                ],
              );
            });
          }
          return Container();
        },
      ),
    );
  }
}

class PdfFloatingActionButton extends StatelessWidget {
  Widget label;
  VoidCallback onPressed;

  PdfFloatingActionButton(
      {Key? key, required this.label, required this.onPressed})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.extended(
      backgroundColor: pdfController.isNightMode ? Colors.grey : Colors.black54,
      foregroundColor: pdfController.isNightMode ? Colors.black : Colors.white,
      label: label,
      onPressed: onPressed,
    );
  }
}
