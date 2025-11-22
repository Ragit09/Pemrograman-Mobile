class FeedbackModel {
  String? nama;
  String? prodi;
  int kepuasanUmum;
  int kepuasanPerpustakaan;
  int kepuasanLaboratorium;
  int kepuasanKantin;
  int kepuasanAdministrasi;
  String? saran;

  FeedbackModel({
    this.nama,
    this.prodi,
    this.kepuasanUmum = 0,
    this.kepuasanPerpustakaan = 0,
    this.kepuasanLaboratorium = 0,
    this.kepuasanKantin = 0,
    this.kepuasanAdministrasi = 0,
    this.saran,
  });

  double get averageRating {
    final ratings = [
      kepuasanUmum,
      kepuasanPerpustakaan,
      kepuasanLaboratorium,
      kepuasanKantin,
      kepuasanAdministrasi,
    ];
    return ratings.reduce((a, b) => a + b) / ratings.length;
  }
}