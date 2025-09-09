// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../services/user_service.dart';
import '../services/tre_service.dart';
import '../models/tre.dart';

import 'learning_progress_screen.dart';
import 'edit_parent_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final FirebaseAuth _auth;
  User? _user;
  final _userService = UserService();

  bool _syncingEmail = false;

  @override
  void initState() {
    super.initState();
    _auth = FirebaseAuth.instance;
    _user = _auth.currentUser;

    // Lắng nghe thay đổi tài khoản:
    // - Cập nhật UI
    // - Đồng bộ email Auth -> DB (users/{uid}/email)
    _auth.userChanges().listen((u) async {
      if (!mounted) return;
      setState(() => _user = u);
      if (u != null && u.email != null) {
        try {
          setState(() => _syncingEmail = true);
          await _userService.updateProfileFields(u.uid, {
            'email': u.email,
          });
        } catch (_) {
          // bỏ qua lỗi sync nhẹ
        } finally {
          if (mounted) setState(() => _syncingEmail = false);
        }
      }
    });
  }

  Future<void> _reloadUser() async {
    try {
      await _auth.currentUser?.reload();
      setState(() {
        _user = _auth.currentUser;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã làm mới trạng thái tài khoản')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi reload: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông Tin Hồ Sơ'),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _reloadUser,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Vui lòng đăng nhập'))
          : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Phụ Huynh:'),
          // ====== HỒ SƠ PHỤ HUYNH từ Realtime DB (users/{uid}) ======
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: StreamBuilder<Map<String, dynamic>?>(
                stream: _userService.watchProfile(user.uid),
                builder: (context, snap) {
                  final hasErr = snap.hasError;
                  final loading = snap.connectionState == ConnectionState.waiting;
                  final profile = snap.data;

                  final name = (profile?['name'] as String?)?.trim();
                  final username = (profile?['username'] as String?)?.trim();
                  final email = (profile?['email'] as String?)?.trim();
                  final phone = (profile?['phone'] as String?)?.trim();
                  final address = (profile?['address'] as String?)?.trim();

                  // Fallback từ Auth nếu DB chưa có
                  final displayName = name?.isNotEmpty == true
                      ? name!
                      : (user.displayName ?? '—');
                  final displayEmail = email?.isNotEmpty == true
                      ? email!
                      : (user.email ?? '—');
                  final displayPhone = phone?.isNotEmpty == true
                      ? phone!
                      : (user.phoneNumber ?? '—');
                  final displayUsername = username?.isNotEmpty == true
                      ? username!
                      : _deriveUsername(displayEmail, user.uid);
                  final displayAddress = address?.isNotEmpty == true ? address! : '—';

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasErr)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Text('Lỗi tải hồ sơ: ${snap.error}',
                              style: const TextStyle(color: Colors.red)),
                        ),
                      if (loading || _syncingEmail)
                        const Padding(
                          padding: EdgeInsets.only(bottom: 8),
                          child: LinearProgressIndicator(minHeight: 2),
                        ),
                      _line('Họ và tên', displayName),
                      _line('Username', displayUsername),
                      _line('Email', displayEmail),
                      Row(
                        children: [
                          Icon(
                            user.emailVerified ? Icons.verified : Icons.info_outline,
                            size: 16,
                            color: user.emailVerified ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            user.emailVerified ? 'Đã xác minh' : 'Chưa xác minh',
                            style: TextStyle(
                              color: user.emailVerified ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Spacer(),
                          if (!user.emailVerified)
                            TextButton(
                              onPressed: () async {
                                try {
                                  await user.sendEmailVerification();
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                        content: Text('Đã gửi lại email xác minh.')),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text('Lỗi gửi xác minh: $e')),
                                  );
                                }
                              },
                              child: const Text('Gửi xác minh'),
                            ),
                        ],
                      ),
                      _line('Số điện thoại', displayPhone),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // Nếu chưa có hồ sơ trong DB, hiển thị nút tạo nhanh
                          if (profile == null)
                            TextButton.icon(
                              onPressed: () => _createInitialProfile(user),
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Thiết lập hồ sơ ban đầu'),
                            ),
                          const SizedBox(width: 6),
                          TextButton.icon(
                            onPressed: () {
                              // Giữ nguyên flow cũ: vào màn chỉnh sửa riêng
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => const EditParentScreen()),
                              );
                            },
                            icon: const Icon(Icons.edit, size: 18),
                            label: const Text('Chỉnh sửa'),
                          ),
                          const SizedBox(width: 6),
                          // Nút ĐỔI EMAIL - tích hợp reauth + verifyBeforeUpdateEmail
                          FilledButton.tonalIcon(
                            onPressed: () => _openChangeEmailSheet(user),
                            icon: const Icon(Icons.alternate_email),
                            label: const Text('Đổi email'),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          const SizedBox(height: 12),
          _sectionTitle('Trẻ:'),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: _ChildrenListWrap(),
            ),
          ),

          const SizedBox(height: 20),
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LearningProgressScreen()),
            ),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('Xem Tiến Độ Học'),
          ),

          const SizedBox(height: 12),
          FilledButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                if (!mounted) return;
                Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('Lỗi đăng xuất: $e')));
              }
            },
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
              minimumSize: const Size.fromHeight(48),
            ),
            child: const Text('Đăng Xuất'),
          ),
        ],
      ),
    );
  }

  Future<void> _createInitialProfile(User user) async {
    final uid = user.uid;
    final name = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();
    final phone = (user.phoneNumber ?? '').trim();
    final username = _deriveUsername(email.isNotEmpty ? email : 'user@$uid', uid);

    try {
      // Cập nhật mềm, có mốc thời gian server
      await _userService.upsertProfile(
        uid: uid,
        name: name.isNotEmpty ? name : null,
        username: username,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
      );
      if (name.isNotEmpty) await _userService.updateAuthDisplayName(name);

      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Đã tạo hồ sơ ban đầu')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Lỗi tạo hồ sơ: $e')));
    }
  }

  // ==== Bottom sheet đổi email: re-auth + verifyBeforeUpdateEmail ====
  void _openChangeEmailSheet(User user) {
    final newEmailCtrl = TextEditingController();
    final passCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();
    bool busy = false;
    String? err;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {
          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false)) return;
            setS(() => busy = true);
            try {
              final cred = EmailAuthProvider.credential(
                email: user.email!,
                password: passCtrl.text.trim(),
              );
              await user.reauthenticateWithCredential(cred);
              await user.verifyBeforeUpdateEmail(newEmailCtrl.text.trim());

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                content: Text('Đã gửi email xác minh đến email MỚI. '
                    'Hãy mở hộp thư, bấm link xác minh, rồi đăng nhập lại bằng email mới.'),
              ));
              Navigator.pop(context);
            } on FirebaseAuthException catch (e) {
              String msg = e.message ?? e.code;
              if (e.code == 'requires-recent-login') {
                msg = 'Vui lòng nhập mật khẩu để xác thực lại.';
              } else if (e.code == 'email-already-in-use') {
                msg = 'Email đã được sử dụng.';
              } else if (e.code == 'invalid-email') {
                msg = 'Email không hợp lệ.';
              } else if (e.code == 'wrong-password') {
                msg = 'Mật khẩu không đúng.';
              }
              setS(() => err = msg);
            } catch (e) {
              setS(() => err = e.toString());
            } finally {
              setS(() => busy = false);
            }
          }

          final bottomInset = MediaQuery.of(ctx).viewInsets.bottom;
          return Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottomInset),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Đổi email', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.email ?? '',
                    readOnly: true,
                    decoration: const InputDecoration(
                      labelText: 'Email hiện tại',
                      prefixIcon: Icon(Icons.email_outlined),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Email mới',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Vui lòng nhập email mới';
                      if (!s.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Mật khẩu hiện tại (để xác thực lại)',
                      prefixIcon: Icon(Icons.lock_outline),
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: const Icon(Icons.send),
                    label: Text(busy ? 'Đang xử lý...' : 'Gửi email xác minh & đổi'),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  String _deriveUsername(String emailOrElse, String uid) {
    final at = emailOrElse.indexOf('@');
    if (at > 0) return emailOrElse.substring(0, at);
    return 'user_${uid.substring(0, 6)}';
  }

  Widget _sectionTitle(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(t, style: const TextStyle(fontWeight: FontWeight.w700)),
  );

  Widget _line(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      children: [
        Expanded(flex: 3, child: Text('$k:')),
        Expanded(flex: 5, child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    ),
  );
}

/// Bọc riêng để không rebuild cả card phụ huynh khi danh sách trẻ thay đổi
class _ChildrenListWrap extends StatelessWidget {
  const _ChildrenListWrap();

  @override
  Widget build(BuildContext context) {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text('Chưa đăng nhập.'),
      );
    }
    return _ChildrenList(parentUid: parentUid);
  }
}

class _ChildrenList extends StatelessWidget {
  const _ChildrenList({required this.parentUid});
  final String parentUid;

  @override
  Widget build(BuildContext context) {
    // Bọc try/catch + errorBuilder để tránh “đỏ màn”
    return StreamBuilder<List<Tre>>(
      stream: TreService().watchTreList(parentUid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Lỗi tải danh sách trẻ: ${snap.error}', style: const TextStyle(color: Colors.red)),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Text('Chưa có hồ sơ trẻ.'),
          );
        }
        return Column(
          children: list.map((t) {
            return ListTile(
              leading: const CircleAvatar(child: Icon(Icons.child_care)),
              title: Text(t.hoTen.isEmpty ? 'Bé' : t.hoTen),
              subtitle: Text(
                'Giới tính: ${t.gioiTinh.isEmpty ? "—" : t.gioiTinh}  •  '
                    'Ngày sinh: ${t.ngaySinh.isEmpty ? "—" : t.ngaySinh}',
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
