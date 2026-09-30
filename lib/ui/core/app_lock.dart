import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import '../../core/theme/omnya_colors.dart';
import '../../core/theme/omnya_typography.dart';
import '../../core/widgets/omnya_logo.dart';
import '../../core/widgets/tactile_button.dart';
import '../../data/repositories/protocol_repository.dart';

final _auth = LocalAuthentication();

/// Face ID, falling back to the passcode. False when she cancels or the phone can't check.
Future<bool> unlockWithFaceId(String reason) async {
  try {
    if (!await _auth.isDeviceSupported()) return false;
    return await _auth.authenticate(localizedReason: reason);
  } on PlatformException {
    return false;
  }
}

/// Covers the app with a lock when she turned on Face ID, on launch and each time it comes back.
class AppLock extends StatefulWidget {
  final Widget child;
  const AppLock({super.key, required this.child});

  @override
  State<AppLock> createState() => _AppLockState();
}

class _AppLockState extends State<AppLock> with WidgetsBindingObserver {
  late bool _locked = _enabled;
  bool _checking = false;

  bool get _enabled => context.read<ProtocolRepository>().profile?.lockWithFaceId ?? false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (_locked) WidgetsBinding.instance.addPostFrameCallback((_) => _unlock());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Face ID itself sends the app inactive, so only a real trip to the background locks it.
    if (state == AppLifecycleState.paused && _enabled && !_checking) setState(() => _locked = true);
    if (state == AppLifecycleState.resumed && _locked && !_checking) _unlock();
  }

  Future<void> _unlock() async {
    if (_checking) return;
    _checking = true;
    final ok = await unlockWithFaceId('Unlock Omnya');
    _checking = false;
    if (ok && mounted) setState(() => _locked = false);
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        widget.child,
        if (_locked)
          Positioned.fill(
            child: ColoredBox(
              color: OmnyaColors.sand,
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    children: [
                      const Spacer(),
                      const OmnyaLogo(size: 56),
                      const SizedBox(height: 20),
                      Text('Omnya is locked', style: OmnyaTypography.headline()),
                      const Spacer(),
                      TactileButton(label: 'Unlock', width: double.infinity, onPressed: _unlock),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
