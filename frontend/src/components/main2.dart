// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spaces (Mobile)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
      ),
      home: const SpacesMobilePage(),
    );
  }
}

/* ============================== */
/* ==========  MODELS  ========== */
/* ============================== */

enum SortKey { name, keyCol, type, lead, status, updatedAt }

class SpaceItem {
  int id;
  bool star;
  String name;
  String key;
  String type; // Service management | Team-managed software
  String lead;
  String leadInitials;
  bool archived;
  String url;
  DateTime updatedAt;

  SpaceItem({
    required this.id,
    required this.star,
    required this.name,
    required this.key,
    required this.type,
    required this.lead,
    required this.leadInitials,
    required this.archived,
    required this.url,
    required this.updatedAt,
  });

  String get status => archived ? 'Archived' : 'Active';
}

/* ============================================= */
/* ==========  MOBILE SPACES SCREEN  =========== */
/* ============================================= */

class SpacesMobilePage extends StatefulWidget {
  const SpacesMobilePage({super.key});
  @override
  State<SpacesMobilePage> createState() => _SpacesMobilePageState();
}

class _SpacesMobilePageState extends State<SpacesMobilePage> {
  // --------- MOCK DATA ----------
  final List<SpaceItem> _raw = [
    SpaceItem(
      id: 1,
      star: true,
      name: 'Support',
      key: 'SUP',
      type: 'Service management',
      lead: 'Tuấn Kiệt Lê Nguyễn',
      leadInitials: 'TN',
      archived: false,
      url: 'https://example.com/sup',
      updatedAt: DateTime(2025, 9, 20),
    ),
    SpaceItem(
      id: 2,
      star: false,
      name: 'To Do List System',
      key: 'KAN',
      type: 'Team-managed software',
      lead: 'Tuấn Kiệt Lê Nguyễn',
      leadInitials: 'TN',
      archived: false,
      url: 'https://example.com/kan',
      updatedAt: DateTime(2025, 9, 18),
    ),
    SpaceItem(
      id: 3,
      star: false,
      name: 'Marketing Ops',
      key: 'MKT',
      type: 'Service management',
      lead: 'Mai Trần',
      leadInitials: 'MT',
      archived: false,
      url: 'https://example.com/mkt',
      updatedAt: DateTime(2025, 8, 11),
    ),
    SpaceItem(
      id: 4,
      star: true,
      name: 'Finance Hub',
      key: 'FIN',
      type: 'Team-managed software',
      lead: 'Lâm Phạm',
      leadInitials: 'LP',
      archived: false,
      url: 'https://example.com/fin',
      updatedAt: DateTime(2025, 8, 3),
    ),
    SpaceItem(
      id: 5,
      star: false,
      name: 'HR Portal',
      key: 'HR',
      type: 'Service management',
      lead: 'An Nguyễn',
      leadInitials: 'AN',
      archived: false,
      url: 'https://example.com/hr',
      updatedAt: DateTime(2025, 7, 25),
    ),
    SpaceItem(
      id: 6,
      star: false,
      name: 'Design Board',
      key: 'DSN',
      type: 'Team-managed software',
      lead: 'Yến Hà',
      leadInitials: 'YH',
      archived: false,
      url: 'https://example.com/dsn',
      updatedAt: DateTime(2025, 7, 12),
    ),
    SpaceItem(
      id: 7,
      star: false,
      name: 'IT Operations',
      key: 'OPS',
      type: 'Service management',
      lead: 'Hải Đỗ',
      leadInitials: 'HĐ',
      archived: false,
      url: 'https://example.com/ops',
      updatedAt: DateTime(2025, 7, 7),
    ),
    SpaceItem(
      id: 8,
      star: false,
      name: 'Data Platform',
      key: 'DPL',
      type: 'Team-managed software',
      lead: 'Trang Võ',
      leadInitials: 'TV',
      archived: false,
      url: 'https://example.com/dpl',
      updatedAt: DateTime(2025, 6, 28),
    ),
    SpaceItem(
      id: 9,
      star: false,
      name: 'Customer Success',
      key: 'CS',
      type: 'Service management',
      lead: 'Long Phạm',
      leadInitials: 'LP',
      archived: true,
      url: 'https://example.com/cs',
      updatedAt: DateTime(2025, 5, 16),
    ),
    SpaceItem(
      id: 10,
      star: false,
      name: 'QA Lab',
      key: 'QAL',
      type: 'Team-managed software',
      lead: 'Huệ Đặng',
      leadInitials: 'HĐ',
      archived: false,
      url: 'https://example.com/qal',
      updatedAt: DateTime(2025, 4, 3),
    ),
    SpaceItem(
      id: 11,
      star: false,
      name: 'Growth Sandbox',
      key: 'GRW',
      type: 'Team-managed software',
      lead: 'Hùng Lê',
      leadInitials: 'HL',
      archived: false,
      url: 'https://example.com/grw',
      updatedAt: DateTime(2025, 1, 10),
    ),
    SpaceItem(
      id: 12,
      star: false,
      name: 'Partner Portal',
      key: 'PRT',
      type: 'Service management',
      lead: 'Quỳnh Anh',
      leadInitials: 'QA',
      archived: false,
      url: 'https://example.com/prt',
      updatedAt: DateTime(2024, 12, 1),
    ),
  ];

  /* ------------ STATE (Filters/Sort/etc) ------------ */
  String q = '';
  String? filterType;
  String? filterLead;
  String? filterStatus; // Active | Archived
  bool filterStarred = false;

  SortKey sortKey = SortKey.name;
  bool sortAsc = true;

  // Density (height of card)
  bool compact = false;

  // Selection mode
  bool selectionMode = false;
  final Set<int> selectedIds = {};

  // Infinite list
  static const int pageChunk = 10;
  int visibleCount = pageChunk;

  /* ------------ Computed data ------------ */
  List<String> get typeOptions => const [
        'Service management',
        'Team-managed software',
      ];
  List<String> get leadOptions =>
      _raw.map((e) => e.lead).toSet().toList()..sort();

  List<SpaceItem> get _filteredSorted {
    List<SpaceItem> arr = List.of(_raw);

    if (q.trim().isNotEmpty) {
      final s = q.trim().toLowerCase();
      arr = arr.where((x) {
        return x.name.toLowerCase().contains(s) || x.key.toLowerCase().contains(s);
      }).toList();
    }
    if (filterType != null) {
      arr = arr.where((x) => x.type == filterType).toList();
    }
    if (filterLead != null) {
      arr = arr.where((x) => x.lead == filterLead).toList();
    }
    if (filterStatus != null) {
      arr = filterStatus == 'Archived'
          ? arr.where((x) => x.archived).toList()
          : arr.where((x) => !x.archived).toList();
    }
    if (filterStarred) {
      arr = arr.where((x) => x.star).toList();
    }

    int cmp<T extends Comparable>(T a, T b) => a.compareTo(b);
    arr.sort((a, b) {
      int c = 0;
      switch (sortKey) {
        case SortKey.name:
          c = cmp(a.name.toLowerCase(), b.name.toLowerCase());
          break;
        case SortKey.keyCol:
          c = cmp(a.key.toLowerCase(), b.key.toLowerCase());
          break;
        case SortKey.type:
          c = cmp(a.type.toLowerCase(), b.type.toLowerCase());
          break;
        case SortKey.lead:
          c = cmp(a.lead.toLowerCase(), b.lead.toLowerCase());
          break;
        case SortKey.status:
          c = cmp(a.status.toLowerCase(), b.status.toLowerCase());
          break;
        case SortKey.updatedAt:
          c = a.updatedAt.compareTo(b.updatedAt);
          break;
      }
      return sortAsc ? c : -c;
    });

    return arr;
  }

  List<SpaceItem> get _visibleList =>
      _filteredSorted.take(visibleCount.clamp(0, _filteredSorted.length)).toList();

  /* ------------ Helpers ------------ */
  Color typeColor(String type) =>
      type == 'Service management' ? Colors.amber.shade700 : Colors.blue.shade700;
  Color typeBg(String type) =>
      type == 'Service management' ? Colors.amber.shade50 : Colors.blue.shade50;

  Color statusColor(String status) =>
      status == 'Active' ? Colors.green.shade700 : Colors.grey.shade700;
  Color statusBg(String status) =>
      status == 'Active' ? Colors.green.shade50 : Colors.grey.shade200;

  String fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  void resetAndApply() {
    setState(() {
      visibleCount = pageChunk;
      selectedIds.clear();
      selectionMode = false;
    });
  }

  /* ------------ Item actions ------------ */
  void toggleStar(SpaceItem s) => setState(() => s.star = !s.star);
  void toggleArchive(SpaceItem s) =>
      setState(() {
        s.archived = !s.archived;
        s.updatedAt = DateTime.now();
      });

  Future<void> renameSpace(SpaceItem s) async {
    final controller = TextEditingController(text: s.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rename space'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: 'New name'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Save')),
        ],
      ),
    );
    if (name != null && name.isNotEmpty) {
      setState(() => s.name = name);
      _toast('Renamed');
    }
  }

  void duplicateSpace(SpaceItem s) {
    final nextId = _raw.fold<int>(0, (p, c) => c.id > p ? c.id : p) + 1;
    String uniqueKey(String base) {
      var k = base;
      var i = 1;
      final set = _raw.map((e) => e.key).toSet();
      while (set.contains(k)) {
        k = '$base$i';
        i++;
      }
      return k;
    }

    final clone = SpaceItem(
      id: nextId,
      star: false,
      name: '${s.name} (Copy)',
      key: uniqueKey(s.key),
      type: s.type,
      lead: s.lead,
      leadInitials: s.leadInitials,
      archived: false,
      url: s.url,
      updatedAt: DateTime.now(),
    );
    setState(() {
      _raw.insert(0, clone);
      visibleCount = (visibleCount + 1).clamp(0, _filteredSorted.length);
    });
    _toast('Duplicated');
  }

  void deleteSpace(SpaceItem s) {
    setState(() {
      _raw.removeWhere((e) => e.id == s.id);
      selectedIds.remove(s.id);
      visibleCount = visibleCount.clamp(0, _filteredSorted.length);
    });
    _toast('Deleted');
  }

  void _toast(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  /* ------------ Bulk ------------ */
  void bulkArchive(bool archive) {
    setState(() {
      for (final s in _raw.where((x) => selectedIds.contains(x.id))) {
        s.archived = archive;
        s.updatedAt = DateTime.now();
      }
    });
    _toast(archive ? 'Archived selected' : 'Unarchived selected');
  }

  Future<void> bulkDelete() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete selected?'),
        content: Text('This will delete ${selectedIds.length} space(s).'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      setState(() {
        _raw.removeWhere((x) => selectedIds.contains(x.id));
        selectedIds.clear();
        selectionMode = false;
        visibleCount = visibleCount.clamp(0, _filteredSorted.length);
      });
      _toast('Deleted selected');
    }
  }

  /* ------------ CSV ------------ */
  Future<void> exportCSV() async {
    final rows = _filteredSorted;
    final header = ['Starred','Name','Key','Type','Lead','Status','Updated','URL'];
    final data = rows.map((r) => [
      r.star ? 'Yes' : 'No',
      r.name, r.key, r.type, r.lead, r.status,
      '${r.updatedAt.year}-${r.updatedAt.month.toString().padLeft(2,'0')}-${r.updatedAt.day.toString().padLeft(2,'0')}',
      r.url
    ]);
    String escape(String s) =>
        s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    final csv = [header, ...data].map((r) => r.map((e) => escape(e.toString())).join(',')).join('\n');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV preview'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace')),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) _toast('CSV copied');
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /* ------------ Bottom sheets ------------ */
  Future<void> openFiltersSheet() async {
    String? t = filterType;
    String? l = filterLead;
    String? s = filterStatus;
    bool starred = filterStarred;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (_) {
        return Padding(
          padding: MediaQuery.of(context).viewInsets.add(const EdgeInsets.all(16)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetTitle('Filters'),
              const SizedBox(height: 8),
              _dropdownField(
                value: t,
                items: typeOptions,
                hint: 'Type (app)',
                onChanged: (v) => t = v,
              ),
              const SizedBox(height: 8),
              _dropdownField(
                value: l,
                items: leadOptions,
                hint: 'Lead',
                onChanged: (v) => l = v,
              ),
              const SizedBox(height: 8),
              _dropdownField(
                value: s,
                items: const ['Active','Archived'],
                hint: 'Status',
                onChanged: (v) => s = v,
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Starred only'),
                value: starred,
                onChanged: (v) => starred = v,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: () {
                    t = null; l = null; s = null; starred = false;
                    setState((){}); // rebuild inside sheet
                  }, child: const Text('Clear'))),
                  const SizedBox(width: 8),
                  Expanded(child: FilledButton(onPressed: () {
                    Navigator.pop(context, true);
                    setState(() {
                      filterType = t; filterLead = l; filterStatus = s; filterStarred = starred;
                      resetAndApply();
                    });
                  }, child: const Text('Apply'))),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> openSortSheet() async {
    SortKey sk = sortKey;
    bool asc = sortAsc;

    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTitle('Sort'),
            const SizedBox(height: 4),
            for (final k in SortKey.values)
              RadioListTile<SortKey>(
                value: k,
                groupValue: sk,
                onChanged: (v) => setState(() => sk = v!),
                title: Text(_sortLabel(k)),
              ),
            const Divider(),
            SwitchListTile(
              value: asc,
              onChanged: (v) => setState(() => asc = v),
              title: const Text('Ascending'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () {
                  sk = SortKey.name; asc = true;
                  setState(() {});
                }, child: const Text('Reset'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () {
                  Navigator.pop(context, true);
                  setState(() { sortKey = sk; sortAsc = asc; resetAndApply(); });
                }, child: const Text('Apply'))),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Future<void> openDensitySheet() async {
    bool _compact = compact;
    await showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _sheetTitle('Density'),
            RadioListTile<bool>(
              value: false, groupValue: _compact, onChanged: (v) => setState(() => _compact = v!),
              title: const Text('Comfortable'),
            ),
            RadioListTile<bool>(
              value: true, groupValue: _compact, onChanged: (v) => setState(() => _compact = v!),
              title: const Text('Compact'),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: OutlinedButton(onPressed: () { _compact = false; setState((){}); }, child: const Text('Reset'))),
                const SizedBox(width: 8),
                Expanded(child: FilledButton(onPressed: () { Navigator.pop(context); setState(() => compact = _compact); }, child: const Text('Apply'))),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  /* ------------ Build ------------ */
  @override
  Widget build(BuildContext context) {
    final title = selectionMode
        ? 'Selected: ${selectedIds.length}'
        : 'Spaces';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: selectionMode
            ? [
                IconButton(
                  tooltip: 'Archive',
                  icon: const Icon(Icons.archive_outlined),
                  onPressed: selectedIds.isEmpty ? null : () => bulkArchive(true),
                ),
                IconButton(
                  tooltip: 'Unarchive',
                  icon: const Icon(Icons.unarchive_outlined),
                  onPressed: selectedIds.isEmpty ? null : () => bulkArchive(false),
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: selectedIds.isEmpty ? null : bulkDelete,
                ),
              ]
            : [
                IconButton(
                  tooltip: 'Templates',
                  icon: const Icon(Icons.view_day_outlined),
                  onPressed: () => _toast('Templates tapped'),
                ),
                IconButton(
                  tooltip: 'Create space',
                  icon: const Icon(Icons.add_circle_outline),
                  onPressed: () => _toast('Create tapped'),
                ),
              ],
        leading: selectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  selectionMode = false;
                  selectedIds.clear();
                }),
              )
            : null,
      ),

      body: Column(
        children: [
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search spaces',
                border: const OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: (v) => setState(() { q = v; resetAndApply(); }),
            ),
          ),

          // Quick actions bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.filter_alt_outlined, size: 18),
                  label: const Text('Filters'),
                  onPressed: openFiltersSheet,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.sort, size: 18),
                  label: const Text('Sort'),
                  onPressed: openSortSheet,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.density_medium, size: 18),
                  label: const Text('Density'),
                  onPressed: openDensitySheet,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.ios_share, size: 18),
                  label: const Text('Export CSV'),
                  onPressed: exportCSV,
                ),
                if (!selectionMode)
                  OutlinedButton.icon(
                    icon: const Icon(Icons.check_box_outlined, size: 18),
                    label: const Text('Select'),
                    onPressed: () => setState(() {
                      selectionMode = true;
                      selectedIds.clear();
                    }),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // List
          Expanded(
            child: _visibleList.isEmpty
                ? const Center(child: Text('No spaces'))
                : ListView.separated(
                    itemCount: _visibleList.length + (_visibleList.length < _filteredSorted.length ? 1 : 0),
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      if (index == _visibleList.length) {
                        return Padding(
                          padding: const EdgeInsets.all(16),
                          child: OutlinedButton(
                            onPressed: () => setState(() => visibleCount += pageChunk),
                            child: Text('Load more (${_filteredSorted.length - _visibleList.length} more)'),
                          ),
                        );
                      }
                      final s = _visibleList[index];
                      final checked = selectedIds.contains(s.id);

                      return GestureDetector(
                        onLongPress: () {
                          if (!selectionMode) {
                            setState(() {
                              selectionMode = true;
                              selectedIds.add(s.id);
                            });
                          }
                        },
                        onTap: () {
                          if (selectionMode) {
                            setState(() {
                              if (checked) {
                                selectedIds.remove(s.id);
                                if (selectedIds.isEmpty) selectionMode = false;
                              } else {
                                selectedIds.add(s.id);
                              }
                            });
                          } else {
                            _toast('Open: ${s.url}');
                          }
                        },
                        child: Container(
                          color: selectionMode && checked
                              ? Colors.indigo.withOpacity(.06)
                              : null,
                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: compact ? 8 : 12),
                          child: _spaceCard(s, checked),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  /* ------------ Widgets ------------ */

  Widget _spaceCard(SpaceItem s, bool checked) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top line
        Row(
          children: [
            if (selectionMode)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Checkbox(
                  value: checked,
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      selectedIds.add(s.id);
                    } else {
                      selectedIds.remove(s.id);
                      if (selectedIds.isEmpty) selectionMode = false;
                    }
                  }),
                ),
              ),
            // icon placeholder
            Container(
              width: 24,
              height: 24,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: typeBg(s.type),
                border: Border.all(color: typeColor(s.type)),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Text(
                s.name,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              icon: Icon(s.star ? Icons.star : Icons.star_border, color: Colors.amber.shade700),
              onPressed: () => toggleStar(s),
              tooltip: s.star ? 'Unstar' : 'Star',
            ),
            PopupMenuButton<String>(
              onSelected: (v) async {
                switch (v) {
                  case 'open': _toast('Open: ${s.url}'); break;
                  case 'copy':
                    await Clipboard.setData(ClipboardData(text: s.url));
                    if (context.mounted) _toast('Copied URL');
                    break;
                  case 'rename': await renameSpace(s); break;
                  case 'duplicate': duplicateSpace(s); break;
                  case 'archive': toggleArchive(s); break;
                  case 'delete': deleteSpace(s); break;
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'open', child: Text('Open')),
                const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
                const PopupMenuItem(value: 'rename', child: Text('Rename')),
                const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'archive',
                  child: Text(s.archived ? 'Unarchive' : 'Archive'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 4),

        // Meta row
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _chip(text: s.key, icon: Icons.key, mono: true),
            _tag(text: s.type, fg: typeColor(s.type), bg: typeBg(s.type)),
            _leadChip(s.lead, s.leadInitials),
            _tag(text: s.status, fg: statusColor(s.status), bg: statusBg(s.status)),
            _chip(text: 'Updated ${fmtDate(s.updatedAt)}', icon: Icons.calendar_today_outlined),
          ],
        ),
      ],
    );
  }

  Widget _chip({required String text, IconData? icon, bool mono = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: Colors.grey.shade700),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(
            fontFamily: mono ? 'monospace' : null,
            color: Colors.grey.shade800,
          ),
        ),
      ]),
    );
  }

  Widget _tag({required String text, required Color fg, required Color bg}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: TextStyle(color: fg)),
    );
  }

  Widget _leadChip(String name, String initials) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        CircleAvatar(radius: 9, backgroundColor: Colors.indigo, child: Text(initials, style: const TextStyle(fontSize: 10, color: Colors.white))),
        const SizedBox(width: 6),
        Text(name),
      ]),
    );
  }

  Widget _sheetTitle(String t) => Row(
        children: [
          Text(t, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const Spacer(),
        ],
      );

  Widget _dropdownField({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: InputDecoration(
        isDense: true,
        border: const OutlineInputBorder(),
        labelText: hint,
      ),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  String _sortLabel(SortKey k) {
    switch (k) {
      case SortKey.name: return 'Name';
      case SortKey.keyCol: return 'Key';
      case SortKey.type: return 'Type';
      case SortKey.lead: return 'Lead';
      case SortKey.status: return 'Status';
      case SortKey.updatedAt: return 'Updated';
    }
  }
}
