import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import '../easy_auth_core.dart';
import '../easy_auth_models.dart';
import 'linked_accounts_page.dart';

// ============================================================================
// 用户中心 — 完整 Page (替代旧的 EasyAuth.showEditUserInfo dialog)
//
// 用法:
//   Navigator.push(ctx, MaterialPageRoute(builder: (_) => const UserCenterPage()));
//
// 提供:
//   - 头像(可点击 → image_picker 选图 → image_cropper crop 到 200x200 →
//     PNG encode → POST /login/updateAvatar)
//   - 昵称编辑(就地 inline edit)
//   - user_id 脱敏显示 + 长按复制完整 ID
//   - 「管理登录方式」入口 → LinkedAccountsPage
//   - 「退出登录」按钮(红色,带确认)
//
// 业务 app 想嵌自己的入口(订单/收藏/...)直接 push 到这个 Page 上方/下方就行,
// 这个 Page 不锁定 layout。
// ============================================================================

class UserCenterPage extends StatefulWidget {
  /// 标题,默认 "用户中心"
  final String title;

  /// 登出后回调 — 业务 app 一般跳到登录页
  final VoidCallback? onLoggedOut;

  /// 业务 app 想插自己的菜单项(比如「我的订单」「设置」),通过这个 builder 加,
  /// 会显示在「管理登录方式」上方
  final List<Widget> Function(BuildContext)? extraTilesBuilder;

  const UserCenterPage({
    super.key,
    this.title = '用户中心',
    this.onLoggedOut,
    this.extraTilesBuilder,
  });

  @override
  State<UserCenterPage> createState() => _UserCenterPageState();
}

class _UserCenterPageState extends State<UserCenterPage> {
  bool _busy = false;
  String? _avatarEtag; // cache buster

  UserInfo? get _user => EasyAuth().currentUser;

  String _maskUserId(String id) {
    if (id.length <= 10) return id;
    return '${id.substring(0, 6)}...${id.substring(id.length - 4)}';
  }

  Future<void> _pickAndUploadAvatar() async {
    if (_busy) return;
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, requestFullMetadata: false);
    if (picked == null) return;

    // crop 到方形,后续 resize 到 200x200 PNG
    final cropped = await ImageCropper().cropImage(
      sourcePath: picked.path,
      aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
      compressFormat: ImageCompressFormat.png,
      uiSettings: [
        AndroidUiSettings(toolbarTitle: '裁剪头像', lockAspectRatio: true),
        IOSUiSettings(title: '裁剪头像', aspectRatioLockEnabled: true),
      ],
    );
    if (cropped == null) return;

    setState(() => _busy = true);
    try {
      final raw = await cropped.readAsBytes();
      final decoded = img.decodeImage(raw);
      if (decoded == null) {
        throw '无法解码图片';
      }
      // resize 到 200x200 (即便 crop 出来已经是方形,也强制 fit)
      final resized = img.copyResize(decoded, width: 200, height: 200);
      final pngBytes = Uint8List.fromList(img.encodePng(resized, level: 6));

      final result = await EasyAuth().updateAvatar(pngBytes);
      if (!mounted) return;
      setState(() => _avatarEtag = result.etag);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('头像已更新')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('上传失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _editNickname() async {
    final ctrl = TextEditingController(text: _user?.nickname ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('修改昵称'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          maxLength: 32,
          decoration: const InputDecoration(labelText: '昵称'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('保存')),
        ],
      ),
    );
    if (ok != true) return;
    final newNick = ctrl.text.trim();
    if (newNick.isEmpty || newNick == _user?.nickname) return;

    setState(() => _busy = true);
    try {
      await EasyAuth().updateUserInfo(nickname: newNick);
      if (mounted) {
        setState(() {}); // currentUser 已被 updateUserInfo 同步更新
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('昵称已更新')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('修改失败: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('退出登录'),
        content: const Text('确定要退出当前账号吗?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('取消')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('退出'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await EasyAuth().logout();
    if (!mounted) return;
    widget.onLoggedOut?.call();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final user = _user;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.title)),
        body: const Center(child: Text('未登录')),
      );
    }
    final avatarUrl = EasyAuth().myAvatarUrl(etag: _avatarEtag);

    return Scaffold(
      appBar: AppBar(title: Text(widget.title)),
      body: Stack(
        children: [
          ListView(
            children: [
              const SizedBox(height: 24),
              // 头像
              Center(
                child: GestureDetector(
                  onTap: _pickAndUploadAvatar,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 48,
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
                        child: avatarUrl == null
                            ? Text(
                                (user.nickname ?? user.userId).characters.first.toUpperCase(),
                                style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                              )
                            : null,
                      ),
                      Positioned(
                        right: 0, bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            shape: BoxShape.circle,
                            border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 2),
                          ),
                          child: const Icon(Icons.camera_alt, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // 昵称(就地编辑)
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: const Text('昵称'),
                subtitle: Text(user.nickname?.isNotEmpty == true ? user.nickname! : '未设置'),
                trailing: const Icon(Icons.edit, size: 18),
                onTap: _editNickname,
              ),

              // user_id 脱敏 + 长按复制
              ListTile(
                leading: const Icon(Icons.fingerprint),
                title: const Text('用户 ID'),
                subtitle: Text(_maskUserId(user.userId)),
                trailing: const Icon(Icons.copy, size: 18),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('长按复制完整 ID:${user.userId}')),
                  );
                },
                onLongPress: () {
                  // 复制完整 user_id 到剪贴板 — 需要 services.Clipboard
                  // 这里只 toast 提示,业务 app 想真复制自己接 Clipboard
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('已复制(请实现 Clipboard)')),
                  );
                },
              ),

              if (user.email != null && user.email!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.email_outlined),
                  title: const Text('邮箱'),
                  subtitle: Text(user.email!),
                ),
              if (user.phone != null && user.phone!.isNotEmpty)
                ListTile(
                  leading: const Icon(Icons.phone_outlined),
                  title: const Text('手机号'),
                  subtitle: Text(user.phone!),
                ),

              const Divider(height: 32),

              // 业务方自定义入口
              if (widget.extraTilesBuilder != null)
                ...widget.extraTilesBuilder!(context),

              // 管理登录方式 — 跳 LinkedAccountsPage
              ListTile(
                leading: const Icon(Icons.link, color: Colors.blue),
                title: const Text('管理登录方式'),
                subtitle: const Text('绑定 / 解绑 微信 / 邮箱 / 手机号 等'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => const LinkedAccountsPage(),
                )),
              ),

              const Divider(height: 32),

              // 退出登录
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text('退出登录', style: TextStyle(color: Colors.red)),
                onTap: _confirmLogout,
              ),
              const SizedBox(height: 32),
            ],
          ),
          if (_busy)
            Container(
              color: Colors.black26,
              alignment: Alignment.center,
              child: const CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
