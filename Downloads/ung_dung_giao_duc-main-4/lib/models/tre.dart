class Tre {
  final String id;
  final String hoTen;
  final String gioiTinh;
  final String ngaySinh; // theo yêu cầu giữ kiểu String
  final String soThich;
  final String parentId;

  Tre({
    required this.id,
    required this.hoTen,
    required this.gioiTinh,
    required this.ngaySinh,
    required this.soThich,
    required this.parentId,
  });

  Tre copyWith({
    String? id,
    String? hoTen,
    String? gioiTinh,
    String? ngaySinh,
    String? soThich,
    String? parentId,
  }) {
    return Tre(
      id: id ?? this.id,
      hoTen: hoTen ?? this.hoTen,
      gioiTinh: gioiTinh ?? this.gioiTinh,
      ngaySinh: ngaySinh ?? this.ngaySinh,
      soThich: soThich ?? this.soThich,
      parentId: parentId ?? this.parentId,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'hoTen': hoTen,
        'gioiTinh': gioiTinh,
        'ngaySinh': ngaySinh,
        'soThich': soThich,
        'parentId': parentId,
      };

  factory Tre.fromMap(Map<dynamic, dynamic> map) => Tre(
        id: (map['id'] ?? '') as String,
        hoTen: (map['hoTen'] ?? '') as String,
        gioiTinh: (map['gioiTinh'] ?? '') as String,
        ngaySinh: (map['ngaySinh'] ?? '') as String,
        soThich: (map['soThich'] ?? '') as String,
        parentId: (map['parentId'] ?? '') as String,
      );
}
