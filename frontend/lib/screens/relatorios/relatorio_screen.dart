import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/relatorio_provider.dart';
import '../../components/report_export_menu.dart';

/// Tela de Relatórios — consome os endpoints de relatório/busca da API
/// (funcionalidades além do CRUD básico implementadas via procedures).
class RelatorioScreen extends StatefulWidget {
  const RelatorioScreen({super.key});

  @override
  State<RelatorioScreen> createState() => _RelatorioScreenState();
}

class _RelatorioScreenState extends State<RelatorioScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final TextEditingController _buscaController = TextEditingController();
  final TextEditingController _buscaRunsController = TextEditingController();
  String? _statusFiltro;
  String _ordem = 'created_at';

  static const _statusOpcoes = [
    ('all', 'Todos'),
    ('completed', 'Concluído'),
    ('failed', 'Falhou'),
    ('running', 'Executando'),
    ('pending', 'Pendente'),
    ('paused', 'Pausado'),
    ('canceled', 'Cancelado'),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _carregarTudo());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _buscaController.dispose();
    _buscaRunsController.dispose();
    super.dispose();
  }

  Future<void> _carregarTudo() async {
    final userId = context.read<AuthProvider>().userId;
    if (userId == null) return;
    final rel = context.read<RelatorioProvider>();
    await rel.carregarDashboard(userId);
    await rel.carregarRelatorioChat(userId);
    await rel.buscarRuns(userId, status: _statusFiltro, busca: null);
  }

  String? get _buscaFiltro {
    final texto = _buscaRunsController.text.trim();
    return texto.length >= 2 ? texto : null;
  }

  void _reloadRuns(RelatorioProvider rel, String? userId) {
    if (userId == null) return;
    rel.buscarRuns(
      userId,
      status: _statusFiltro,
      busca: _buscaFiltro,
      ordem: _ordem,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final userId = auth.userId;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1100),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: TabBar(
                controller: _tabController,
                labelColor: theme.colorScheme.primary,
                unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                indicatorColor: theme.colorScheme.primary,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: const [
                  Tab(text: 'Automações'),
                  Tab(text: 'Conversas'),
                  Tab(text: 'Busca de Mensagens'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildAbaAutomacoes(userId),
                  const _AbaConversas(),
                  _buildAbaBusca(userId),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────── ABA: Automações ───────────────────────────
  Widget _buildAbaAutomacoes(String? userId) {
    final rel = context.watch<RelatorioProvider>();

    return RefreshIndicator(
      onRefresh: () async => _reloadRuns(rel, userId),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (userId != null)
            Align(
              alignment: Alignment.centerRight,
              child: ReportExportMenu(
                userId: userId,
                tipo: 'automacoes',
                filtros: {
                  if (_statusFiltro != null) 'status': _statusFiltro!,
                  if (_buscaFiltro != null) 'busca': _buscaFiltro!,
                  'ordem': _ordem,
                },
              ),
            ),
          _buildFiltrosRuns(rel, userId),
          const SizedBox(height: 12),
          if (rel.carregandoRuns)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (rel.erro != null)
            _buildErro(rel.erro!)
          else if (rel.runsFiltrados.isEmpty)
            _buildVazio('Nenhuma execução encontrada para os filtros.')
          else ...[
            Text(
              'Total: ${rel.runsTotal} execução(ões)',
              style: GoogleFonts.inter(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...rel.runsFiltrados.map((run) => _RunFiltradoCard(run: run)),
            if (rel.temMaisRuns)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Center(
                  child: OutlinedButton(
                    onPressed: () {
                      if (userId != null) {
                        rel.buscarRuns(
                          userId,
                          status: _statusFiltro,
                          busca: _buscaFiltro,
                          carregarMais: true,
                        );
                      }
                    },
                    child: const Text('Carregar mais'),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildFiltrosRuns(RelatorioProvider rel, String? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _buscaRunsController,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) => _reloadRuns(rel, userId),
                decoration: InputDecoration(
                  hintText: 'Buscar por título/descrição...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  isDense: true,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              initialValue: _ordem,
              icon: const Icon(Icons.sort_rounded),
              tooltip: 'Ordenar por',
              onSelected: (value) {
                setState(() => _ordem = value);
                _reloadRuns(rel, userId);
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'created_at',
                  child: Text('Mais recentes'),
                ),
                PopupMenuItem(value: 'status', child: Text('Por status')),
                PopupMenuItem(value: 'started_at', child: Text('Por início')),
                PopupMenuItem(value: 'run_type', child: Text('Por tipo')),
              ],
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: _statusOpcoes.map((opt) {
            return FilterChip(
              label: Text(opt.$2, style: GoogleFonts.inter(fontSize: 12)),
              visualDensity: VisualDensity.compact,
              selected: opt.$1 == 'all'
                  ? _statusFiltro == null
                  : _statusFiltro == opt.$1,
              onSelected: (_) {
                setState(() {
                  _statusFiltro = opt.$1 == 'all' ? null : opt.$1;
                });
                _reloadRuns(rel, userId);
              },
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─────────────────────────── ABA: Busca ───────────────────────────
  Widget _buildAbaBusca(String? userId) {
    final rel = context.watch<RelatorioProvider>();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        TextField(
          controller: _buscaController,
          textInputAction: TextInputAction.search,
          onSubmitted: (value) {
            if (userId != null) rel.buscarMensagens(userId, value);
          },
          decoration: InputDecoration(
            hintText: 'Pesquisar mensagens (mín. 2 caracteres)...',
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (rel.carregandoBusca)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: CircularProgressIndicator(),
            ),
          )
        else if (rel.erro != null)
          _buildErro(rel.erro!)
        else if (rel.mensagens.isEmpty)
          _buildVazio('Digite um termo para buscar mensagens.')
        else ...[
          Text(
            '${rel.mensagensTotal} mensagem(ns) encontrada(s)',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          ...rel.mensagens.map((m) => _MensagemResultado(mensagem: m)),
        ],
      ],
    );
  }

  Widget _buildErro(String mensagem) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(
        child: Text(
          mensagem.replaceFirst('Exception: ', ''),
          style: GoogleFonts.inter(color: Theme.of(context).colorScheme.error),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildVazio(String texto) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── ABA: Conversas ───────────────────────────
class _AbaConversas extends StatelessWidget {
  const _AbaConversas();

  @override
  Widget build(BuildContext context) {
    final rel = context.watch<RelatorioProvider>();
    final theme = Theme.of(context);
    final chat = rel.chat;
    final userId = context.read<AuthProvider>().userId;

    return RefreshIndicator(
      onRefresh: () async {
        final userId = context.read<AuthProvider>().userId;
        if (userId != null) {
          await context.read<RelatorioProvider>().carregarRelatorioChat(userId);
        }
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (userId != null)
            Align(
              alignment: Alignment.centerRight,
              child: ReportExportMenu(userId: userId, tipo: 'chat'),
            ),
          if (rel.carregandoChat)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ),
            )
          else if (rel.erro != null)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: Text(
                  rel.erro!.replaceFirst('Exception: ', ''),
                  style: GoogleFonts.inter(color: theme.colorScheme.error),
                ),
              ),
            )
          else if (chat == null)
            const SizedBox.shrink()
          else ...[
            Row(
              children: [
                Expanded(
                  child: _MetricaCard(
                    titulo: 'Sessões',
                    valor: '${chat['total_sessoes'] ?? 0}',
                    icone: Icons.forum_outlined,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricaCard(
                    titulo: 'Mensagens',
                    valor: '${chat['total_mensagens'] ?? 0}',
                    icone: Icons.chat_bubble_outline,
                    color: Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _MetricaCard(
                    titulo: 'Sessões ativas (período)',
                    valor: '${chat['sessoes_ativas'] ?? 0}',
                    icone: Icons.bolt_outlined,
                    color: Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MetricaCard(
                    titulo: 'Feedback',
                    valor: _feedbackLabel(chat),
                    icone: Icons.thumb_up_outlined,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildRoles(theme, chat['mensagens_por_role']),
            const SizedBox(height: 24),
            _buildPorDia(theme, chat['mensagens_por_dia']),
          ],
        ],
      ),
    );
  }

  String _feedbackLabel(Map<String, dynamic> chat) {
    final fb = chat['feedback'];
    if (fb is Map) {
      return '${fb['likes'] ?? 0}👍 · ${fb['dislikes'] ?? 0}👎';
    }
    return '—';
  }

  Widget _buildRoles(ThemeData theme, dynamic porRole) {
    if (porRole is! Map || porRole.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mensagens por papel',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _papelItem('Usuário', '${porRole['user'] ?? 0}', Colors.blue),
              const SizedBox(width: 16),
              _papelItem(
                'Assistente',
                '${porRole['assistant'] ?? 0}',
                Colors.green,
              ),
              const SizedBox(width: 16),
              _papelItem('Sistema', '${porRole['system'] ?? 0}', Colors.orange),
            ],
          ),
        ],
      ),
    );
  }

  Widget _papelItem(String label, String valor, Color cor) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: cor,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          ' $valor',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildPorDia(ThemeData theme, dynamic porDia) {
    if (porDia is! List || porDia.isEmpty) {
      return Text(
        'Sem mensagens no período selecionado.',
        style: GoogleFonts.inter(color: theme.colorScheme.onSurfaceVariant),
      );
    }
    final total = porDia.fold<int>(
      0,
      (acc, d) =>
          acc +
          ((d['usuarios'] ?? 0) as num).toInt() +
          ((d['assistentes'] ?? 0) as num).toInt(),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mensagens por dia',
          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...porDia.take(14).map((d) {
          final usuarios = (d['usuarios'] ?? 0) as num;
          final assistentes = (d['assistentes'] ?? 0) as num;
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    '${d['dia']}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(child: _barra(theme, usuarios, total, Colors.blue)),
                const SizedBox(width: 4),
                Expanded(
                  child: _barra(theme, assistentes, total, Colors.green),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  child: Text(
                    '${usuarios.toInt()}/${assistentes.toInt()}',
                    textAlign: TextAlign.right,
                    style: GoogleFonts.inter(fontSize: 11),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _barra(ThemeData theme, num valor, num total, Color cor) {
    final frac = total > 0 ? valor.toDouble() / total.toDouble() : 0.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: LinearProgressIndicator(
        value: frac.clamp(0.0, 1.0),
        minHeight: 6,
        backgroundColor: theme.colorScheme.outline.withValues(alpha: 0.1),
        valueColor: AlwaysStoppedAnimation(cor),
      ),
    );
  }
}

class _MetricaCard extends StatelessWidget {
  final String titulo;
  final String valor;
  final IconData icone;
  final Color color;
  const _MetricaCard({
    required this.titulo,
    required this.valor,
    required this.icone,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(icone, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  valor,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────── CARD: run filtrado ───────────────────────────
class _RunFiltradoCard extends StatelessWidget {
  final Map<String, dynamic> run;
  const _RunFiltradoCard({required this.run});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final nome =
        run['automation_name'] as String? ??
        run['input_summary'] as String? ??
        'Automação sem título';
    final subtitulo = run['input_summary'] as String? ?? '';
    final status = run['status'] as String? ?? 'pending';
    final createdAt = run['created_at'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.route_outlined,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome.isEmpty ? 'Automação sem título' : nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitulo.isNotEmpty && subtitulo != nome)
                  Text(
                    subtitulo,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                Text(
                  _formatarData(createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _chipStatus(status),
        ],
      ),
    );
  }

  Widget _chipStatus(String status) {
    Color cor;
    switch (status) {
      case 'completed':
        cor = Colors.green;
      case 'failed':
        cor = Colors.red;
      case 'running':
        cor = Colors.blue;
      default:
        cor = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: cor.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 11, color: cor, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _formatarData(String iso) {
    if (iso.isEmpty || !iso.contains('-')) return iso;
    final data = iso.split('T').first;
    final parts = data.split('-');
    if (parts.length != 3) return iso;
    return '${parts[2]}/${parts[1]}/${parts[0]}';
  }
}

// ─────────────────────────── CARD: resultado de busca ───────────────────────
class _MensagemResultado extends StatelessWidget {
  final Map<String, dynamic> mensagem;
  const _MensagemResultado({required this.mensagem});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final conteudo = mensagem['content'] as String? ?? '';
    final titulo = mensagem['session_title'] as String? ?? 'Sessão';
    final role = mensagem['role'] as String? ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            role == 'user' ? Icons.person_outline : Icons.smart_toy_outlined,
            size: 18,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  conteudo,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
