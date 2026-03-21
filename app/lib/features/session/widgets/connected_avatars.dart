import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/avatar_widget.dart';
import '../../../l10n/app_localizations.dart';

/// Two avatars facing each other with a connecting line between them.
/// Shows confirmation status for each party.
class ConnectedAvatars extends StatefulWidget {
  final String userName;
  final String? userAvatar;
  final bool userConfirmed;
  final String otherUserName;
  final String? otherUserAvatar;
  final bool otherConfirmed;

  const ConnectedAvatars({
    super.key,
    required this.userName,
    this.userAvatar,
    required this.userConfirmed,
    required this.otherUserName,
    this.otherUserAvatar,
    required this.otherConfirmed,
  });

  @override
  State<ConnectedAvatars> createState() => _ConnectedAvatarsState();
}

class _ConnectedAvatarsState extends State<ConnectedAvatars>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseCtrl;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  bool get _bothConfirmed => widget.userConfirmed && widget.otherConfirmed;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Left avatar (You)
          Expanded(child: _AvatarSide(
            name: 'You',
            avatarUrl: widget.userAvatar,
            fullName: widget.userName,
            confirmed: widget.userConfirmed,
            pulseAnimation: _pulse,
          )),

          // Connecting line
          SizedBox(
            width: 60,
            height: 4,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              decoration: BoxDecoration(
                color: _bothConfirmed
                    ? AppColors.success
                    : AppColors.divider,
                borderRadius: BorderRadius.circular(2),
              ),
              child: _bothConfirmed
                  ? null
                  : AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(2),
                          gradient: LinearGradient(
                            colors: [
                              AppColors.divider,
                              AppColors.primary.withValues(alpha: _pulse.value * 0.5),
                              AppColors.divider,
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),

          // Right avatar (Other user)
          Expanded(child: _AvatarSide(
            name: widget.otherUserName.split(' ').first,
            avatarUrl: widget.otherUserAvatar,
            fullName: widget.otherUserName,
            confirmed: widget.otherConfirmed,
            pulseAnimation: _pulse,
          )),
        ],
      ),
    );
  }
}

class _AvatarSide extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final String fullName;
  final bool confirmed;
  final Animation<double> pulseAnimation;

  const _AvatarSide({
    required this.name,
    this.avatarUrl,
    required this.fullName,
    required this.confirmed,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Avatar with status ring
        Stack(
          alignment: Alignment.center,
          children: [
            // Status ring
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (_, __) => Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: confirmed
                        ? AppColors.success
                        : AppColors.textHint.withValues(
                            alpha: 0.3 + pulseAnimation.value * 0.4),
                    width: 3,
                  ),
                ),
              ),
            ),
            AvatarWidget(
              imageUrl: avatarUrl,
              name: fullName,
              size: 56,
            ),
            // Check badge
            if (confirmed)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                  child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          name,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        Text(
          confirmed ? AppLocalizations.of(context).confirmed : AppLocalizations.of(context).waiting,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: confirmed ? AppColors.success : AppColors.textHint,
          ),
        ),
      ],
    );
  }
}
