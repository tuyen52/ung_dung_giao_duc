class AppUser {
final String id;
final String name;
final String username;
final String email;
final String phone;
final DateTime createdAt;


AppUser({
required this.id,
required this.name,
required this.username,
required this.email,
required this.phone,
DateTime? createdAt,
}) : createdAt = createdAt ?? DateTime.now();


Map<String, dynamic> toMap() => {
'id': id,
'name': name,
'username': username,
'email': email,
'phone': phone,
'createdAt': createdAt.toIso8601String(),
};


factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
id: map['id'] as String,
name: map['name'] as String? ?? '',
username: map['username'] as String? ?? '',
email: map['email'] as String? ?? '',
phone: map['phone'] as String? ?? '',
createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
);
}