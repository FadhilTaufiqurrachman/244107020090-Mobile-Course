double hitungLuasPersegiPanjang(double panjang, double lebar) {
  double hasil = panjang * lebar;
  return hasil;
}

class Profile {
  String nama;
  String nim;
  String? email;

  Profile({required this.nama, required this.nim, this.email});
  
  void tampilkanProfile() {
    print("Nama   : $nama");
    print("NIM    : $nim");
    print("Email  : ${email ?? 'Email Tidak Tersedia'}");
  }
}

void main() {
  double panjang = 12.5;
  double lebar = 7.5;
  double luas = hitungLuasPersegiPanjang(panjang, lebar);
  print("Luas Persegi Panjang : $luas");
  print("==============================================");  

  Profile profileMahasiswa = Profile(nama: "Fadhil Taufiqurrachman", nim: "244107020090", email: "fadhiltaufiqurrachman08@gmail.com");
  profileMahasiswa.tampilkanProfile();
  print("==============================================");  
  Profile profileMahasiswa2 = Profile(nama: "Amanda Shofirotus", nim: "244107020089");
  profileMahasiswa2.tampilkanProfile();
}