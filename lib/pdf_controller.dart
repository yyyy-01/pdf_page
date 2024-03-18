import 'package:get/get.dart';

class PdfController extends GetxController {
  String url = '';
  bool isNightMode = false;
  bool isSwipeHorizontal = false;
  int totalPages = 0;
  int currentPage = 0;
  String path = '';
  String progress = '0%';

  void setUrl(String url) {
    this.url = url;
    path = '';
    totalPages = 0;
    currentPage = 0;
    progress = '0%';
    update();
  }

  void setProgress(progress) {
    this.progress = progress;
    update();
  }

  void setNightMode() {
    isNightMode = !isNightMode;
    update();
  }

  void setSwipeHorizontal() {
    isSwipeHorizontal = !isSwipeHorizontal;
    update();
  }

  void setTotalPages(int totalPages) {
    this.totalPages = totalPages;
    update();
  }

  void setCurrentPages(int currentPage) {
    this.currentPage = currentPage;
    update();
  }

  void setPath(String pdfPath) {
    this.path = pdfPath;
    update();
  }
}
