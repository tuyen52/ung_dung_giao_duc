class UserProfile {
  final String uid;
  final String? name;
  final String? email;
  final String? phone;
  final String? address;
  final int? createdAt;
  final int? updatedAt;

  const UserProfile({
    required this.uid,
    this.name,
    this.email,
    this.phone,
    this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> map) {
    return UserProfile(
      uid: uid,
      name: map['name'] as String?,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      createdAt: (map['createdAt'] as num?)?.toInt(),
      updatedAt: (map['updatedAt'] as num?)?.toInt(),
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'createdAt': createdAt,
    'updatedAt': updatedAt,
  };

  UserProfile copyWith({
    String? name,
    String? email,
    String? phone,
    String? address,
    int? createdAt,
    int? updatedAt,
  }) => UserProfile(
    uid: uid,
    name: name ?? this.name,
    email: email ?? this.email,
    phone: phone ?? this.phone,
    address: address ?? this.address,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
