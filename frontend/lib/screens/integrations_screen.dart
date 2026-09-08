import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:catas/components/brand_logo.dart';
import 'package:provider/provider.dart';
import 'package:catas/providers/auth_provider.dart';
import 'package:catas/providers/integrations_provider.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:catas/screens/integration_details_screen.dart';
import 'package:catas/components/upgrade_modal.dart';
import 'package:catas/l10n/app_localizations.dart';

enum IntegrationCategory {
  all('integrationsCategoryAll'),
  google('integrationsCategoryGoogle'),
  productivity('integrationsCategoryProductivity'),
  communication('integrationsCategoryCommunication'),
  crm('integrationsCategoryCRM');

  final String labelKey;
  const IntegrationCategory(this.labelKey);

  String getLabel(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    switch (this) {
      case IntegrationCategory.all:
        return l10n.integrationsCategoryAll;
      case IntegrationCategory.google:
        return l10n.integrationsCategoryGoogle;
      case IntegrationCategory.productivity:
        return l10n.integrationsCategoryProductivity;
      case IntegrationCategory.communication:
        return l10n.integrationsCategoryCommunication;
      case IntegrationCategory.crm:
        return l10n.integrationsCategoryCRM;
    }
  }
}

/// Dados de uma integração
@immutable
class IntegrationItem {
  final String title;
  final LogoId logoId;
  final String providerName;
  final List<IntegrationCategory> category;

  const IntegrationItem({
    required this.title,
    required this.logoId,
    required this.providerName,
    required this.category,
  });
}

class IntegrationsScreen extends StatefulWidget {
  const IntegrationsScreen({super.key});

  @override
  State<IntegrationsScreen> createState() => _IntegrationsScreenState();
}

class _IntegrationsScreenState extends State<IntegrationsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';

  // Lista de integrações com categorias
  static const List<IntegrationItem> _integrations = [
    // Produtividade
    IntegrationItem(
      title: 'Google Calendar',
      logoId: LogoId.googleCalendar,
      providerName: 'google_calendar',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Sheets',
      logoId: LogoId.googleSheets,
      providerName: 'google_sheets',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Drive',
      logoId: LogoId.googleDrive,
      providerName: 'google_drive',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Docs',
      logoId: LogoId.googleDocs,
      providerName: 'google_docs',
      category: [IntegrationCategory.productivity, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Notion',
      logoId: LogoId.notion,
      providerName: 'notion',
      category: [IntegrationCategory.productivity],
    ),
    // Comunicação
    IntegrationItem(
      title: 'Gmail',
      logoId: LogoId.googleGmail,
      providerName: 'google_gmail',
      category: [IntegrationCategory.communication, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Google Meet',
      logoId: LogoId.googleMeet,
      providerName: 'google_meet',
      category: [IntegrationCategory.communication, IntegrationCategory.google],
    ),
    IntegrationItem(
      title: 'Whatsapp',
      logoId: LogoId.whatsapp,
      providerName: 'whatsapp',
      category: [IntegrationCategory.communication],
    ),
    IntegrationItem(
      title: 'Slack',
      logoId: LogoId.slack,
      providerName: 'slack',
      category: [IntegrationCategory.communication],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: IntegrationCategory.values.length,
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _handleOAuthCallback();
    });
  }

  void _handleOAuthCallback() {
    final uri = Uri.base;
    final connected = uri.queryParameters['connected'];
    if (connected != null && connected.isNotEmpty) {
      context.read<IntegrationsProvider>().fetchIntegrations(force: true);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<IntegrationItem> _filterByCategory(IntegrationCategory category) {
    // Primeiro filtra por categoria
    final byCategory = category == IntegrationCategory.all
        ? _integrations
        : _integrations.where((i) => i.category.contains(category)).toList();

    // Depois aplica o filtro de busca por título
    if (_searchQuery.trim().isEmpty) {
      return byCategory;
    }

    final query = _searchQuery.trim().toLowerCase();
    return byCategory
        .where((i) => i.title.toLowerCase().contains(query))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<IntegrationsProvider>();
    final auth = context.watch<AuthProvider>();
    final tier = auth.subscriptionTier ?? 'free';
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    // Mostrar snackbar se houver erro
    final error = provider.lastError;
    if (error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(error)));
          provider.clearError();
        }
      });
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1200),
        child: Column(
          children: [
            // Abas de categoria
            Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  bottom: BorderSide(
                    color: colorScheme.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                labelColor: colorScheme.primary,
                tabAlignment: TabAlignment.start,
                unselectedLabelColor: colorScheme.onSurface.withValues(
                  alpha: 0.5,
                ),
                indicatorColor: colorScheme.primary,
                indicatorWeight: 2,
                labelStyle: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                tabs: IntegrationCategory.values
                    .map((c) => Tab(text: c.getLabel(context)))
                    .toList(),
              ),
            ),
            // Caixa de pesquisa
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: l10n.integrationsSearchHint,
                  hintStyle: GoogleFonts.inter(
                    fontSize: 13,
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    size: 20,
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                  ),
                  filled: true,
                  fillColor: colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 0,
                    vertical: 0,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.onSurface.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: colorScheme.primary.withValues(alpha: 0.6),
                      width: 1.4,
                    ),
                  ),
                ),
              ),
            ),
            // Conteúdo das abas
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: IntegrationCategory.values.map((category) {
                  final items = _filterByCategory(category);
                  return _buildGrid(context, items, provider, tier);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(
    BuildContext context,
    List<IntegrationItem> items,
    IntegrationsProvider provider,
    String userTier,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Dynamic column count based on width
        int crossAxisCount = 2;
        if (constraints.maxWidth > 900) {
          crossAxisCount = 4;
        } else if (constraints.maxWidth > 600) {
          crossAxisCount = 3;
        }

        return Skeletonizer(
          enabled: provider.isLoading && provider.connectedProviders.isEmpty,
          child: RefreshIndicator(
            onRefresh: () async {
              await provider.fetchIntegrations();
            },
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                childAspectRatio: 0.72,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return _buildCard(
                  context,
                  item.title,
                  item.logoId,
                  item.providerName,
                  provider,
                  userTier,
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard(
    BuildContext context,
    String title,
    LogoId logoId,
    String providerName,
    IntegrationsProvider provider,
    String userTier,
  ) {
    final bool connected = provider.isConnected(providerName);
    final isAllowed = _isIntegrationAllowed(providerName, userTier);
    final requiredTier = _getRequiredTier(providerName);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    return InkWell(
      onTap: !isAllowed
          ? () {
              UpgradeModal.show(context, "Integração $title", requiredTier);
            }
          : () {
              if (kIsWeb) {
                showDialog(
                  context: context,
                  builder: (context) => Dialog(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 500),
                      child: IntegrationDetailsScreen(
                        title: title,
                        logoId: logoId,
                        providerName: providerName,
                        isModal: true,
                      ),
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => IntegrationDetailsScreen(
                      title: title,
                      logoId: logoId,
                      providerName: providerName,
                    ),
                  ),
                );
              }
            },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: colorScheme.onSurface.withValues(alpha: 0.05),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: connected
                    ? Colors.white
                    : (isAllowed
                          ? Colors.white.withValues(alpha: 0.05)
                          : Colors.white.withValues(alpha: 0.02)),
                shape: BoxShape.circle,
              ),
              child: Logo(
                logoId: logoId,
                size: 40,
                onErrorIcon: Icon(
                  _getIntegrationIcon(title),
                  color: connected
                      ? colorScheme.primary
                      : (isAllowed
                            ? colorScheme.onSurface.withValues(alpha: 0.5)
                            : colorScheme.onSurface.withValues(alpha: 0.2)),
                  size: 40,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isAllowed
                    ? colorScheme.onSecondaryContainer
                    : colorScheme.onSecondaryContainer.withValues(alpha: 0.4),
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              connected
                  ? l10n.integrationsConnected
                  : (isAllowed ? l10n.integrationsDisconnected : l10n.integrationsBlocked),
              style: GoogleFonts.inter(
                fontSize: 11,
                color: connected
                    ? Colors.green[400]
                    : (isAllowed ? Colors.grey[500] : Colors.red[300]),
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: provider.isBusy(providerName)
                    ? null
                    : (!isAllowed
                          ? () => UpgradeModal.show(
                                context,
                                "Integração $title",
                                _getRequiredTier(providerName),
                              )
                          : () {
                              provider.toggleConnection(providerName);
                            }),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: connected ? Colors.red[600]! : colorScheme.primary,
                  ),
                  foregroundColor: connected
                      ? Colors.white
                      : colorScheme.primary,
                  backgroundColor: connected
                      ? Colors.red[600]
                      : Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: provider.isBusy(providerName)
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            connected ? Icons.link_off : Icons.link,
                            color: connected
                                ? Colors.white
                                : colorScheme.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            connected ? l10n.integrationsDisconnect : l10n.integrationsConnect,
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIntegrationIcon(String title) {
    if (title.contains("Calendar")) return Icons.calendar_today;
    if (title.contains("Gmail")) return Icons.email_outlined;
    if (title.contains("Notion")) return Icons.description_outlined;
    if (title.contains("Slack")) return Icons.chat_bubble_outline;
    return Icons.link;
  }

  bool _isIntegrationAllowed(String providerName, String userTier) {
    if (userTier == 'free') return false;
    if (userTier == 'max') return true;
    if (userTier == 'pro') {
      // Pro allows almost everything except custom API modules
      return true;
    }
    // Basic allowed? The user didn't specify for basic, but usually basic should have some.
    // Based on plans.md/project-context.md, basic has limits but allows them.
    return true; 
  }

  String _getRequiredTier(String providerName) {
    final proRequired = ["whatsapp", "slack", "telegram"];
    if (proRequired.contains(providerName)) return "pro";
    return "free";
  }
}
