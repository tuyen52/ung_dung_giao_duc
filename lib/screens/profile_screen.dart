// lib/screens/profile_screen.dart
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_service.dart';
import '../services/tre_service.dart';
import '../models/tre.dart';
import 'learning_progress_screen.dart';
import 'edit_parent_screen.dart';
import 'tre_detail_screen.dart';

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
    bool showEmailVerificationCheck = false; // Thêm state để hiện thị check verification

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setS) {

          // THÊM: Method kiểm tra email verification status
          Future<void> _checkEmailVerificationStatus() async {
            try {
              setS(() => busy = true);

              // Reload user để lấy thông tin mới nhất
              await user.reload();
              final currentUser = FirebaseAuth.instance.currentUser;

              if (currentUser == null) {
                setS(() => err = 'Không tìm thấy thông tin người dùng');
                return;
              }

              if (currentUser.emailVerified) {
                // Email đã được xác minh
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('✅ Email đã được xác minh thành công!',
                      style: GoogleFonts.quicksand()),
                  backgroundColor: Colors.green,
                ));
                Navigator.pop(context); // Đóng bottom sheet
              } else {
                // Email chưa được xác minh
                setS(() => err = '❌ Email chưa được xác minh. Vui lòng kiểm tra hộp thư.');
              }

            } catch (e) {
              setS(() => err = 'Lỗi kiểm tra trạng thái: $e');
            } finally {
              setS(() => busy = false);
            }
          }

          // THÊM: Method gửi lại email verification
          Future<void> _resendVerificationEmail() async {
            try {
              setS(() => busy = true);
              await user.sendEmailVerification();

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('📧 Đã gửi lại email xác minh!',
                    style: GoogleFonts.quicksand()),
              ));

            } catch (e) {
              setS(() => err = 'Lỗi gửi email: $e');
            } finally {
              setS(() => busy = false);
            }
          }

          // THÊM: Method kiểm tra email đã được sử dụng trong Firebase
          Future<bool> _checkEmailExists(String email) async {
            try {
              final emailToCheck = email.toLowerCase().trim();

              // Kiểm tra email trùng với email hiện tại
              if (emailToCheck == user.email?.toLowerCase()) {
                return true; // Email trùng với hiện tại
              }

              // Kiểm tra trong Realtime Database
              final databaseRef = FirebaseDatabase.instance.ref('users');
              final snapshot = await databaseRef.get();

              if (snapshot.exists) {
                final usersData = snapshot.value as Map<dynamic, dynamic>;

                // Duyệt qua tất cả users để kiểm tra email
                for (final userData in usersData.values) {
                  if (userData is Map && userData['email'] != null) {
                    final existingEmail = userData['email'].toString().toLowerCase();
                    if (existingEmail == emailToCheck) {
                      return true; // Email đã tồn tại trong database
                    }
                  }
                }
              }

              // Thêm kiểm tra bằng cách thử tạo user tạm (không khuyến nghị)
              // hoặc sử dụng Cloud Functions để kiểm tra Authentication

              return false; // Email chưa được sử dụng
            } catch (e) {
              print('Error checking email exists: $e');
              return false; // Nếu lỗi, cho phép tiếp tục (Firebase sẽ handle)
            }
          }

          Future<void> submit() async {
            if (!(formKey.currentState?.validate() ?? false)) return;

            // THÊM: Kiểm tra email trùng và đã tồn tại
            final newEmail = newEmailCtrl.text.trim();

            if (newEmail.toLowerCase() == user.email?.toLowerCase()) {
              setS(() => err = '❌ Email mới không được trùng với email hiện tại!');
              return;
            }

            setS(() {
              busy = true;
              err = null;
            });

            // Kiểm tra email đã tồn tại trong hệ thống
            final emailExists = await _checkEmailExists(newEmail);
            if (emailExists && newEmail.toLowerCase() != user.email?.toLowerCase()) {
              setS(() {
                err = '❌ Email này đã được sử dụng bởi tài khoản khác!';
                busy = false;
              });
              return;
            }

            try {
              final cred = EmailAuthProvider.credential(
                email: user.email!,
                password: passCtrl.text.trim(),
              );
              await user.reauthenticateWithCredential(cred);

              // Sử dụng updateEmail thay vì verifyBeforeUpdateEmail nếu không có
              try {
                await user.verifyBeforeUpdateEmail(newEmailCtrl.text.trim());
              } catch (noSuchMethodError) {
                // Fallback nếu verifyBeforeUpdateEmail không có
                await user.updateEmail(newEmailCtrl.text.trim());
                await user.sendEmailVerification();
              }

              // THAY ĐỔI: Hiện thị UI kiểm tra verification thay vì đóng ngay
              setS(() {
                showEmailVerificationCheck = true;
                err = null;
              });

              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Đã gửi email xác minh đến email MỚI. Hãy mở hộp thư, bấm link xác minh!',
                    style: GoogleFonts.quicksand()),
              ));

            } on FirebaseAuthException catch (e) {
              String msg = e.message ?? e.code;
              if (e.code == 'requires-recent-login') {
                msg = 'Vui lòng nhập mật khẩu để xác thực lại.';
              } else if (e.code == 'email-already-in-use' || e.code == 'email-already-exists') {
                msg = '❌ Email này đã được sử dụng bởi tài khoản khác!';
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
                  Text('Đổi email',
                      style: GoogleFonts.quicksand(fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),

                  // THÊM: Hiển thị trạng thái email verification hiện tại
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: user.emailVerified ? Colors.green.shade50 : Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: user.emailVerified ? Colors.green : Colors.orange,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          user.emailVerified ? Icons.verified : Icons.warning,
                          color: user.emailVerified ? Colors.green : Colors.orange,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            user.emailVerified
                                ? 'Email hiện tại đã được xác minh ✅'
                                : 'Email hiện tại chưa được xác minh ⚠️',
                            style: GoogleFonts.quicksand(
                              fontWeight: FontWeight.w600,
                              color: user.emailVerified ? Colors.green.shade800 : Colors.orange.shade800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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

                  // ĐIỀU KIỆN: Ẩn form nhập email mới khi đang check verification
                  if (!showEmailVerificationCheck) ...[
                    TextFormField(
                      controller: newEmailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email mới',
                        prefixIcon: const Icon(Icons.alternate_email),
                        border: const OutlineInputBorder(),
                        labelStyle: GoogleFonts.quicksand(),
                        helperText: 'Email mới phải khác với email hiện tại',
                        helperStyle: GoogleFonts.quicksand(fontSize: 12, color: Colors.grey.shade600),
                      ),
                      validator: (v) {
                        final s = (v ?? '').trim();
                        if (s.isEmpty) return 'Vui lòng nhập email mới';
                        if (!s.contains('@')) return 'Email không hợp lệ';

                        // THÊM: Kiểm tra email trùng với email hiện tại
                        if (s.toLowerCase() == user.email?.toLowerCase()) {
                          return '❌ Email mới không được trùng với email hiện tại!';
                        }

                        return null;
                      },
                      style: GoogleFonts.quicksand(),
                      // THÊM: Thay đổi màu border khi email trùng hoặc đã tồn tại
                      onChanged: (value) async {
                        final newEmail = value.toLowerCase().trim();

                        // Kiểm tra trùng với email hiện tại
                        if (newEmail == user.email?.toLowerCase()) {
                          setS(() => err = '⚠️ Email này trùng với email hiện tại');
                          return;
                        }

                        // Xóa lỗi cũ
                        if (err?.contains('trùng với email hiện tại') == true ||
                            err?.contains('đã được sử dụng') == true) {
                          setS(() => err = null);
                        }

                        // Kiểm tra email đã tồn tại (với debounce để tránh gọi quá nhiều)
                        if (newEmail.isNotEmpty && newEmail.contains('@')) {
                          // Đợi user ngừng gõ 1 giây rồi mới kiểm tra
                          await Future.delayed(const Duration(seconds: 1));
                          if (newEmailCtrl.text.toLowerCase().trim() == newEmail) {
                            final emailExists = await _checkEmailExists(newEmail);
                            if (emailExists && newEmail != user.email?.toLowerCase()) {
                              setS(() => err = '⚠️ Email này đã được sử dụng bởi tài khoản khác');
                            }
                          }
                        }
                      },
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
                  ],

                  // THÊM: UI kiểm tra email verification
                  if (showEmailVerificationCheck) ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        children: [
                          Icon(Icons.mark_email_read, size: 48, color: Colors.blue.shade600),
                          const SizedBox(height: 12),
                          Text(
                            'Email xác minh đã được gửi!',
                            style: GoogleFonts.quicksand(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.blue.shade800,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Vui lòng:\n1. Kiểm tra hộp thư email mới\n2. Bấm vào link xác minh\n3. Bấm "Kiểm tra trạng thái" bên dưới',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.quicksand(color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                    ),
                  ],

                  if (err != null) ...[
                    const SizedBox(height: 8),
                    Text(err!, style: GoogleFonts.quicksand(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),

                  // THAY ĐỔI: Các button tùy theo trạng thái
                  if (!showEmailVerificationCheck) ...[
                    // Button gửi email verification ban đầu
                    FilledButton.icon(
                      onPressed: busy ? null : submit,
                      icon: const Icon(Icons.send),
                      label: Text(
                        busy ? 'Đang xử lý...' : 'Gửi email xác minh & đổi',
                        style: GoogleFonts.quicksand(),
                      ),
                    ),
                  ] else ...[
                    // Buttons khi đã gửi email verification
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: busy ? null : _resendVerificationEmail,
                            icon: const Icon(Icons.refresh),
                            label: Text('Gửi lại', style: GoogleFonts.quicksand()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: busy ? null : _checkEmailVerificationStatus,
                            icon: const Icon(Icons.check_circle),
                            label: Text(
                              busy ? 'Đang kiểm tra...' : 'Kiểm tra trạng thái',
                              style: GoogleFonts.quicksand(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Đóng', style: GoogleFonts.quicksand()),
                    ),
                  ],
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
              colors: [Color(0xFFBA68C8), Color(0xFF8EC5FC)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFE0C3FC), Color(0xFF8EC5FC)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          user == null
              ? Center(
            child: Text(
              'Vui lòng đăng nhập',
              style: GoogleFonts.quicksand(color: Colors.white, fontSize: 18),
            ),
          )
              : SafeArea(
            child: OrientationBuilder(
              builder: (context, orientation) {
                if (orientation == Orientation.landscape) {
                  return _buildLandscapeLayout(user);
                } else {
                  return _buildPortraitLayout(user);
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortraitLayout(User user) {
    return SingleChildScrollView(
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
// For portrait, action buttons can be in a Column
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
    );
  }

  Widget _buildLandscapeLayout(User user) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _buildParentProfileContent(user),
                ),
                const SizedBox(width: 24),
                Expanded(
                  child: _buildProfileSection(
                    title: 'Trẻ:',
                    children: [
                      _ChildrenListWrap(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
// For landscape, action buttons are in a Row
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    label: 'Xem Tiến Độ Học',
                    icon: Icons.timeline_rounded,
// *** THAY ĐỔI MÀU Ở ĐÂY ***
                    color: const Color(0xFFFFA726), // Orange
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const LearningProgressScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildActionButton(
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
                ),
              ],
            ),
          ],
        ),
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
// *** ĐÃ TRẢ LẠI CÁC TRƯỜNG THÔNG TIN GỐC ***
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
                  onTap: () {
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
