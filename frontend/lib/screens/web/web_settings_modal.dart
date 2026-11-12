import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../components/catas_dialog.dart';
import '../../components/catas_dropdown.dart';
import '../../components/catas_page.dart';
import '../../core/design_tokens.dart';
import '../../core/router.dart';
import '../../core/web_page_renderer.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../providers/theme_provider.dart';
import '../assinatura/manage_subscription_screen.dart';
import '../configuracoes/account_settings_screen.dart';

/// Desktop settings modeled after a focused, two-pane productivity workspace.
class WebSettingsModal extends StatefulWidget {
  const WebSettingsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => const WebSettingsModal(),
    );
  }

  @override
  State<WebSettingsModal> createState() => _WebSettingsModalState();
}

enum _SettingsSection {
  general,
  account,
  subscription,
  privacy,
  integrations,
  help,
}

class _WebSettingsModalState extends State<WebSettingsModal> {
  _SettingsSection _section = _SettingsSection.general;
  String _searchQuery = '';
  String _notificationsPreference = 'Todas';
  String _conversationDensity = 'Confortável';
  String _responseStyle = 'Objetivo';

  @override
  Widget build(BuildContext context) {
    final tokens = context.catasTokens;

    return Dialog(
      insetPadding: const EdgeInsets.all(32),
      backgroundColor: tokens.surfaceRaised,
      surfaceTintColor: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040, maxHeight: 760),
        child: SizedBox(
          width: 1040,
          height: 760,
          child: Column(
            children: [
              _buildHeader(tokens),
              Expanded(
                child: Row(
                  children: [
                    SizedBox(width: 254, child: _buildSidebar(tokens)),
                    VerticalDivider(width: 1, color: tokens.borderSubtle),
                    Expanded(child: _buildContent(tokens)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(CatasThemeTokens tokens) {
    return Container(
      height: 60,
      padding: const EdgeInsets.only(left: 20, right: 10),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Row(
        children: [
          Text(
            'Configurações',
            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const Spacer(),
          IconButton(
            tooltip: 'Fechar configurações',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close_rounded),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(CatasThemeTokens tokens) {
    return ColoredBox(
      color: tokens.surfaceMuted.withValues(alpha: 0.38),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: TextField(
              onChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                hintText: 'Procurar',
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                filled: true,
                fillColor: tokens.surfaceRaised,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 2, 10, 16),
              children: [
                _navGroup('Preferências', [
                  _navItem(
                    section: _SettingsSection.general,
                    icon: Icons.tune_rounded,
                    label: 'Geral',
                  ),
                  _navItem(
                    section: _SettingsSection.account,
                    icon: Icons.person_outline_rounded,
                    label: 'Conta',
                  ),
                  _navItem(
                    section: _SettingsSection.privacy,
                    icon: Icons.shield_outlined,
                    label: 'Privacidade e dados',
                  ),
                  _navItem(
                    section: _SettingsSection.subscription,
                    icon: Icons.credit_card_outlined,
                    label: 'Plano e cobrança',
                  ),
                ]),
                _navGroup('Espaço de trabalho', [
                  _navItem(
                    section: _SettingsSection.integrations,
                    icon: Icons.extension_outlined,
                    label: 'Integrações',
                  ),
                  _navItem(
                    section: _SettingsSection.help,
                    icon: Icons.help_outline_rounded,
                    label: 'Ajuda e suporte',
                  ),
                ]),
              ],
            ),
          ),
          _buildProfileFooter(tokens),
        ],
      ),
    );
  }

  Widget _navGroup(String label, List<Widget> items) {
    final visibleItems = items.whereType<_VisibleSettingsItem>().toList();
    if (visibleItems.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 7),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          ...visibleItems,
        ],
      ),
    );
  }

  Widget _navItem({
    required _SettingsSection section,
    required IconData icon,
    required String label,
  }) {
    final matches =
        _searchQuery.isEmpty || label.toLowerCase().contains(_searchQuery);
    if (!matches) return const SizedBox.shrink();
    return _VisibleSettingsItem(
      section: section,
      icon: icon,
      label: label,
      selected: _section == section,
      onTap: () => setState(() => _section = section),
    );
  }

  Widget _buildProfileFooter(CatasThemeTokens tokens) {
    final auth = context.watch<AuthProvider>();
    final name = auth.userName?.trim().isNotEmpty == true
        ? auth.userName!.trim()
        : 'Usuário';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: tokens.borderSubtle)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 17,
            backgroundColor: Theme.of(context).colorScheme.primary,
            backgroundImage: auth.userPhotoUrl == null
                ? null
                : NetworkImage(auth.userPhotoUrl!),
            child: auth.userPhotoUrl == null
                ? Text(
                    name[0].toUpperCase(),
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          IconButton(
            tooltip: 'Sair da conta',
            onPressed: _confirmLogout,
            icon: const Icon(Icons.logout_rounded, size: 19),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(CatasThemeTokens tokens) {
    return switch (_section) {
      _SettingsSection.general => _buildGeneral(tokens),
      _SettingsSection.account => Padding(
        padding: const EdgeInsets.all(24),
        child: AccountSettingsScreen(
          isEmbedded: true,
          onBack: () => setState(() => _section = _SettingsSection.general),
        ),
      ),
      _SettingsSection.subscription => Padding(
        padding: const EdgeInsets.all(24),
        child: ManageSubscriptionScreen(
          isEmbedded: true,
          onBack: () => setState(() => _section = _SettingsSection.general),
        ),
      ),
      _SettingsSection.privacy => _buildPrivacy(tokens),
      _SettingsSection.integrations => _buildIntegrations(tokens),
      _SettingsSection.help => _buildHelp(tokens),
    };
  }

  Widget _buildGeneral(CatasThemeTokens tokens) {
    final themeProvider = context.watch<ThemeProvider>();
    final localeProvider = context.watch<LocaleProvider>();
    final language = switch (localeProvider.locale?.languageCode) {
      'pt' => 'Português',
      'en' => 'English',
      _ => 'Sistema',
    };

    return _contentScroll(
      title: 'Aparência',
      subtitle: 'Personalize como o CATAS aparece e responde para você.',
      children: [
        _settingsRow(
          title: 'Tema',
          trailing: _themeSelector(themeProvider, tokens),
        ),
        _settingsRow(
          title: 'Fonte da interface',
          trailing: const _StaticValue('Inter'),
        ),
        _settingsRow(
          title: 'Densidade da conversa',
          trailing: _valueDropdown(
            value: _conversationDensity,
            options: const ['Compacta', 'Confortável', 'Espaçosa'],
            onChanged: (value) => setState(() => _conversationDensity = value),
          ),
        ),
        _settingsRow(
          title: 'Estilo das respostas',
          trailing: _valueDropdown(
            value: _responseStyle,
            options: const ['Objetivo', 'Equilibrado', 'Detalhado'],
            onChanged: (value) => setState(() => _responseStyle = value),
          ),
        ),
        _settingsRow(
          title: 'Idioma',
          trailing: _valueDropdown(
            value: language,
            options: const ['Sistema', 'Português', 'English'],
            onChanged: (value) {
              context.read<LocaleProvider>().setLocale(switch (value) {
                'Português' => const Locale('pt'),
                'English' => const Locale('en'),
                _ => null,
              });
            },
          ),
        ),
        const SizedBox(height: 34),
        Text(
          'Notificações',
          style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        _settingsRow(
          title: 'Atualizações do CATAS',
          subtitle:
              'Receba avisos sobre execuções, integrações e tarefas importantes.',
          trailing: _valueDropdown(
            value: _notificationsPreference,
            options: const ['Todas', 'Importantes', 'Nenhuma'],
            onChanged: (value) =>
                setState(() => _notificationsPreference = value),
          ),
        ),
      ],
    );
  }

  Widget _themeSelector(ThemeProvider provider, CatasThemeTokens tokens) {
    Widget button(ThemeMode mode, IconData icon, String tooltip) {
      final selected = provider.themeMode == mode;
      return Tooltip(
        message: tooltip,
        child: IconButton(
          onPressed: () => provider.setThemeMode(mode),
          icon: Icon(icon, size: 18),
          color: selected
              ? Theme.of(context).colorScheme.onPrimary
              : Theme.of(context).colorScheme.onSurfaceVariant,
          style: IconButton.styleFrom(
            minimumSize: const Size(36, 34),
            backgroundColor: selected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(tokens.radiusSmall - 2),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: tokens.surfaceMuted,
        border: Border.all(color: tokens.borderSubtle),
        borderRadius: BorderRadius.circular(tokens.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          button(ThemeMode.light, Icons.light_mode_outlined, 'Tema claro'),
          button(ThemeMode.dark, Icons.dark_mode_outlined, 'Tema escuro'),
          button(
            ThemeMode.system,
            Icons.brightness_auto_outlined,
            'Tema do sistema',
          ),
        ],
      ),
    );
  }

  Widget _buildPrivacy(CatasThemeTokens tokens) {
    return _contentScroll(
      title: 'Privacidade e dados',
      subtitle: 'Controle seus dados, permissões e informações armazenadas.',
      children: [
        CatasSurface(
          child: Column(
            children: [
              _actionRow(
                icon: Icons.file_download_outlined,
                title: 'Exportar meus dados',
                detail: 'Baixe uma cópia das suas informações.',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.settingsExport);
                },
              ),
              Divider(height: 1, color: tokens.borderSubtle),
              _actionRow(
                icon: Icons.policy_outlined,
                title: 'Política de privacidade',
                detail: 'Entenda como tratamos os seus dados.',
                onTap: () {
                  if (kIsWeb) navigateTo('/privacy');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntegrations(CatasThemeTokens tokens) {
    return _contentScroll(
      title: 'Integrações',
      subtitle: 'Conecte seus serviços para transformar pedidos em automações.',
      children: [
        CatasSurface(
          child: Column(
            children: [
              _actionRow(
                icon: Icons.extension_outlined,
                title: 'Gerenciar integrações',
                detail: 'Conecte Gmail, Agenda, Drive e outros serviços.',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.integrations);
                },
              ),
              Divider(height: 1, color: tokens.borderSubtle),
              _actionRow(
                icon: Icons.bolt_outlined,
                title: 'Ver automações',
                detail: 'Acompanhe os fluxos que estão em execução.',
                onTap: () {
                  Navigator.of(context).pop();
                  context.go(AppRoutes.automations);
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHelp(CatasThemeTokens tokens) {
    return _contentScroll(
      title: 'Ajuda e suporte',
      subtitle: 'Encontre respostas ou fale com a equipe do CATAS.',
      children: [
        CatasSurface(
          child: Column(
            children: [
              _actionRow(
                icon: Icons.help_outline_rounded,
                title: 'Central de ajuda',
                detail: 'Veja orientações para usar o CATAS.',
                onTap: () {
                  if (kIsWeb) navigateTo('/contact');
                },
              ),
              Divider(height: 1, color: tokens.borderSubtle),
              _actionRow(
                icon: Icons.info_outline_rounded,
                title: 'Sobre o CATAS',
                detail: 'Conheça o produto e a nossa proposta.',
                onTap: () {
                  if (kIsWeb) navigateTo('/about');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _contentScroll({
    required String title,
    required String subtitle,
    required List<Widget> children,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(32, 28, 32, 36),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 680),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 13,
                height: 1.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _settingsRow({
    required String title,
    String? subtitle,
    required Widget trailing,
  }) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.catasTokens.borderSubtle),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      height: 1.45,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 18),
          trailing,
        ],
      ),
    );
  }

  Widget _actionRow({
    required IconData icon,
    required String title,
    required String detail,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(context.catasTokens.radiusSmall),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _valueDropdown({
    required String value,
    required List<String> options,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      width: 176,
      child: CatasDropdown<String>(
        value: value,
        items: options
            .map((option) => CatasDropdownItem(value: option, label: option))
            .toList(),
        onChanged: onChanged,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showCatasDialog<bool>(
      context: context,
      title: 'Sair da conta?',
      message: 'Você poderá entrar novamente quando quiser.',
      icon: Icon(
        Icons.logout_rounded,
        color: context.catasTokens.danger,
        size: 34,
      ),
      actionsBuilder: (dialogContext) => [
        CatasDialogAction(
          label: 'Cancelar',
          isSecondary: true,
          onPressed: () => Navigator.pop(dialogContext, false),
        ),
        CatasDialogAction(
          label: 'Sair',
          onPressed: () => Navigator.pop(dialogContext, true),
        ),
      ],
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
      if (mounted) Navigator.of(context).pop();
    }
  }
}

class _VisibleSettingsItem extends StatelessWidget {
  final _SettingsSection section;
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _VisibleSettingsItem({
    required this.section,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: context.reduceMotion ? Duration.zero : CatasMotion.fast,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? theme.colorScheme.onSurface.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: selected
                      ? theme.colorScheme.onSurface
                      : theme.colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StaticValue extends StatelessWidget {
  final String value;

  const _StaticValue(this.value);

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      style: GoogleFonts.inter(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
