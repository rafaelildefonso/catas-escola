import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../components/clickable_wrapper.dart';
import '../../providers/auth_provider.dart';
import '../../components/catas_dialog.dart';
import '../../components/catas_input.dart';

class AccountSettingsScreen extends StatefulWidget {
  final bool isEmbedded;
  final VoidCallback? onBack;

  const AccountSettingsScreen({
    super.key,
    this.isEmbedded = false,
    this.onBack,
  });

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? theme.colorScheme.error : null,
      ),
    );
  }

  Future<void> _showRenameDialog() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;
    final controller = TextEditingController(text: auth.userName);

    final newName = await showCatasDialog<String>(
      context: context,
      title: l10n.actionRename,
      content: Padding(
        padding: const EdgeInsets.only(top: 16),
        child: CatasInput(
          controller: controller,
          autofocus: true,
          hintText: l10n.fullName,
          maxLength: 50,
        ),
      ),
      actionsBuilder: (innerCtx) => [
        CatasDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(innerCtx),
          isSecondary: true,
        ),
        CatasDialogAction(
          label: l10n.actionSave,
          onPressed: () => Navigator.pop(innerCtx, controller.text),
        ),
      ],
    );

    if (newName != null &&
        newName.trim().isNotEmpty &&
        newName != auth.userName) {
      try {
        await auth.updateProfile(name: newName.trim());
        _showSnack(l10n.profileUpdated);
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  Future<void> _deleteAccount() async {
    final auth = context.read<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final theme = Theme.of(context);
    final confirmed = await showCatasDialog<bool>(
      context: context,
      title: l10n.deleteAccount,
      message: l10n.deleteAccountConfirmation,
      icon: Icon(Icons.warning_amber_rounded, size: 48, color: theme.colorScheme.error),
      actionsBuilder: (innerCtx) => [
        CatasDialogAction(
          label: l10n.cancel,
          onPressed: () => Navigator.pop(innerCtx, false),
          isSecondary: true,
        ),
        CatasDialogAction(
          label: l10n.deleteAccount,
          onPressed: () => Navigator.pop(innerCtx, true),
          isDestructive: true,
        ),
      ],
    );

    if (confirmed == true) {
      try {
        await auth.deleteAccount();
      } catch (e) {
        _showSnack(e.toString(), isError: true);
      }
    }
  }

  Widget _buildInitials(AuthProvider auth, ThemeData theme) {
    return Center(
      child: Text(
        (auth.userName ?? "U").trim().isEmpty ? "U" : (auth.userName ?? "U").trim()[0].toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final l10n = AppLocalizations.of(context)!;

    final content = SingleChildScrollView(
      physics: widget.isEmbedded
          ? const NeverScrollableScrollPhysics()
          : const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(
        horizontal: widget.isEmbedded ? 0 : 20,
        vertical: widget.isEmbedded ? 0 : 24,
      ),
      child: Column(
        children: [
          if (widget.isEmbedded && widget.onBack != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Row(
                children: [
                  IconButton(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back),
                    iconSize: 20,
                  ),
                  Text(
                    l10n.account,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

          // Avatar Section
          Clickable(
            onTap: () => _showSnack(l10n.featureInDevelopment),
            child: Column(
              children: [
                Container(
                  width: 110,
                  height: 110,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: theme.colorScheme.outlineVariant.withValues(
                        alpha: 0.5,
                      ),
                      width: 1,
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: auth.userPhotoUrl != null
                      ? Image.network(
                          auth.userPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              _buildInitials(auth, theme),
                        )
                      : _buildInitials(auth, theme),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.changeProfilePhoto,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),

          // Account Details Card
          Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerLow.withValues(
                alpha: 0.8,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: theme.colorScheme.outlineVariant.withValues(alpha: 0.8),
              ),
            ),
            child: Column(
              children: [
                // Name Row
                ListTile(
                  onTap: _showRenameDialog,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  title: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.nameLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          auth.userName ?? '---',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: theme.colorScheme.onSurfaceVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  color: theme.colorScheme.outlineVariant.withValues(
                    alpha: 0.8,
                  ),
                ),
                // Email Row
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 4,
                  ),
                  title: Row(
                    children: [
                      SizedBox(
                        width: 80,
                        child: Text(
                          l10n.emailLabel,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          auth.userEmail ?? '---',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          textAlign: TextAlign.right,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 35),
          

          const SizedBox(height: 40),

          // Delete Account Button for Embedded version
          if (widget.isEmbedded)
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _deleteAccount,
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                  foregroundColor: theme.colorScheme.error,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  l10n.deleteAccount,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.account,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 18,
            color: theme.colorScheme.onSurface,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: theme.colorScheme.onSurface),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(child: content),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _deleteAccount,
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error.withValues(alpha: 0.1),
                foregroundColor: theme.colorScheme.error,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                ),
                elevation: 0,
              ),
              child: Text(
                l10n.deleteAccount,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
