import 'package:catas/providers/auth_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../core/router.dart';
import '../../l10n/app_localizations.dart';
import '../../components/brand_logo.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _page = 0;

  String? _selectedIndustry;
  final List<String> _selectedPains = [];
  bool _isCustomPain = false;
  final TextEditingController _customPainController = TextEditingController();

  final List<String> _selectedTools = [];
  int _setupStep = 0;

  final List<_IndustryData> _industries = [
    _IndustryData(
      key: 'real_estate',
      label: 'Imobiliário',
      icon: Icons.home_work,
      pains: [
        'Leads do Zap/VivaReal se perdem',
        'Esqueço de dar follow-up',
        'Muitos leads, pouco tempo'
      ],
    ),
    _IndustryData(
      key: 'marketing',
      label: 'Marketing Digital',
      icon: Icons.trending_up,
      pains: [
        'Relatórios manuais toda semana',
        'Dados espalhados in planilhas',
        'Esqueço de enviar report ao cliente'
      ],
    ),
    _IndustryData(
      key: 'legal',
      label: 'Advocacia',
      icon: Icons.gavel,
      pains: [
        'Resumo de processos demora horas',
        'Prazos processuais passam batendo',
        'Muitos PDFs para organizar'
      ],
    ),
    _IndustryData(
      key: 'other',
      label: 'Outro',
      icon: Icons.more_horiz,
      pains: [
        'Processos manuais repetitivos',
        'Falta de integração entre ferramentas',
        'Dificuldade em organizar dados'
      ],
    ),
  ];

  final List<_ToolData> _tools = [
    _ToolData(
      key: 'google_sheets',
      label: 'Google Sheets',
      icon: Icons.table_chart,
      color: Colors.green,
      logoId: LogoId.googleSheets,
    ),
    _ToolData(
      key: 'google_calendar',
      label: 'Google Calendar',
      icon: Icons.calendar_month,
      color: Colors.blue,
      logoId: LogoId.googleCalendar,
    ),
    _ToolData(
      key: 'google_drive',
      label: 'Google Drive',
      icon: Icons.add_to_drive,
      color: Colors.amber,
      logoId: LogoId.googleDrive,
    ),
    _ToolData(
      key: 'gmail',
      label: 'Gmail',
      icon: Icons.mail,
      color: Colors.red,
      logoId: LogoId.googleGmail,
    ),
    _ToolData(
      key: 'whatsapp',
      label: 'WhatsApp',
      icon: Icons.chat,
      color: Colors.teal,
    ),
    _ToolData(
      key: 'notion',
      label: 'Notion',
      icon: Icons.book,
      color: Colors.grey,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _customPainController.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final industry = _selectedIndustry ?? 'other';
    final role = _selectedPains.isNotEmpty ? _selectedPains.join(', ') : 'Usuário';

    debugPrint('🏁 [_finish] Iniciando finalização do onboarding...');
    
    final authProvider = context.read<AuthProvider>();
    await authProvider.completeOnboarding(
      industry: industry,
      role: role,
      tools: _selectedTools,
      scheduleAhaDemo: true,
    );
    
    debugPrint('🏁 [_finish] completeOnboarding finalizado. Verificando estado...');
    debugPrint('🏁 [_finish] onboardingCompleted=${authProvider.onboardingCompleted}');
    debugPrint('🏁 [_finish] profile.industry=${authProvider.profile?.industry}');
    
    // Aguarda um frame para garantir que o GoRouter processou a notificação
    await Future.delayed(const Duration(milliseconds: 100));
    
    if (!mounted) return;
    debugPrint('🚀 [_finish] Navegando para o Chat...');
    context.go(AppRoutes.chat);
  }

  void _nextPage() {
    debugPrint('➡️ _nextPage: page=$_page, setupStep=$_setupStep');
    if (_page < 3) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
      if (_page == 2) {
        debugPrint('🚀 Iniciando simulação de setup automaticamente');
        _startSetupSimulation();
      }
    } else {
      if (_setupStep == 3) {
        debugPrint('🏁 Finalizando onboarding via _nextPage');
        _finish();
      } else {
        debugPrint('⏳ Aguardando checklist... step=$_setupStep');
      }
    }
  }

  void _startSetupSimulation() {
    debugPrint('🛠️ [_startSetupSimulation] Iniciando timers...');
    setState(() {
      _setupStep = 0;
    });

    // Passo 0 -> 1 (Imediato ou quase)
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        debugPrint('✅ Step 1 completo');
        setState(() => _setupStep = 1);
      }
    });

    // Passo 1 -> 2
    Future.delayed(const Duration(milliseconds: 2000), () {
      if (mounted) {
        debugPrint('✅ Step 2 completo');
        setState(() => _setupStep = 2);
      }
    });

    // Passo 2 -> 3 (Final)
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        debugPrint('✅ Step 3 completo (FINAL)');
        setState(() => _setupStep = 3);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  if (_page > 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOutCubic,
                        );
                      },
                    ),
                  const Spacer(),
                  // Botão Pular removido - onboarding é obrigatório
                ],
              ),
            ),
            LinearProgressIndicator(
              value: (_page + 1) / 4,
              backgroundColor: colorScheme.surfaceVariant,
              minHeight: 4,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _page = i),
                children: [
                  _buildIndustryPage(),
                  _buildPainPage(),
                  _buildToolsPage(),
                  _buildSetupPage(),
                ],
              ),
            ),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: FilledButton(
                        onPressed: _canGoNext() ? _nextPage : null,
                        child: Text(
                          _page < 3
                              ? 'Continuar'
                              : (_setupStep < 3 ? 'Processando...' : 'Começar Agora'),
                          style: GoogleFonts.inter(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  bool _canGoNext() {
    if (_page == 0) return _selectedIndustry != null;
    if (_page == 1) return _selectedPains.isNotEmpty || _isCustomPain;
    if (_page == 2) return true; // Seleção de ferramentas opcional
    if (_page == 3) return _setupStep == 3;
    return true;
  }

  Widget _buildIndustryPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? size.width * 0.15 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Qual é o seu nicho?',
            style: GoogleFonts.outfit(
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione sua área para personalizar suas automações:',
            style: GoogleFonts.inter(
              fontSize: isWeb ? 16 : 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWeb ? 4 : 2,
                crossAxisSpacing: isWeb ? 12 : 12,
                mainAxisSpacing: isWeb ? 12 : 12,
                childAspectRatio: isWeb ? 1.2 : 1.0,
              ),
              itemCount: _industries.length,
              itemBuilder: (context, index) {
                final industry = _industries[index];
                final isSelected = _selectedIndustry == industry.key;
                return InkWell(
                  onTap: () {
                    setState(() {
                      _selectedIndustry = industry.key;
                      _selectedPains.clear();
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primaryContainer : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          industry.icon,
                          size: isWeb ? 36 : 32,
                          color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          industry.label,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: isWeb ? 15 : 14,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPainPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 900;
    final currentIndustry = _industries.firstWhere((i) => i.key == _selectedIndustry, orElse: () => _industries.last);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? size.width * 0.15 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quais são suas dores?',
            style: GoogleFonts.outfit(
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Selecione o que mais te atrapalha no dia a dia:',
            style: GoogleFonts.inter(
              fontSize: isWeb ? 16 : 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: isWeb ? 600 : double.infinity),
                child: ListView(
                  children: [
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: currentIndustry.pains.map((pain) {
                        final isSelected = _selectedPains.contains(pain);
                        return ChoiceChip(
                          label: Text(pain),
                          selected: isSelected,
                          onSelected: (val) {
                            setState(() {
                              if (val) {
                                _selectedPains.add(pain);
                              } else {
                                _selectedPains.remove(pain);
                              }
                            });
                          },
                          labelStyle: GoogleFonts.inter(
                            fontSize: isWeb ? 14 : 13,
                            color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          backgroundColor: colorScheme.surface,
                          selectedColor: colorScheme.primaryContainer,
                          checkmarkColor: colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                            side: BorderSide(
                              color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    if (!_isCustomPain)
                      TextButton.icon(
                        onPressed: () => setState(() => _isCustomPain = true),
                        icon: const Icon(Icons.add),
                        label: const Text('Adicionar outra dor'),
                      )
                    else
                      TextField(
                        controller: _customPainController,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: 'Descreva sua maior dor...',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            setState(() {
                              _selectedPains.add(val.trim());
                              _customPainController.clear();
                              _isCustomPain = false;
                            });
                          }
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToolsPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 900;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? size.width * 0.15 : 24,
        vertical: 24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.onboardingSelectToolsTitle,
            style: GoogleFonts.outfit(
              fontSize: isWeb ? 28 : 24,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            l10n.onboardingSelectToolsSubtitle,
            style: GoogleFonts.inter(
              fontSize: isWeb ? 16 : 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWeb ? 3 : 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isWeb ? 1.4 : 1.1,
              ),
              itemCount: _tools.length,
              itemBuilder: (context, index) {
                final tool = _tools[index];
                final isSelected = _selectedTools.contains(tool.key);
                return InkWell(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedTools.remove(tool.key);
                      } else {
                        _selectedTools.add(tool.key);
                      }
                    });
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.4) : colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? colorScheme.primary : colorScheme.outlineVariant,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: colorScheme.primary.withOpacity(0.15),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (tool.logoId != null)
                                Logo(
                                  logoId: tool.logoId!,
                                  size: isWeb ? 36 : 32,
                                  onErrorIcon: Icon(tool.icon, size: isWeb ? 36 : 32, color: isSelected ? colorScheme.primary : tool.color),
                                )
                              else
                                Icon(
                                  tool.icon,
                                  size: isWeb ? 36 : 32,
                                  color: isSelected ? colorScheme.primary : tool.color,
                                ),
                              const SizedBox(height: 12),
                              Text(
                                tool.label,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: isWeb ? 15 : 14,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? colorScheme.onPrimaryContainer : colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Icon(
                              Icons.check_circle,
                              color: colorScheme.primary,
                              size: 20,
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSetupPage() {
    final colorScheme = Theme.of(context).colorScheme;
    final size = MediaQuery.of(context).size;
    final isWeb = kIsWeb || size.width > 900;
    final industryLabel = _industries.firstWhere((i) => i.key == _selectedIndustry, orElse: () => _industries.last).label;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isWeb ? size.width * 0.2 : 24,
        vertical: 24,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: isWeb ? 80 : 100,
            height: isWeb ? 80 : 100,
            child: const CircularProgressIndicator(strokeWidth: 6),
          ),
          const SizedBox(height: 40),
          Text(
            'Personalizando seu CATAS...',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: isWeb ? 24 : 28,
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Preparando automações para $industryLabel.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: isWeb ? 16 : 14,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: BoxConstraints(maxWidth: isWeb ? 400 : double.infinity),
            child: Column(
              children: [
                _buildLoadingStep('Aprendendo sobre sua rotina...', _setupStep >= 1),
                _buildLoadingStep('Conectando módulos...', _setupStep >= 2),
                _buildLoadingStep('Preparando o chat...', _setupStep >= 3),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingStep(String label, bool completed) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(
            completed ? Icons.check_circle : Icons.radio_button_unchecked,
            color: completed ? colorScheme.primary : colorScheme.outline,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: completed ? colorScheme.onSurface : colorScheme.onSurfaceVariant,
              fontWeight: completed ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

class _IndustryData {
  final String key;
  final String label;
  final IconData icon;
  final List<String> pains;

  _IndustryData({
    required this.key,
    required this.label,
    required this.icon,
    required this.pains,
  });
}

class _ToolData {
  final String key;
  final String label;
  final IconData icon;
  final Color color;
  final LogoId? logoId;

  _ToolData({
    required this.key,
    required this.label,
    required this.icon,
    required this.color,
    this.logoId,
  });
}

