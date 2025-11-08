// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Clipboard

void main() => runApp(const MyApp());

/// =======================
/// App shell
/// =======================
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Spaces Manager',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: false,
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const SpacesPage(),
    );
  }
}

/// =======================
/// Models / constants
/// =======================
enum ColKey { star, name, keyCol, type, lead, status, updatedAt, url }

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

/// =======================
/// Page
/// =======================
class SpacesPage extends StatefulWidget {
  const SpacesPage({super.key});
  @override
  State<SpacesPage> createState() => _SpacesPageState();
}

class _SpacesPageState extends State<SpacesPage> {
  // ---------- MOCK DATA ----------
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

  // ---------- Filters / state ----------
  String q = '';
  String? filterType;
  String? filterLead;
  String? filterStatus; // Active | Archived
  bool onlyStarred = false;

  // Visible columns
  final Map<ColKey, String> columnLabels = const {
    ColKey.star: '',
    ColKey.name: 'Name',
    ColKey.keyCol: 'Key',
    ColKey.type: 'Type',
    ColKey.lead: 'Lead',
    ColKey.status: 'Status',
    ColKey.updatedAt: 'Updated',
    ColKey.url: 'Space URL',
  };
  final List<ColKey> allCols = [
    ColKey.star,
    ColKey.name,
    ColKey.keyCol,
    ColKey.type,
    ColKey.lead,
    ColKey.status,
    ColKey.updatedAt,
    ColKey.url,
  ];
  final Set<ColKey> visibleCols = {
    ColKey.star,
    ColKey.name,
    ColKey.keyCol,
    ColKey.type,
    ColKey.lead,
    ColKey.status,
    ColKey.updatedAt,
    ColKey.url,
  };

  // Sorting
  ColKey sortKey = ColKey.name;
  bool sortAsc = true;

  // Density
  String density = 'middle'; // large | middle | small

  // Selection & bulk actions
  final Set<int> selectedIds = {};

  // Pagination
  int page = 1; // 1-indexed
  int pageSize = 10;

  // Helpers
  List<String> get typeOptions => [
        'Service management',
        'Team-managed software',
      ];
  List<String> get leadOptions =>
      _raw.map((e) => e.lead).toSet().toList()..sort();

  // ---------- Derived ----------
  List<SpaceItem> get _filteredSorted {
    List<SpaceItem> arr = List.of(_raw);

    if (q.trim().isNotEmpty) {
      final s = q.trim().toLowerCase();
      arr = arr
          .where((x) =>
              x.name.toLowerCase().contains(s) || x.key.toLowerCase().contains(s))
          .toList();
    }
    if (filterType != null) {
      arr = arr.where((x) => x.type == filterType).toList();
    }
    if (filterLead != null) {
      arr = arr.where((x) => x.lead == filterLead).toList();
    }
    if (filterStatus != null) {
      if (filterStatus == 'Archived') {
        arr = arr.where((x) => x.archived).toList();
      } else {
        arr = arr.where((x) => !x.archived).toList();
      }
    }
    if (onlyStarred) arr = arr.where((x) => x.star).toList();

    int cmpBy<T extends Comparable>(T a, T b) => a.compareTo(b);

    arr.sort((a, b) {
      int cmp = 0;
      switch (sortKey) {
        case ColKey.name:
          cmp = cmpBy(a.name.toLowerCase(), b.name.toLowerCase());
          break;
        case ColKey.keyCol:
          cmp = cmpBy(a.key.toLowerCase(), b.key.toLowerCase());
          break;
        case ColKey.type:
          cmp = cmpBy(a.type.toLowerCase(), b.type.toLowerCase());
          break;
        case ColKey.lead:
          cmp = cmpBy(a.lead.toLowerCase(), b.lead.toLowerCase());
          break;
        case ColKey.status:
          cmp = cmpBy(a.status.toLowerCase(), b.status.toLowerCase());
          break;
        case ColKey.updatedAt:
          cmp = a.updatedAt.compareTo(b.updatedAt);
          break;
        case ColKey.url:
          cmp = cmpBy(a.url.toLowerCase(), b.url.toLowerCase());
          break;
        case ColKey.star:
          cmp = cmpBy(a.star ? 1 : 0, b.star ? 1 : 0);
          break;
      }
      return sortAsc ? cmp : -cmp;
    });

    return arr;
  }

  List<SpaceItem> get _paged {
    final start = (page - 1) * pageSize;
    final list = _filteredSorted;
    if (start >= list.length) return [];
    final end = (start + pageSize).clamp(0, list.length);
    return list.sublist(start, end);
  }

  int get _totalPages =>
      (_filteredSorted.length / pageSize).ceil().clamp(1, 999999);

  // ---------- UI helpers ----------
  Color _typeColor(String type) =>
      type == 'Service management' ? Colors.amber.shade600 : Colors.blue.shade600;
  Color _typeBg(String type) =>
      type == 'Service management' ? Colors.amber.shade50 : Colors.blue.shade50;

  Color _statusColor(String status) =>
      status == 'Active' ? Colors.green.shade600 : Colors.grey.shade700;
  Color _statusBg(String status) =>
      status == 'Active' ? Colors.green.shade50 : Colors.grey.shade200;

  String _fmtDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  double get _rowMinHeight => switch (density) {
        'large' => 56,
        'small' => 36,
        _ => 48,
      };

  // ---------- Actions ----------
  void _goFirstPage() => setState(() => page = 1);

  void _toggleColumn(ColKey key) {
    // keep at least one data column visible (not counting star/url)
    final next = Set<ColKey>.from(visibleCols);
    if (next.contains(key)) {
      next.remove(key);
    } else {
      next.add(key);
    }
    final hasData = next.any((k) =>
        k == ColKey.name ||
        k == ColKey.keyCol ||
        k == ColKey.type ||
        k == ColKey.lead ||
        k == ColKey.status ||
        k == ColKey.updatedAt);
    if (!hasData) return;
    setState(() => visibleCols
      ..clear()
      ..addAll(next));
  }

  void _onSort(ColKey key) {
    setState(() {
      if (sortKey == key) {
        sortAsc = !sortAsc;
      } else {
        sortKey = key;
        sortAsc = true;
      }
    });
  }

  void _toggleStar(SpaceItem item) {
    setState(() => item.star = !item.star);
  }

  void _toggleArchive(SpaceItem item) {
    setState(() {
      item.archived = !item.archived;
      item.updatedAt = DateTime.now();
    });
  }

  void _deleteSpace(SpaceItem item) {
    setState(() {
      _raw.removeWhere((e) => e.id == item.id);
      selectedIds.remove(item.id);
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Deleted')));
  }

  Future<void> _renameSpace(SpaceItem item) async {
    final controller = TextEditingController(text: item.name);
    final result = await showDialog<String>(
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
    if (result != null && result.isNotEmpty) {
      setState(() => item.name = result);
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Renamed')));
    }
  }

  void _duplicateSpace(SpaceItem item) {
    final nextId = (_raw.map((e) => e.id).fold<int>(0, (p, c) => c > p ? c : p)) + 1;
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
      name: '${item.name} (Copy)',
      key: uniqueKey(item.key),
      type: item.type,
      lead: item.lead,
      leadInitials: item.leadInitials,
      archived: false,
      url: item.url,
      updatedAt: DateTime.now(),
    );
    setState(() => _raw.insert(0, clone));
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Duplicated')));
  }

  Future<void> _exportCSV() async {
    final rows = _filteredSorted;
    final header = ['Starred', 'Name', 'Key', 'Type', 'Lead', 'Status', 'Updated', 'URL'];
    final data = rows.map((r) => [
          r.star ? 'Yes' : 'No',
          r.name,
          r.key,
          r.type,
          r.lead,
          r.status,
          '${r.updatedAt.year}-${r.updatedAt.month.toString().padLeft(2, '0')}-${r.updatedAt.day.toString().padLeft(2, '0')}',
          r.url
        ]);
    String escape(String s) =>
        s.contains(RegExp(r'[",\n]')) ? '"${s.replaceAll('"', '""')}"' : s;
    final csv = [header, ...data]
        .map((r) => r.map((e) => escape(e.toString())).join(','))
        .join('\n');

    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('CSV preview'),
        content: SizedBox(
          width: 600,
          child: SelectableText(csv, style: const TextStyle(fontFamily: 'monospace')),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close')),
          FilledButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: csv));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CSV copied')),
                );
              }
            },
            child: const Text('Copy CSV'),
          ),
        ],
      ),
    );
  }

  void _bulkArchive(bool archive) {
    setState(() {
      for (final s in _raw.where((e) => selectedIds.contains(e.id))) {
        s.archived = archive;
        s.updatedAt = DateTime.now();
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(archive ? 'Archived selected' : 'Unarchived selected')),
    );
  }

  void _bulkDelete() async {
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
        _raw.removeWhere((e) => selectedIds.contains(e.id));
        selectedIds.clear();
      });
      if (page > _totalPages) page = _totalPages;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Deleted selected')));
    }
  }

  // ---------- Build ----------
  @override
  Widget build(BuildContext context) {
    final divider = SizedBox(
      height: 32,
      child: VerticalDivider(color: Colors.grey.shade300, width: 16),
    );

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Spaces', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                  Wrap(
                    spacing: 8,
                    children: [
                      OutlinedButton(onPressed: () {}, child: const Text('Templates')),
                      ElevatedButton(onPressed: () {}, child: const Text('Create space')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Toolbar
              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  SizedBox(
                    width: 260,
                    child: TextField(
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.search),
                        hintText: 'Search spaces',
                        border: const OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (v) => setState(() {
                        q = v;
                        page = 1;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 180,
                    child: _dropdown(
                      value: filterType,
                      items: typeOptions,
                      hint: 'Filter by app',
                      onChanged: (v) => setState(() {
                        filterType = v;
                        page = 1;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 160,
                    child: _dropdown(
                      value: filterLead,
                      items: leadOptions,
                      hint: 'Lead',
                      onChanged: (v) => setState(() {
                        filterLead = v;
                        page = 1;
                      }),
                    ),
                  ),
                  SizedBox(
                    width: 140,
                    child: _dropdown(
                      value: filterStatus,
                      items: const ['Active', 'Archived'],
                      hint: 'Status',
                      onChanged: (v) => setState(() {
                        filterStatus = v;
                        page = 1;
                      }),
                    ),
                  ),
                  divider,
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Checkbox(
                        value: onlyStarred,
                        onChanged: (v) => setState(() {
                          onlyStarred = v ?? false;
                          page = 1;
                        }),
                      ),
                      const Text('Starred'),
                    ],
                  ),
                  divider,
                  // Columns
                  OutlinedButton(
                    onPressed: () async {
                      await showDialog(
                        context: context,
                        builder: (_) => _ColumnsDialog(
                          labels: columnLabels,
                          visible: Set.of(visibleCols),
                          onToggle: (c) => _toggleColumn(c),
                        ),
                      );
                      setState(() {});
                    },
                    child: const Text('Columns'),
                  ),
                  // Density
                  OutlinedButton(
                    onPressed: () async {
                      final v = await showDialog<String>(
                        context: context,
                        builder: (_) => _DensityDialog(current: density),
                      );
                      if (v != null) setState(() => density = v);
                    },
                    child: const Text('Density'),
                  ),
                  OutlinedButton(onPressed: _exportCSV, child: const Text('Export CSV')),
                  const SizedBox(width: 8),
                  // Spacer
                  SizedBox(
                    width: 1,
                    child: LayoutBuilder(builder: (context, c) {
                      return SizedBox(width: MediaQuery.of(context).size.width * .2);
                    }),
                  ),
                  // Bulk actions (only when selected)
                  if (selectedIds.isNotEmpty) ...[
                    OutlinedButton(
                      onPressed: () => _bulkArchive(true),
                      child: Text('Archive (${selectedIds.length})'),
                    ),
                    OutlinedButton(
                      onPressed: () => _bulkArchive(false),
                      child: const Text('Unarchive'),
                    ),
                    FilledButton.tonal(
                      style: FilledButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                      ),
                      onPressed: _bulkDelete,
                      child: const Text('Delete'),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),

              // Table
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: DataTableTheme(
                    data: DataTableThemeData(
                      dataRowMinHeight: _rowMinHeight,
                      dataRowMaxHeight: _rowMinHeight,
                      headingRowColor: MaterialStatePropertyAll(Colors.grey.shade100),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 900),
                        child: SingleChildScrollView(
                          child: DataTable(
                            sortColumnIndex: _sortColumnVisibleIndex(),
                            sortAscending: sortAsc,
                            columns: _buildColumns(),
                            rows: _paged.map(_buildRow).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Pagination
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    tooltip: 'Previous',
                    onPressed: page > 1
                        ? () => setState(() => page--)
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.indigo.shade200),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text('$page / $_totalPages'),
                  ),
                  IconButton(
                    tooltip: 'Next',
                    onPressed: page < _totalPages
                        ? () => setState(() => page++)
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                  const SizedBox(width: 16),
                  const Text('Rows per page:'),
                  const SizedBox(width: 8),
                  DropdownButton<int>(
                    value: pageSize,
                    items: const [5, 10, 20, 50]
                        .map((e) => DropdownMenuItem(value: e, child: Text('$e')))
                        .toList(),
                    onChanged: (v) => setState(() {
                      pageSize = v ?? 10;
                      page = 1;
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------- Widgets builders ----------
  DropdownButtonFormField<String> _dropdown({
    required String? value,
    required List<String> items,
    required String hint,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isDense: true,
      decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
      hint: Text(hint),
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
    );
  }

  int? _sortColumnVisibleIndex() {
    final cols = _visibleColList();
    final idx = cols.indexOf(sortKey);
    if (idx == -1) return null;
    // +1 because we always prepend the "Sel" checkbox column
    return idx + 1;
  }

  List<ColKey> _visibleColList() =>
      allCols.where((c) => visibleCols.contains(c)).toList();

  List<DataColumn> _buildColumns() {
    final List<DataColumn> cols = [];

    // Selection column (header has select-all for current page)
    final allSelectedOnPage =
        _paged.isNotEmpty && _paged.every((e) => selectedIds.contains(e.id));
    cols.add(
      DataColumn(
        label: Row(
          children: [
            Checkbox(
              value: allSelectedOnPage && _paged.isNotEmpty,
              tristate: _paged.isNotEmpty && !allSelectedOnPage && _paged.any((e) => selectedIds.contains(e.id)),
              onChanged: (v) {
                setState(() {
                  if (v == true) {
                    selectedIds.addAll(_paged.map((e) => e.id));
                  } else {
                    selectedIds.removeAll(_paged.map((e) => e.id));
                  }
                });
              },
            ),
            const SizedBox(width: 6),
            const Text(''),
          ],
        ),
      ),
    );

    for (final ck in _visibleColList()) {
      final label = columnLabels[ck] ?? '';
      final sortable = ck != ColKey.url && ck != ColKey.star;
      cols.add(DataColumn(
        label: InkWell(
          onTap: sortable ? () => _onSort(ck) : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              if (sortable) ...[
                const SizedBox(width: 4),
                Icon(
                  sortKey == ck
                      ? (sortAsc ? Icons.arrow_upward : Icons.arrow_downward)
                      : Icons.unfold_more,
                  size: 16,
                  color: sortKey == ck ? Colors.indigo : Colors.black45,
                ),
              ],
            ],
          ),
        ),
        onSort: sortable ? (_, __) => _onSort(ck) : null,
      ));
    }
    return cols;
  }

  DataRow _buildRow(SpaceItem r) {
    final cells = <DataCell>[];

    // Selection checkbox
    cells.add(
      DataCell(
        Checkbox(
          value: selectedIds.contains(r.id),
          onChanged: (v) => setState(() {
            if (v == true) {
              selectedIds.add(r.id);
            } else {
              selectedIds.remove(r.id);
            }
          }),
        ),
      ),
    );

    for (final ck in _visibleColList()) {
      switch (ck) {
        case ColKey.star:
          cells.add(
            DataCell(
              IconButton(
                icon: Icon(r.star ? Icons.star : Icons.star_border, color: Colors.amber.shade600),
                onPressed: () => _toggleStar(r),
                tooltip: r.star ? 'Unstar' : 'Star',
              ),
            ),
          );
          break;

        case ColKey.name:
          cells.add(
            DataCell(
              Row(
                children: [
                  // simple colored square (placeholder of icon)
                  Container(
                    width: 20,
                    height: 20,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: _typeBg(r.type),
                      border: Border.all(color: _typeColor(r.type)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Open: ${r.url}')),
                      );
                    },
                    child: Text(
                      r.name,
                      style: const TextStyle(color: Colors.indigo, decoration: TextDecoration.underline),
                    ),
                  ),
                ],
              ),
            ),
          );
          break;

        case ColKey.keyCol:
          cells.add(
            DataCell(
              Text(
                r.key,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
            ),
          );
          break;

        case ColKey.type:
          cells.add(
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _typeBg(r.type),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(r.type, style: TextStyle(color: _typeColor(r.type))),
              ),
            ),
          );
          break;

        case ColKey.lead:
          cells.add(
            DataCell(
              Row(
                children: [
                  CircleAvatar(
                    radius: 10,
                    backgroundColor: Colors.indigo.shade400,
                    child: Text(r.leadInitials, style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                  const SizedBox(width: 6),
                  Text(r.lead),
                ],
              ),
            ),
          );
          break;

        case ColKey.status:
          cells.add(
            DataCell(
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusBg(r.status),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(r.status, style: TextStyle(color: _statusColor(r.status))),
              ),
            ),
          );
          break;

        case ColKey.updatedAt:
          cells.add(DataCell(Text(_fmtDate(r.updatedAt), style: const TextStyle(color: Colors.black54))));
          break;

        case ColKey.url:
          cells.add(
            DataCell(
              PopupMenuButton<String>(
                tooltip: 'Actions',
                itemBuilder: (_) => [
                  const PopupMenuItem(value: 'open', child: Text('Open')),
                  const PopupMenuItem(value: 'copy', child: Text('Copy URL')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                  const PopupMenuDivider(),
                  PopupMenuItem(value: 'archive', child: Text(r.archived ? 'Unarchive' : 'Archive')),
                  const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red))),
                ],
                onSelected: (v) async {
                  switch (v) {
                    case 'open':
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open: ${r.url}')));
                      break;
                    case 'copy':
                      await Clipboard.setData(ClipboardData(text: r.url));
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Copied URL')));
                      }
                      break;
                    case 'rename':
                      await _renameSpace(r);
                      break;
                    case 'duplicate':
                      _duplicateSpace(r);
                      break;
                    case 'archive':
                      _toggleArchive(r);
                      break;
                    case 'delete':
                      _deleteSpace(r);
                      break;
                  }
                },
                child: const Icon(Icons.more_horiz),
              ),
            ),
          );
          break;
      }
    }

    return DataRow(
      selected: selectedIds.contains(r.id),
      cells: cells,
      onSelectChanged: (sel) {
        setState(() {
          if (sel == true) {
            selectedIds.add(r.id);
          } else {
            selectedIds.remove(r.id);
          }
        });
      },
    );
  }
}

/// =======================
/// Dialogs
/// =======================
class _ColumnsDialog extends StatefulWidget {
  const _ColumnsDialog({
    required this.labels,
    required this.visible,
    required this.onToggle,
  });

  final Map<ColKey, String> labels;
  final Set<ColKey> visible;
  final void Function(ColKey) onToggle;

  @override
  State<_ColumnsDialog> createState() => _ColumnsDialogState();
}

class _ColumnsDialogState extends State<_ColumnsDialog> {
  late Set<ColKey> temp;

  @override
  void initState() {
    super.initState();
    temp = Set.of(widget.visible);
  }

  bool get _hasDataCols => temp.any((k) =>
      k == ColKey.name ||
      k == ColKey.keyCol ||
      k == ColKey.type ||
      k == ColKey.lead ||
      k == ColKey.status ||
      k == ColKey.updatedAt);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Columns'),
      content: SizedBox(
        width: 260,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: ColKey.values
              .map(
                (c) => CheckboxListTile(
                  dense: true,
                  value: temp.contains(c),
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        temp.add(c);
                      } else {
                        temp.remove(c);
                        if (!_hasDataCols) {
                          // ensure at least one data column remains visible
                          temp.add(ColKey.name);
                        }
                      }
                    });
                  },
                  title: Text(widget.labels[c] ?? c.name),
                ),
              )
              .toList(),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(
          onPressed: () {
            // Apply
            for (final c in ColKey.values) {
              final before = widget.visible.contains(c);
              final after = temp.contains(c);
              if (before != after) widget.onToggle(c);
            }
            Navigator.pop(context);
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
}

class _DensityDialog extends StatelessWidget {
  const _DensityDialog({required this.current});
  final String current;

  @override
  Widget build(BuildContext context) {
    String value = current;
    return StatefulBuilder(builder: (context, setState) {
      return AlertDialog(
        title: const Text('Density'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile(
              value: 'middle',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Default'),
            ),
            RadioListTile(
              value: 'large',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Comfortable'),
            ),
            RadioListTile(
              value: 'small',
              groupValue: value,
              onChanged: (v) => setState(() => value = v!),
              title: const Text('Compact'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, value), child: const Text('Apply')),
        ],
      );
    });
  }
}
