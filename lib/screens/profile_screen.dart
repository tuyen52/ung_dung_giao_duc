// lib/screens/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/tre_service.dart';
import '../models/tre.dart';
import 'learning_progress_screen.dart';
import 'edit_parent_screen.dart';
import 'tre_detail_screen.dart'; // <<< DÒNG MỚI: Import màn hình chi tiết của trẻ

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
          // Bỏ qua lỗi sync nhẹ
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
        SnackBar(content: Text('Đã làm mới trạng thái tài khoản', style: GoogleFonts.quicksand())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi reload: $e', style: GoogleFonts.quicksand())),
      );
    }
  }

  Future<void> _createInitialProfile(User user) async {
    final uid = user.uid;
    final name = (user.displayName ?? '').trim();
    final email = (user.email ?? '').trim();
    final phone = (user.phoneNumber ?? '').trim();
    final username = _deriveUsername(email.isNotEmpty ? email : 'user@$uid', uid);

    try {
      await _userService.upsertProfile(
        uid: uid,
        name: name.isNotEmpty ? name : null,
        username: username,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
      );
      if (name.isNotEmpty) await _userService.updateAuthDisplayName(name);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Đã tạo hồ sơ ban đầu', style: GoogleFonts.quicksand())));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi tạo hồ sơ: $e', style: GoogleFonts.quicksand())));
    }
  }

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
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Đã gửi email xác minh đến email MỚI. Hãy mở hộp thư, bấm link xác minh, rồi đăng nhập lại bằng email mới.', style: GoogleFonts.quicksand()),
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
                  Text('Đổi email', style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  TextFormField(
                    initialValue: user.email ?? '',
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Email hiện tại',
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: const OutlineInputBorder(),
                      labelStyle: GoogleFonts.quicksand(),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: newEmailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email mới',
                      prefixIcon: const Icon(Icons.alternate_email),
                      border: const OutlineInputBorder(),
                      labelStyle: GoogleFonts.quicksand(),
                    ),
                    validator: (v) {
                      final s = (v ?? '').trim();
                      if (s.isEmpty) return 'Vui lòng nhập email mới';
                      if (!s.contains('@')) return 'Email không hợp lệ';
                      return null;
                    },
                    style: GoogleFonts.quicksand(),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu hiện tại (để xác thực lại)',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      labelStyle: GoogleFonts.quicksand(),
                    ),
                    validator: (v) => (v == null || v.isEmpty) ? 'Nhập mật khẩu' : null,
                    style: GoogleFonts.quicksand(),
                  ),
                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!, style: GoogleFonts.quicksand(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: busy ? null : submit,
                    icon: const Icon(Icons.send),
                    label: Text(busy ? 'Đang xử lý...' : 'Gửi email xác minh & đổi', style: GoogleFonts.quicksand()),
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

  Widget _buildProfileSection({
    required String title,
    required List<Widget> children,
    VoidCallback? onEdit,
  }) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      margin: const EdgeInsets.symmetric(horizontal: 0),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF6A1B9A),
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFFBA68C8), size: 24),
                    onPressed: onEdit,
                  ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoLine(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: const Color(0xFFBA68C8), size: 20),
            const SizedBox(width: 12),
          ],
          Text(
            '$label:',
            style: GoogleFonts.quicksand(
              fontSize: 16,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.quicksand(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 24, color: Colors.white),
      label: Text(
        label,
        style: GoogleFonts.quicksand(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 8,
        shadowColor: color.withOpacity(0.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Hồ Sơ Của Tôi', style: GoogleFonts.quicksand(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _reloadUser,
            icon: const Icon(Icons.refresh, color: Colors.white),
          ),
        ],
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFFBA68C8),
                Color(0xFF8EC5FC),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Lớp nền với gradient cho toàn bộ màn hình
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFFE0C3FC),
                  Color(0xFF8EC5FC),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          // Lớp nội dung có cuộn và padding an toàn
          user == null
              ? Center(
            child: Text(
              'Vui lòng đăng nhập',
              style: GoogleFonts.quicksand(color: Colors.white, fontSize: 18),
            ),
          )
              : SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildParentProfileContent(user),
                    const SizedBox(height: 24),
                    _buildProfileSection(
                      title: 'Trẻ:',
                      children: [
                        _ChildrenListWrap(),
                      ],
                    ),
                    const SizedBox(height: 30),
                    _buildActionButton(
                      label: 'Xem Tiến Độ Học',
                      icon: Icons.timeline_rounded,
                      color: const Color(0xFFFFA726),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LearningProgressScreen()),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildActionButton(
                      label: 'Đăng Xuất',
                      icon: Icons.logout_rounded,
                      color: Colors.redAccent,
                      onPressed: () async {
                        try {
                          await FirebaseAuth.instance.signOut();
                          if (!mounted) return;
                          Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                        } catch (e) {
                          if (!mounted) return;
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Lỗi đăng xuất: $e', style: GoogleFonts.quicksand())),
                          );
                        }
                      },
                    ),
                    SizedBox(height: MediaQuery.of(context).padding.bottom + 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParentProfileContent(User user) {
    return StreamBuilder<Map<String, dynamic>?>(
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

        final displayName = name?.isNotEmpty == true ? name! : (user.displayName ?? '—');
        final displayEmail = email?.isNotEmpty == true ? email! : (user.email ?? '—');
        final displayPhone = phone?.isNotEmpty == true ? phone! : (user.phoneNumber ?? '—');
        final displayUsername = username?.isNotEmpty == true ? username! : _deriveUsername(displayEmail, user.uid);
        final displayAddress = address?.isNotEmpty == true ? address! : '—';

        return _buildProfileSection(
          title: 'Phụ Huynh:',
          onEdit: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const EditParentScreen()),
            );
          },
          children: [
            if (hasErr)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text('Lỗi tải hồ sơ: ${snap.error}', style: GoogleFonts.quicksand(color: Colors.red)),
              ),
            if (loading || _syncingEmail)
              const Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: LinearProgressIndicator(minHeight: 2, color: Color(0xFF6A1B9A)),
              ),
            _buildInfoLine('Họ và tên', displayName, icon: Icons.badge_outlined),
            _buildInfoLine('Username', displayUsername, icon: Icons.alternate_email_outlined),
            _buildInfoLine('Email', displayEmail, icon: Icons.email_outlined),
            _buildEmailVerificationStatus(user),
            _buildInfoLine('Số điện thoại', displayPhone, icon: Icons.phone_outlined),
            _buildInfoLine('Địa chỉ', displayAddress, icon: Icons.home_outlined),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (profile == null)
                  TextButton.icon(
                    onPressed: () => _createInitialProfile(user),
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Thiết lập hồ sơ ban đầu', style: GoogleFonts.quicksand()),
                  ),
                const SizedBox(width: 6),
                FilledButton.tonalIcon(
                  onPressed: () => _openChangeEmailSheet(user),
                  icon: const Icon(Icons.alternate_email, color: Color(0xFF6A1B9A)),
                  label: Text('Đổi email', style: GoogleFonts.quicksand(color: const Color(0xFF6A1B9A))),
                  style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE0C3FC)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmailVerificationStatus(User user) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(
            user.emailVerified ? Icons.verified : Icons.info_outline,
            size: 16,
            color: user.emailVerified ? Colors.green : Colors.orange,
          ),
          const SizedBox(width: 6),
          Text(
            user.emailVerified ? 'Đã xác minh' : 'Chưa xác minh',
            style: GoogleFonts.quicksand(
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
                    SnackBar(content: Text('Đã gửi lại email xác minh.', style: GoogleFonts.quicksand())),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Lỗi gửi xác minh: $e', style: GoogleFonts.quicksand())),
                  );
                }
              },
              child: Text('Gửi xác minh', style: GoogleFonts.quicksand(color: Colors.orange)),
            ),
        ],
      ),
    );
  }
}

String _deriveUsername(String emailOrElse, String uid) {
  final at = emailOrElse.indexOf('@');
  if (at > 0) return emailOrElse.substring(0, at);
  return 'user_${uid.substring(0, 6)}';
}

Widget _buildProfileSection({
  required String title,
  required List<Widget> children,
  VoidCallback? onEdit,
}) {
  return Card(
    elevation: 8,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    margin: const EdgeInsets.symmetric(horizontal: 0),
    child: Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF6A1B9A),
                ),
              ),
              if (onEdit != null)
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFFBA68C8), size: 24),
                  onPressed: onEdit,
                ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    ),
  );
}

Widget _buildInfoLine(String label, String value, {IconData? icon}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, color: const Color(0xFFBA68C8), size: 20),
          const SizedBox(width: 12),
        ],
        Text(
          '$label:',
          style: GoogleFonts.quicksand(
            fontSize: 16,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: GoogleFonts.quicksand(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );
}

Widget _buildActionButton({
  required String label,
  required IconData icon,
  required Color color,
  required VoidCallback onPressed,
}) {
  return ElevatedButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, size: 24, color: Colors.white),
    label: Text(
      label,
      style: GoogleFonts.quicksand(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(vertical: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      elevation: 8,
      shadowColor: color.withOpacity(0.5),
    ),
  );
}

class _ChildrenListWrap extends StatelessWidget {
  const _ChildrenListWrap();

  @override
  Widget build(BuildContext context) {
    final parentUid = FirebaseAuth.instance.currentUser?.uid;
    if (parentUid == null) {
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Text('Chưa đăng nhập.', style: GoogleFonts.quicksand()),
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
    return StreamBuilder<List<Tre>>(
      stream: TreService().watchTreList(parentUid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Lỗi tải danh sách trẻ: ${snap.error}', style: GoogleFonts.quicksand(color: Colors.red)),
          );
        }
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator(color: Color(0xFF6A1B9A))),
          );
        }
        final list = snap.data ?? const <Tre>[];
        if (list.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text('Chưa có hồ sơ trẻ.', style: GoogleFonts.quicksand(color: Colors.grey[700])),
          );
        }
        return Column(
          children: list.map((t) {
            final isMale = t.gioiTinh.toLowerCase() == 'nam';
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isMale ? Colors.lightBlueAccent : Colors.pinkAccent,
                    radius: 25,
                    child: Icon(isMale ? Icons.boy_rounded : Icons.girl_rounded, color: Colors.white, size: 30),
                  ),
                  title: Text(
                    t.hoTen.isEmpty ? 'Bé' : t.hoTen,
                    style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    'Giới tính: ${t.gioiTinh.isEmpty ? "—" : t.gioiTinh}',
                    style: GoogleFonts.quicksand(color: Colors.grey[600]),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  onTap: () { // <<< SỬA Ở ĐÂY
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TreDetailScreen(tre: t)),
                    );
                  },
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }
}