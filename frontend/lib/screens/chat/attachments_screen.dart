import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:pdfrx/pdfrx.dart';

import '../../data/storage_repository.dart';

class AttachmentsScreen extends StatefulWidget {
  const AttachmentsScreen({super.key});

  @override
  State<AttachmentsScreen> createState() => _AttachmentsScreenState();
}

class _AttachmentsScreenState extends State<AttachmentsScreen> {
  final StorageRepository _repository = StorageRepository();
  late Future<List<Map<String, dynamic>>> _files;
  String? _openingId;

  @override
  void initState() {
    super.initState();
    _files = _repository.listAttachments();
  }

  Future<void> _reload() async {
    setState(() => _files = _repository.listAttachments());
    await _files;
  }

  Future<void> _openFile(Map<String, dynamic> file) async {
    final id = file['id'] as String;
    final mimeType = file['content_type'] as String? ?? '';
    final url = file['url'] as String? ?? '';
    if (mimeType == 'application/pdf') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => PdfPreviewScreen(
            name: file['name'] as String? ?? 'Documento PDF',
            url: url,
          ),
        ),
      );
      return;
    }
    if (mimeType ==
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document') {
      setState(() => _openingId = id);
      try {
        final preview = await _repository.previewDocx(id);
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DocxPreviewScreen(
              name: preview['name'] as String? ?? 'Documento DOCX',
              text: preview['text'] as String? ?? '',
            ),
          ),
        );
      } catch (erro) {
        if (mounted) _showError(erro);
      } finally {
        if (mounted) setState(() => _openingId = null);
      }
      return;
    }
    if (url.isNotEmpty) {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => ImagePreviewScreen(
            name: file['name'] as String? ?? 'Imagem',
            url: url,
          ),
        ),
      );
    }
  }

  Future<void> _deleteFile(Map<String, dynamic> file) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir arquivo?'),
        content: Text('“${file['name']}” será removido permanentemente.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _repository.deleteAttachment(file['id'] as String);
      await _reload();
    } catch (erro) {
      if (mounted) _showError(erro);
    }
  }

  void _showError(Object erro) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(erro.toString().replaceFirst('Exception: ', '')),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Meus arquivos')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _files,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return _MessageState(
              icon: Icons.cloud_off_outlined,
              message: snapshot.error.toString().replaceFirst(
                'Exception: ',
                '',
              ),
              action: TextButton.icon(
                onPressed: _reload,
                icon: const Icon(Icons.refresh),
                label: const Text('Tentar novamente'),
              ),
            );
          }
          final files = snapshot.data ?? const [];
          if (files.isEmpty) {
            return const _MessageState(
              icon: Icons.folder_open_outlined,
              message: 'Seus documentos e imagens enviados aparecerão aqui.',
            );
          }
          return RefreshIndicator(
            onRefresh: _reload,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text(
                  '${files.length} arquivo(s) recente(s)',
                  style: theme.textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                ...files.map(
                  (file) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      minLeadingWidth: 44,
                      leading: _FileThumbnail(file: file),
                      title: Text(
                        file['name'] as String? ?? 'Arquivo',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text(_fileDetails(file)),
                      onTap: _openingId == file['id']
                          ? null
                          : () => _openFile(file),
                      trailing: PopupMenuButton<String>(
                        tooltip: 'Ações do arquivo',
                        onSelected: (value) {
                          if (value == 'delete') _deleteFile(file);
                        },
                        itemBuilder: (context) => const [
                          PopupMenuItem(
                            value: 'delete',
                            child: ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: Icon(Icons.delete_outline),
                              title: Text('Excluir'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  String _fileDetails(Map<String, dynamic> file) {
    final size = (file['size_bytes'] as num?)?.toInt() ?? 0;
    final formattedSize = size < 1024 * 1024
        ? '${(size / 1024).ceil()} KB'
        : '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
    final mimeType = file['content_type'] as String? ?? '';
    final type = switch (mimeType) {
      'application/pdf' => 'PDF',
      'application/vnd.openxmlformats-officedocument.wordprocessingml.document' =>
        'DOCX',
      _ => 'Imagem',
    };
    return '$type · $formattedSize';
  }
}

class _FileThumbnail extends StatelessWidget {
  final Map<String, dynamic> file;

  const _FileThumbnail({required this.file});

  @override
  Widget build(BuildContext context) {
    final mimeType = file['content_type'] as String? ?? '';
    if (mimeType.startsWith('image/')) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: file['url'] as String? ?? '',
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          errorWidget: (context, url, error) =>
              const Icon(Icons.broken_image_outlined),
        ),
      );
    }
    return Icon(
      mimeType == 'application/pdf'
          ? Icons.picture_as_pdf_outlined
          : Icons.description_outlined,
      size: 30,
      color: Theme.of(context).colorScheme.primary,
    );
  }
}

class PdfPreviewScreen extends StatelessWidget {
  final String name;
  final String url;

  const PdfPreviewScreen({super.key, required this.name, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: PdfViewer.uri(Uri.parse(url)),
    );
  }
}

class DocxPreviewScreen extends StatelessWidget {
  final String name;
  final String text;

  const DocxPreviewScreen({super.key, required this.name, required this.text});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: text.trim().isEmpty
          ? const _MessageState(
              icon: Icons.description_outlined,
              message: 'Este documento não contém texto para pré-visualizar.',
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: SelectableText(
                text,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.6),
              ),
            ),
    );
  }
}

class ImagePreviewScreen extends StatelessWidget {
  final String name;
  final String url;

  const ImagePreviewScreen({super.key, required this.name, required this.url});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: InteractiveViewer(
          child: CachedNetworkImage(
            imageUrl: url,
            placeholder: (context, url) =>
                const Center(child: CircularProgressIndicator()),
            errorWidget: (context, url, error) =>
                const Icon(Icons.broken_image_outlined, size: 48),
          ),
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;

  const _MessageState({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 44, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}
