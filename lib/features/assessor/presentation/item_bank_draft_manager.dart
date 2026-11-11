import 'dart:convert';
import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../../app/app_theme.dart';
import '../../assessment/data/bundled_item_catalog.dart';
import '../../assessment/data/item_bank_draft_store.dart';
import '../../assessment/domain/models/item_bank_draft.dart';

/// Local authoring workspace. Every edit remains a draft and is excluded from
/// the task preview and participant-release pipeline.
class ItemBankDraftManager extends StatefulWidget {
  const ItemBankDraftManager({super.key, required this.catalog, this.store});

  final BundledItemCatalog catalog;
  final ItemBankDraftStore? store;

  @override
  State<ItemBankDraftManager> createState() => _ItemBankDraftManagerState();
}

class _ItemBankDraftManagerState extends State<ItemBankDraftManager> {
  late final ItemBankDraftStore _store;
  late Future<List<ItemBankDraft>> _draftsFuture;
  final TextEditingController _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _store = widget.store ?? createItemBankDraftStore();
    _draftsFuture = _store.loadAll();
    _search.addListener(() {
      if (mounted) {
        setState(() => _query = _search.text.trim().toLowerCase());
      }
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _draftsFuture = _store.loadAll());
    await _draftsFuture;
  }

  Future<void> _downloadBackup() async {
    try {
      final drafts = await _store.loadAll();
      final payload = const JsonEncoder.withIndent('  ').convert(
        <String, Object?>{
          'schema_version': 1,
          'application': 'PadLab content drafts',
          'exported_at': DateTime.now().toUtc().toIso8601String(),
          'approved_for_gameplay': false,
          'items': drafts.map((draft) => draft.toJson()).toList(growable: false),
        },
      );
      await FileSaver.instance.saveAs(
        name: 'padalab-content-drafts-backup',
        bytes: Uint8List.fromList(utf8.encode(payload)),
        fileExtension: 'json',
        mimeType: MimeType.other,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Draft backup prepared. It contains no participant records.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft backup failed: $error'),
          backgroundColor: AppTheme.coral,
        ),
      );
    }
  }

  Future<void> _add(ItemBankDraftType type) async {
    final prefix = type == ItemBankDraftType.realWord ? 'WDRAFT' : 'NDRAFT';
    final id = '$prefix-${const Uuid().v4().substring(0, 8).toUpperCase()}';
    final draft = await _editDialog(
      id: id,
      type: type,
      text: '',
      metadata: const <String, String>{},
      revision: 0,
    );
    if (draft != null) await _save(draft);
  }

  Future<void> _editWord(KannadaSourceWord item, ItemBankDraft? current) async {
    final base = current;
    final draft = await _editDialog(
      id: item.id,
      type: ItemBankDraftType.realWord,
      text: base?.text ?? item.text,
      metadata: base?.metadata ?? <String, String>{
        'transcription': item.transcription,
        'meaning': item.meaning,
        'part_of_speech': item.partOfSpeech,
        'age_band': item.ageBand,
        'akshara_type': item.aksharaType,
        'mean_age_of_acquisition': item.meanAgeOfAcquisition?.toString() ?? '',
        'syllables': item.syllables?.toString() ?? '',
        'phonemes': item.phonemes?.toString() ?? '',
        'morphemes': item.morphemes?.toString() ?? '',
      },
      revision: base?.revision ?? 0,
      createdAt: base?.createdAt,
      updatedAt: base?.updatedAt,
    );
    if (draft != null) await _save(draft);
  }

  Future<void> _editNonWord(
    KannadaNonWordCandidate item,
    ItemBankDraft? current,
  ) async {
    final base = current;
    final draft = await _editDialog(
      id: item.id,
      type: ItemBankDraftType.nonWord,
      text: base?.text ?? item.text,
      metadata: base?.metadata ?? <String, String>{
        'method': item.method,
        'source_word_1': item.sourceWord1,
        'source_id_1': item.sourceId1,
        'source_word_2': item.sourceWord2 ?? '',
        'source_id_2': item.sourceId2 ?? '',
        'transformation': item.transformation,
      },
      revision: base?.revision ?? 0,
      createdAt: base?.createdAt,
      updatedAt: base?.updatedAt,
    );
    if (draft != null) await _save(draft);
  }

  Future<ItemBankDraft?> _editDialog({
    required String id,
    required ItemBankDraftType type,
    required String text,
    required Map<String, String> metadata,
    required int revision,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return showDialog<ItemBankDraft>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ItemBankDraftEditorDialog(
        id: id,
        type: type,
        initialText: text,
        initialMetadata: metadata,
        revision: revision,
        createdAt: createdAt,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> _save(ItemBankDraft draft) async {
    try {
      final allDrafts = await _store.loadAll();
      final normalized = draft.text.trim();
      final duplicateWord = widget.catalog.realWords.any(
        (item) => item.id != draft.id && item.text.trim() == normalized,
      );
      final duplicateNonWord = widget.catalog.suppliedNonWordCandidates.any(
        (item) => item.id != draft.id && item.text.trim() == normalized,
      );
      final duplicateDraft = allDrafts.any(
        (item) => item.id != draft.id && item.text.trim() == normalized,
      );
      if (duplicateWord || duplicateNonWord || duplicateDraft) {
        throw StateError('This Kannada text already exists under another item ID.');
      }
      final saved = await _store.save(draft);
      if (!mounted) return;
      await _refresh();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Saved local draft ${saved.id} · revision ${saved.revision}'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Draft was not saved: $error'),
          backgroundColor: AppTheme.coral,
        ),
      );
    }
  }

  Future<void> _showHistory(String itemId) async {
    try {
      final history = await _store.loadHistory(itemId);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Revision history · $itemId'),
          content: SizedBox(
            width: 440,
            child: history.isEmpty
                ? const Text('No saved revisions are available.')
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: history.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final item = history[index];
                      return ListTile(
                        dense: true,
                        title: Text('Revision ${item.revision} · ${item.text}'),
                        subtitle: Text(item.updatedAt.toLocal().toString()),
                      );
                    },
                  ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load revision history: $error')),
      );
    }
  }

  bool _matches(String text, String id, [String extra = '']) {
    if (_query.isEmpty) return true;
    return text.toLowerCase().contains(_query) ||
        id.toLowerCase().contains(_query) ||
        extra.toLowerCase().contains(_query);
  }

  ItemBankDraft? _findDraft(List<ItemBankDraft> drafts, String id) {
    for (final draft in drafts) {
      if (draft.id == id) return draft;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ItemBankDraft>>(
      future: _draftsFuture,
      builder: (context, snapshot) {
        final drafts = snapshot.data ?? const <ItemBankDraft>[];
        final wordDrafts = drafts
            .where((item) => item.type == ItemBankDraftType.realWord)
            .length;
        final nonWordDrafts = drafts
            .where((item) => item.type == ItemBankDraftType.nonWord)
            .length;
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  children: <Widget>[
                    const Icon(Icons.edit_note_rounded, color: AppTheme.teal),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Content management · Draft workspace',
                        style: TextStyle(
                          color: AppTheme.deepInk,
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Reload saved drafts',
                      onPressed: snapshot.connectionState == ConnectionState.waiting
                          ? null
                          : _refresh,
                      icon: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Edit supplied entries or create new draft items. Draft changes '
                  'are saved locally with revision history and never enter the '
                  'playable task or participant item bank.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: <Widget>[
                    OutlinedButton.icon(
                      onPressed: () => _add(ItemBankDraftType.realWord),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('Add Real Word'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () => _add(ItemBankDraftType.nonWord),
                      icon: const Icon(Icons.add_rounded, size: 17),
                      label: const Text('Add Non-Word'),
                    ),
                    OutlinedButton.icon(
                      onPressed: drafts.isEmpty ? null : _downloadBackup,
                      icon: const Icon(Icons.download_outlined, size: 17),
                      label: const Text('Download draft backup'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Storage: encrypted SQLCipher on Android; browser IndexedDB on Web (not encrypted and limited to content drafts). Browser drafts can be cleared by browser settings, so download backups regularly. Never enter participant data or reviewer personal information.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: _search,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    labelText: 'Search items and saved drafts',
                    border: OutlineInputBorder(),
                    isDense: true,
                  ),
                ),
                const SizedBox(height: 8),
                if (snapshot.connectionState == ConnectionState.waiting)
                  const LinearProgressIndicator(minHeight: 2),
                if (snapshot.hasError)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(
                      'Local draft storage could not be opened: ${snapshot.error}',
                      style: const TextStyle(color: AppTheme.coral),
                    ),
                  ),
                if (snapshot.hasData)
                  DefaultTabController(
                    length: 3,
                    child: Column(
                      children: <Widget>[
                        TabBar(
                          isScrollable: true,
                          tabAlignment: TabAlignment.start,
                          labelColor: AppTheme.tealDark,
                          unselectedLabelColor: AppTheme.muted,
                          tabs: <Widget>[
                            Tab(text: 'Real Words · ${widget.catalog.realWords.length}'),
                            Tab(text: 'Non-Words · ${widget.catalog.suppliedNonWordCount}'),
                            Tab(text: 'Drafts · ${drafts.length}'),
                          ],
                        ),
                        SizedBox(
                          height: 420,
                          child: TabBarView(
                            children: <Widget>[
                              _realWordsTab(drafts),
                              _nonWordsTab(drafts),
                              _draftsTab(drafts),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: <Widget>[
                            const Icon(Icons.history_rounded,
                                size: 16, color: AppTheme.teal),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                '$wordDrafts real-word drafts · $nonWordDrafts non-word drafts · all remain unapproved',
                                style: const TextStyle(
                                  color: AppTheme.muted,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _realWordsTab(List<ItemBankDraft> drafts) {
    final items = widget.catalog.realWords.where((item) {
      final draft = _findDraft(drafts, item.id);
      return _matches(
        draft?.text ?? item.text,
        item.id,
        '${item.transcription} ${item.meaning}',
      );
    }).toList(growable: false);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final draft = _findDraft(drafts, item.id);
        final title = draft?.text ?? item.text;
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(
            title,
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${item.id} · ${item.meaning}${draft == null ? '' : ' · DRAFT r${draft.revision}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: draft == null ? 'Create editable draft' : 'Edit saved draft',
            onPressed: () => _editWord(item, draft),
            icon: Icon(
              draft == null ? Icons.edit_outlined : Icons.edit_note_rounded,
              color: AppTheme.tealDark,
            ),
          ),
        );
      },
    );
  }

  Widget _nonWordsTab(List<ItemBankDraft> drafts) {
    final items = widget.catalog.suppliedNonWordCandidates.where((item) {
      final draft = _findDraft(drafts, item.id);
      return _matches(
        draft?.text ?? item.text,
        item.id,
        '${item.method} ${item.sourceWord1}',
      );
    }).toList(growable: false);
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: items.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final item = items[index];
        final draft = _findDraft(drafts, item.id);
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(
            draft?.text ?? item.text,
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${item.id} · ${item.method} · ${item.sourceWord1}${draft == null ? '' : ' · DRAFT r${draft.revision}'}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: IconButton(
            tooltip: draft == null ? 'Create editable review draft' : 'Edit saved draft',
            onPressed: () => _editNonWord(item, draft),
            icon: Icon(
              draft == null ? Icons.edit_outlined : Icons.edit_note_rounded,
              color: AppTheme.tealDark,
            ),
          ),
        );
      },
    );
  }

  Widget _draftsTab(List<ItemBankDraft> drafts) {
    final filtered = drafts.where((draft) =>
      _matches(draft.text, draft.id, draft.typeValue)).toList(growable: false);
    if (filtered.isEmpty) {
      return const Center(
        child: Text(
          'No saved drafts yet. Edit a supplied item or add a new one.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppTheme.muted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final draft = filtered[index];
        return ListTile(
          dense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          title: Text(
            draft.text,
            style: const TextStyle(
              color: AppTheme.deepInk,
              fontSize: 17,
              fontWeight: FontWeight.w800,
            ),
          ),
          subtitle: Text(
            '${draft.id} · ${draft.type == ItemBankDraftType.realWord ? 'Real Word' : 'Non-Word'} · revision ${draft.revision}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              IconButton(
                tooltip: 'View revision history',
                onPressed: () => _showHistory(draft.id),
                icon: const Icon(Icons.history_rounded, color: AppTheme.muted),
              ),
              IconButton(
                tooltip: 'Edit draft',
                onPressed: () async {
                  final edited = await _editDialog(
                    id: draft.id,
                    type: draft.type,
                    text: draft.text,
                    metadata: draft.metadata,
                    revision: draft.revision,
                    createdAt: draft.createdAt,
                    updatedAt: draft.updatedAt,
                  );
                  if (edited != null) await _save(edited);
                },
                icon: const Icon(Icons.edit_note_rounded, color: AppTheme.tealDark),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemBankDraftEditorDialog extends StatefulWidget {
  const _ItemBankDraftEditorDialog({
    required this.id,
    required this.type,
    required this.initialText,
    required this.initialMetadata,
    required this.revision,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final ItemBankDraftType type;
  final String initialText;
  final Map<String, String> initialMetadata;
  final int revision;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  @override
  State<_ItemBankDraftEditorDialog> createState() =>
      _ItemBankDraftEditorDialogState();
}

class _ItemBankDraftEditorDialogState
    extends State<_ItemBankDraftEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _text;
  late final Map<String, TextEditingController> _fields;
  String? _method;
  String? _error;

  bool get _isWord => widget.type == ItemBankDraftType.realWord;

  static const _wordFields = <(String, String)>[
    ('transcription', 'Transcription / romanization'),
    ('meaning', 'Meaning'),
    ('part_of_speech', 'Part of speech'),
    ('age_band', 'Age band'),
    ('akshara_type', 'Akshara type'),
    ('mean_age_of_acquisition', 'Mean age of acquisition'),
    ('syllables', 'Syllables'),
    ('phonemes', 'Phonemes'),
    ('morphemes', 'Morphemes'),
  ];

  static const _nonWordFields = <(String, String)>[
    ('source_word_1', 'First source word'),
    ('source_id_1', 'First source word ID'),
    ('source_word_2', 'Second source word (where required)'),
    ('source_id_2', 'Second source word ID (where required)'),
    ('transformation', 'Construction / transformation'),
  ];

  @override
  void initState() {
    super.initState();
    _text = TextEditingController(text: widget.initialText);
    _method = widget.initialMetadata['method'];
    final keys = _isWord ? _wordFields : _nonWordFields;
    _fields = <String, TextEditingController>{
      for (final field in keys)
        field.$1: TextEditingController(
          text: widget.initialMetadata[field.$1] ?? '',
        ),
    };
  }

  @override
  void dispose() {
    _text.dispose();
    for (final controller in _fields.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final metadata = <String, String>{
      for (final entry in _fields.entries)
        entry.key: entry.value.text.trim(),
    };
    if (!_isWord) metadata['method'] = _method ?? '';
    try {
      final draft = ItemBankDraft(
        id: widget.id,
        type: widget.type,
        text: _text.text.trim(),
        metadata: metadata,
        revision: widget.revision,
        createdAt: widget.createdAt,
        updatedAt: widget.updatedAt,
      );
      draft.validate();
      Navigator.of(context).pop(draft);
    } catch (error) {
      setState(() => _error = error.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final fields = _isWord ? _wordFields : _nonWordFields;
    return AlertDialog(
      title: Text(_isWord ? 'Real Word draft' : 'Non-Word draft'),
      content: SizedBox(
        width: 480,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Text(
                  '${widget.id} · Draft revision ${widget.revision}',
                  style: const TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _text,
                  autofocus: true,
                  minLines: 1,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Kannada item text *',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty
                          ? 'Enter the Kannada item text.'
                          : null,
                ),
                if (!_isWord) ...<Widget>[
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: _method,
                    decoration: const InputDecoration(
                      labelText: 'Non-word construction method *',
                      border: OutlineInputBorder(),
                    ),
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(value: 'A_vowel', child: Text('A · Vowel replacement')),
                      DropdownMenuItem(value: 'B_consonant', child: Text('B · Consonant replacement')),
                      DropdownMenuItem(value: 'C_suffix_prefix', child: Text('C · Suffix + prefix blend')),
                      DropdownMenuItem(value: 'D_prefix_suffix', child: Text('D · Prefix + suffix blend')),
                    ],
                    onChanged: (value) => setState(() => _method = value),
                    validator: (value) => value == null ? 'Select a construction method.' : null,
                  ),
                ],
                for (final field in fields) ...<Widget>[
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _fields[field.$1],
                    decoration: InputDecoration(
                      labelText: field.$2,
                      border: const OutlineInputBorder(),
                    ),
                    maxLines: field.$1 == 'transformation' ? 2 : 1,
                    validator: (value) {
                      if (_isWord) return null;
                      if (field.$1 == 'source_word_2' ||
                          field.$1 == 'source_id_2') {
                        if (_method != 'C_suffix_prefix' &&
                            _method != 'D_prefix_suffix') return null;
                      }
                      return value == null || value.trim().isEmpty
                          ? 'This field is required.'
                          : null;
                    },
                  ),
                ],
                if (_error != null) ...<Widget>[
                  const SizedBox(height: 10),
                  Text(_error!, style: const TextStyle(color: AppTheme.coral)),
                ],
                const SizedBox(height: 12),
                const Text(
                  'This saves an editable local draft only. It does not mark the item reviewed, approved or available to gameplay. Do not enter child or participant information here.',
                  style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: <Widget>[
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.save_outlined, size: 17),
          label: const Text('Save draft'),
        ),
      ],
    );
  }
}
