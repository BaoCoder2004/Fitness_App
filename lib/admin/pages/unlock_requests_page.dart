import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../domain/entities/unlock_request.dart';
import '../../domain/repositories/unlock_request_repository.dart';
import '../widgets/admin_layout.dart';

class UnlockRequestsPage extends StatefulWidget {
  const UnlockRequestsPage({super.key});

  @override
  State<UnlockRequestsPage> createState() => _UnlockRequestsPageState();
}

class _UnlockRequestsPageState extends State<UnlockRequestsPage> {
  String _filter = 'all';
  String _search = '';
  bool _submitting = false;

  @override
  Widget build(BuildContext context) {
    final repo = context.watch<UnlockRequestRepository>();
    return AdminLayout(
      title: 'Yêu cầu mở khóa',
      currentRoute: '/unlock-requests',
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFFF6F8FB),
        padding: EdgeInsets.fromLTRB(
          MediaQuery.of(context).size.width > 600 ? 20 : 12,
          20,
          MediaQuery.of(context).size.width > 600 ? 20 : 12,
          24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 700;
                if (isNarrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yêu cầu mở khóa',
                            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Quản lý các yêu cầu mở khóa tài khoản của người dùng.',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm email hoặc họ tên...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
                      ),
                      const SizedBox(height: 12),
                      Theme(
                        data: Theme.of(context).copyWith(
                          popupMenuTheme: const PopupMenuThemeData(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                            elevation: 6,
                            enableFeedback: true,
                            textStyle: TextStyle(color: Colors.black87),
                            labelTextStyle: MaterialStatePropertyAll(TextStyle(color: Colors.black87)),
                            menuPadding: EdgeInsets.zero,
                            position: PopupMenuPosition.over,
                            mouseCursor: MaterialStatePropertyAll(SystemMouseCursors.click),
                          ),
                        ),
                        child: PopupMenuButton<String>(
                          color: Colors.white,
                          offset: const Offset(0, 44),
                          constraints: const BoxConstraints(minWidth: 150, maxWidth: 200),
                          initialValue: _filter,
                          onSelected: (v) => setState(() => _filter = v),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          itemBuilder: (context) => const [
                            PopupMenuItem(value: 'all', child: Text('Tất cả')),
                            PopupMenuItem(value: 'pending', child: Text('Đang chờ')),
                            PopupMenuItem(value: 'approved', child: Text('Đã duyệt')),
                            PopupMenuItem(value: 'rejected', child: Text('Đã từ chối')),
                          ],
                          child: Container(
                            height: 40,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _filter == 'all'
                                        ? 'Tất cả'
                                        : _filter == 'pending'
                                            ? 'Đang chờ'
                                            : _filter == 'approved'
                                                ? 'Đã duyệt'
                                                : 'Đã từ chối',
                                    style: const TextStyle(fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                }
                return Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Yêu cầu mở khóa',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: Color(0xFF0F172A)),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Quản lý các yêu cầu mở khóa tài khoản của người dùng.',
                          style: TextStyle(fontSize: 13, color: Colors.black54),
                        ),
                      ],
                    ),
                    SizedBox(
                      width: 280,
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm email hoặc họ tên...',
                          prefixIcon: const Icon(Icons.search, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        onChanged: (value) => setState(() => _search = value.trim().toLowerCase()),
                      ),
                    ),
                    Theme(
                      data: Theme.of(context).copyWith(
                        popupMenuTheme: const PopupMenuThemeData(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                          elevation: 6,
                          enableFeedback: true,
                          textStyle: TextStyle(color: Colors.black87),
                          labelTextStyle: MaterialStatePropertyAll(TextStyle(color: Colors.black87)),
                          menuPadding: EdgeInsets.zero,
                          position: PopupMenuPosition.over,
                          mouseCursor: MaterialStatePropertyAll(SystemMouseCursors.click),
                        ),
                      ),
                      child: PopupMenuButton<String>(
                        color: Colors.white,
                        offset: const Offset(0, 44),
                        constraints: const BoxConstraints(minWidth: 180, maxWidth: 200),
                        initialValue: _filter,
                        onSelected: (v) => setState(() => _filter = v),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        itemBuilder: (context) => const [
                          PopupMenuItem(value: 'all', child: Text('Tất cả')),
                          PopupMenuItem(value: 'pending', child: Text('Đang chờ')),
                          PopupMenuItem(value: 'approved', child: Text('Đã duyệt')),
                          PopupMenuItem(value: 'rejected', child: Text('Đã từ chối')),
                        ],
                        child: Container(
                          height: 40,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _filter == 'all'
                                    ? 'Tất cả'
                                    : _filter == 'pending'
                                        ? 'Đang chờ'
                                        : _filter == 'approved'
                                            ? 'Đã duyệt'
                                            : 'Đã từ chối',
                                style: const TextStyle(fontSize: 14),
                              ),
                              const SizedBox(width: 6),
                              const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 18),
            Expanded(
              child: StreamBuilder<List<UnlockRequest>>(
                stream: repo.watchAllRequests(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final data = snapshot.data ?? [];
                  final filtered = data.where((e) {
                    final matchFilter = _filter == 'all' ? true : e.status == _filter;
                    final matchSearch = _search.isEmpty
                        ? true
                        : e.userEmail.toLowerCase().contains(_search) ||
                            e.userName.toLowerCase().contains(_search);
                    return matchFilter && matchSearch;
                  }).toList();

                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'Chưa có yêu cầu nào.',
                        style: TextStyle(fontSize: 14, color: Colors.black54),
                      ),
                    );
                  }

                  return Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: DataTableTheme(
                        data: DataTableThemeData(
                          headingRowColor: MaterialStateProperty.all(const Color(0xFFF4F6FA)),
                          dataRowColor: MaterialStateProperty.resolveWith<Color?>(
                            (states) => states.contains(MaterialState.hovered)
                                ? const Color(0xFFEEF2F7)
                                : null,
                          ),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minWidth: constraints.maxWidth,
                                ),
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.vertical,
                                  child: DataTable(
                                    headingRowHeight: 48,
                                    dataRowHeight: 60,
                                    columnSpacing: 28,
                                    horizontalMargin: 16,
                                    columns: const [
                                      DataColumn(label: Text('Email')),
                                      DataColumn(label: Text('Họ tên')),
                                      DataColumn(label: Text('Lý do')),
                                      DataColumn(label: Text('Trạng thái')),
                                      DataColumn(label: Text('Thời gian tạo')),
                                      DataColumn(label: Text('Thao tác')),
                                    ],
                                    rows: filtered.map((req) {
                                      return DataRow(
                                        cells: [
                                          DataCell(Text(req.userEmail)),
                                          DataCell(Text(req.userName)),
                                          DataCell(Text(req.reason?.isNotEmpty == true ? req.reason! : '-')),
                                          DataCell(_StatusBadge(status: req.status)),
                                          DataCell(Text(_formatDate(req.createdAt))),
                                          DataCell(_ActionButtons(
                                            req: req,
                                            submitting: _submitting,
                                            onApprove: () => _handleRequest(repo, req, true),
                                            onReject: () => _handleRequest(repo, req, false),
                                            onEdit: () => _showEditReason(req),
                                            onDelete: () => _deleteRequest(repo, req),
                                          )),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleRequest(
    UnlockRequestRepository repo,
    UnlockRequest req,
    bool approve,
  ) async {
    setState(() => _submitting = true);
    try {
      String? note;
      if (!approve && mounted) {
        note = await showDialog<String>(
          context: context,
          builder: (context) {
            final controller = TextEditingController();
            return AlertDialog(
              title: const Text('Nhập ghi chú từ chối'),
              content: TextField(
                controller: controller,
                decoration: const InputDecoration(labelText: 'Ghi chú'),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(null),
                  child: const Text('Huỷ'),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(controller.text.trim()),
                  child: const Text('Lưu'),
                ),
              ],
            );
          },
        );
        if (note == null) {
          setState(() => _submitting = false);
          return;
        }
      }

      await repo.updateRequestStatus(
        requestId: req.id,
        status: approve ? 'approved' : 'rejected',
        adminNote: note,
        processedBy: 'admin',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(approve ? 'Đã duyệt yêu cầu' : 'Đã từ chối yêu cầu'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi xử lý: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatDate(DateTime time) {
    final local = time.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  }

  Future<void> _showEditReason(UnlockRequest req) async {
    final controller = TextEditingController(text: req.reason ?? '');
    final noteController = TextEditingController(text: req.adminNote ?? '');
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'Chỉnh sửa yêu cầu',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Cập nhật lý do và ghi chú quản trị viên.',
                            style: TextStyle(fontSize: 13, color: Colors.black54),
                          ),
                        ],
                      ),
                      Icon(Icons.edit_note, color: Colors.deepPurple.shade400),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: controller,
                    readOnly: true,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú (user)',
                      hintText: 'Chỉ đọc',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: noteController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: 'Ghi chú admin',
                      hintText: 'Thêm ghi chú nội bộ (tuỳ chọn)',
                      filled: true,
                      fillColor: const Color(0xFFF5F7FB),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        ),
                        child: const Text('Huỷ'),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          backgroundColor: Colors.deepPurple.shade500,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Lưu', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    if (result == true) {
      try {
        await context.read<UnlockRequestRepository>().updateRequestStatus(
              requestId: req.id,
              status: req.status,
              adminNote: noteController.text.trim().isEmpty ? null : noteController.text.trim(),
              processedBy: 'admin',
            );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Đã lưu chỉnh sửa')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi lưu: $e')),
        );
      }
    }
  }

  Future<void> _deleteRequest(UnlockRequestRepository repo, UnlockRequest req) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xoá yêu cầu'),
        content: const Text('Bạn có chắc muốn xoá yêu cầu này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Huỷ'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Xoá'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    try {
      // Dù rules đang chặn delete, yêu cầu đã nêu cần chức năng xoá: gọi delete
      await repo.deleteRequest(req.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Đã xoá yêu cầu')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xoá: $e')),
      );
    }
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final color = {
      'approved': const Color(0xFF22C55E),
      'rejected': const Color(0xFFEF4444),
      'pending': const Color(0xFFF97316),
    }[status]!;
    final text = {
      'approved': 'Đã duyệt',
      'rejected': 'Đã từ chối',
      'pending': 'Đang chờ',
    }[status]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.req,
    required this.submitting,
    required this.onApprove,
    required this.onReject,
    required this.onEdit,
    required this.onDelete,
  });

  final UnlockRequest req;
  final bool submitting;
  final VoidCallback onApprove;
  final VoidCallback onReject;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    if (req.status == 'pending') {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: submitting ? null : onApprove,
            child: const Text('Duyệt'),
          ),
          TextButton(
            onPressed: submitting ? null : onReject,
            child: const Text('Từ chối'),
          ),
          IconButton(
            tooltip: 'Chỉnh sửa',
            icon: const Icon(Icons.edit, size: 18),
            onPressed: submitting ? null : onEdit,
          ),
          IconButton(
            tooltip: 'Xoá',
            icon: const Icon(Icons.delete_outline, size: 18),
            onPressed: submitting ? null : onDelete,
          ),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          req.status == 'approved' ? 'Đã duyệt' : 'Đã từ chối',
          style: const TextStyle(color: Colors.black54),
        ),
        IconButton(
          tooltip: 'Chỉnh sửa ghi chú',
          icon: const Icon(Icons.edit, size: 18),
          onPressed: submitting ? null : onEdit,
        ),
        IconButton(
          tooltip: 'Xoá',
          icon: const Icon(Icons.delete_outline, size: 18),
          onPressed: submitting ? null : onDelete,
        ),
      ],
    );
  }
}

