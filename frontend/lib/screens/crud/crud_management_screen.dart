import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../data/crud_api_service.dart';
import '../../components/catas_page.dart';
import '../../core/design_tokens.dart';

class _EntityConfig {
  final String nome;
  final String rota;
  final IconData icone;
  final List<_FieldConfig> campos;
  final String campoExibicao;

  const _EntityConfig({
    required this.nome,
    required this.rota,
    required this.icone,
    required this.campos,
    required this.campoExibicao,
  });
}

class _FieldConfig {
  final String chave;
  final String rotulo;
  final bool obrigatorio;
  final TextInputType tipo;

  const _FieldConfig({
    required this.chave,
    required this.rotulo,
    this.obrigatorio = false,
    this.tipo = TextInputType.text,
  });
}

const _entities = <_EntityConfig>[
  _EntityConfig(
    nome: 'Profiles',
    rota: 'profiles',
    icone: Icons.person,
    campoExibicao: 'email',
    campos: [
      _FieldConfig(
        chave: 'email',
        rotulo: 'Email',
        obrigatorio: true,
        tipo: TextInputType.emailAddress,
      ),
      _FieldConfig(chave: 'subscription_tier', rotulo: 'Plano'),
      _FieldConfig(chave: 'language', rotulo: 'Idioma'),
      _FieldConfig(chave: 'industry', rotulo: 'Segmento'),
    ],
  ),
  _EntityConfig(
    nome: 'Chat Sessions',
    rota: 'chat-sessions',
    icone: Icons.chat,
    campoExibicao: 'title',
    campos: [
      _FieldConfig(chave: 'user_id', rotulo: 'User ID', obrigatorio: true),
      _FieldConfig(chave: 'title', rotulo: 'Título'),
    ],
  ),
  _EntityConfig(
    nome: 'Messages',
    rota: 'messages',
    icone: Icons.message,
    campoExibicao: 'content',
    campos: [
      _FieldConfig(
        chave: 'session_id',
        rotulo: 'Session ID',
        obrigatorio: true,
      ),
      _FieldConfig(
        chave: 'role',
        rotulo: 'Role (user/assistant/system)',
        obrigatorio: true,
      ),
      _FieldConfig(chave: 'content', rotulo: 'Conteúdo'),
    ],
  ),
  _EntityConfig(
    nome: 'Automations',
    rota: 'automations',
    icone: Icons.auto_awesome,
    campoExibicao: 'name',
    campos: [
      _FieldConfig(chave: 'name', rotulo: 'Nome'),
      _FieldConfig(chave: 'trigger', rotulo: 'Trigger'),
      _FieldConfig(chave: 'status', rotulo: 'Status (active/paused)'),
    ],
  ),
  _EntityConfig(
    nome: 'Automation Runs',
    rota: 'automation-runs',
    icone: Icons.play_circle,
    campoExibicao: 'input_summary',
    campos: [
      _FieldConfig(chave: 'automation_id', rotulo: 'Automation ID'),
      _FieldConfig(chave: 'status', rotulo: 'Status'),
      _FieldConfig(chave: 'run_type', rotulo: 'Tipo'),
    ],
  ),
  _EntityConfig(
    nome: 'Step Logs',
    rota: 'automation-step-logs',
    icone: Icons.list_alt,
    campoExibicao: 'step_name',
    campos: [
      _FieldConfig(chave: 'run_id', rotulo: 'Run ID', obrigatorio: true),
      _FieldConfig(
        chave: 'step_index',
        rotulo: 'Índice',
        tipo: TextInputType.number,
      ),
      _FieldConfig(chave: 'status', rotulo: 'Status'),
    ],
  ),
  _EntityConfig(
    nome: 'Integrations',
    rota: 'integrations',
    icone: Icons.device_hub,
    campoExibicao: 'provider',
    campos: [
      _FieldConfig(chave: 'provider', rotulo: 'Provedor', obrigatorio: true),
      _FieldConfig(chave: 'access_token', rotulo: 'Access Token'),
    ],
  ),
  _EntityConfig(
    nome: 'Feedbacks',
    rota: 'message-feedback',
    icone: Icons.feedback,
    campoExibicao: 'reason',
    campos: [
      _FieldConfig(
        chave: 'message_id',
        rotulo: 'Message ID',
        obrigatorio: true,
      ),
      _FieldConfig(chave: 'is_liked', rotulo: 'Gostou? (true/false)'),
      _FieldConfig(chave: 'reason', rotulo: 'Motivo'),
    ],
  ),
];

class CrudManagementScreen extends StatefulWidget {
  const CrudManagementScreen({super.key});

  @override
  State<CrudManagementScreen> createState() => _CrudManagementScreenState();
}

class _CrudManagementScreenState extends State<CrudManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _entities.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Gerenciar Dados',
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelStyle: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: _entities.map((e) => Tab(text: e.nome)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _entities.map((e) => _EntityCrudView(config: e)).toList(),
      ),
    );
  }
}

class _EntityCrudView extends StatefulWidget {
  final _EntityConfig config;
  const _EntityCrudView({required this.config});

  @override
  State<_EntityCrudView> createState() => _EntityCrudViewState();
}

class _EntityCrudViewState extends State<_EntityCrudView> {
  late CrudApiService _service;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _service = CrudApiService(widget.config.rota);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _service.listar();
      if (mounted) {
        setState(() {
          _items = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  Future<void> _criar() => _mostrarFormulario(null);

  Future<void> _editar(Map<String, dynamic> item) => _mostrarFormulario(item);

  Future<void> _mostrarFormulario(Map<String, dynamic>? item) async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) =>
          _CrudFormDialog(config: widget.config, dadosIniciais: item),
    );
    if (result != null) {
      try {
        if (item == null) {
          await _service.criar(result);
        } else {
          await _service.atualizar(item['id'], result);
        }
        _carregar();
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Future<void> _deletar(Map<String, dynamic> item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar exclusão'),
        content: Text(
          'Deletar "${item[widget.config.campoExibicao] ?? item['id']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: context.catasTokens.danger,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Deletar'),
          ),
        ],
      ),
    );
    if (confirm == true) {
      try {
        await _service.deletar(item['id']);
        _carregar();
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Deletado com sucesso')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: $e'), backgroundColor: Colors.red),
          );
        }
      }
    }
  }

  Widget _buildItemTile(Map<String, dynamic> item) {
    final display =
        item[widget.config.campoExibicao]?.toString() ??
        item['id']?.toString() ??
        '---';
    final subtitle = item.entries
        .where(
          (e) =>
              e.key != 'id' &&
              e.key != widget.config.campoExibicao &&
              e.value != null,
        )
        .take(3)
        .map(
          (e) =>
              '${e.key}: ${e.value.toString().length > 40 ? '${e.value.toString().substring(0, 40)}...' : e.value}',
        )
        .join(', ');

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      color: context.catasTokens.surfaceRaised,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(context.catasTokens.radiusMedium),
        side: BorderSide(color: context.catasTokens.borderSubtle),
      ),
      child: ListTile(
        title: Text(
          display,
          style: GoogleFonts.inter(fontWeight: FontWeight.w600),
        ),
        subtitle: subtitle.isNotEmpty
            ? Text(subtitle, maxLines: 2, overflow: TextOverflow.ellipsis)
            : null,
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 20),
              onPressed: () => _editar(item),
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline,
                size: 20,
                color: context.catasTokens.danger,
              ),
              onPressed: () => _deletar(item),
            ),
          ],
        ),
        onTap: () => _editar(item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return CatasEmptyState(
        icon: Icons.error_outline_rounded,
        title: 'Erro ao carregar dados',
        message: _error!,
        action: FilledButton.icon(
          onPressed: _carregar,
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Tentar novamente'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButton: FloatingActionButton(
        heroTag: widget.config.rota,
        mini: true,
        onPressed: _criar,
        child: const Icon(Icons.add),
      ),
      body: _items.isEmpty
          ? CatasEmptyState(
              icon: widget.config.icone,
              title: 'Nenhum registro encontrado',
              message:
                  'Adicione o primeiro item para começar a organizar estes dados.',
              action: FilledButton.icon(
                onPressed: _criar,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Adicionar'),
              ),
            )
          : RefreshIndicator(
              onRefresh: _carregar,
              child: ListView.builder(
                padding: const EdgeInsets.only(top: 8, bottom: 80),
                itemCount: _items.length,
                itemBuilder: (_, i) => _buildItemTile(_items[i]),
              ),
            ),
    );
  }
}

class _CrudFormDialog extends StatefulWidget {
  final _EntityConfig config;
  final Map<String, dynamic>? dadosIniciais;

  const _CrudFormDialog({required this.config, this.dadosIniciais});

  @override
  State<_CrudFormDialog> createState() => _CrudFormDialogState();
}

class _CrudFormDialogState extends State<_CrudFormDialog> {
  late Map<String, TextEditingController> _controllers;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _controllers = {};
    for (final campo in widget.config.campos) {
      final valor = widget.dadosIniciais?[campo.chave]?.toString() ?? '';
      _controllers[campo.chave] = TextEditingController(text: valor);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _salvar() {
    if (!_formKey.currentState!.validate()) return;
    final dados = <String, dynamic>{};
    for (final campo in widget.config.campos) {
      final valor = _controllers[campo.chave]!.text.trim();
      if (valor.isNotEmpty) {
        if (campo.tipo == TextInputType.number) {
          dados[campo.chave] = int.tryParse(valor) ?? valor;
        } else if (valor == 'true' || valor == 'false') {
          dados[campo.chave] = valor == 'true';
        } else {
          dados[campo.chave] = valor;
        }
      }
    }
    Navigator.pop(context, dados);
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.dadosIniciais != null;
    return AlertDialog(
      title: Text(
        isEdit ? 'Editar ${widget.config.nome}' : 'Novo ${widget.config.nome}',
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: widget.config.campos.map((campo) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: TextFormField(
                  controller: _controllers[campo.chave],
                  keyboardType: campo.tipo,
                  decoration: InputDecoration(
                    labelText: campo.rotulo,
                    border: const OutlineInputBorder(),
                  ),
                  validator: campo.obrigatorio
                      ? (v) => (v == null || v.trim().isEmpty)
                            ? 'Campo obrigatório'
                            : null
                      : null,
                ),
              );
            }).toList(),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _salvar,
          child: Text(isEdit ? 'Atualizar' : 'Criar'),
        ),
      ],
    );
  }
}
