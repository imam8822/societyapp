import 'package:flutter/material.dart';
import 'package:societyapp/core/app_utils.dart';
import 'package:intl/intl.dart';
import '../../core/api/api_services.dart';
import '../../models/leave_request_models.dart';
import '../../core/constants.dart';
import '../../widgets/shared_widgets.dart';

class AdminLeaveRequestsScreen extends StatefulWidget {
  const AdminLeaveRequestsScreen({super.key});

  @override
  State<AdminLeaveRequestsScreen> createState() => _AdminLeaveRequestsScreenState();
}

class _AdminLeaveRequestsScreenState extends State<AdminLeaveRequestsScreen> {
  final List<LeaveRequestDto> _requests = [];
  bool _loading = false;
  bool _hasMore = true;
  int _page = 1;
  final int _limit = 20;

  @override
  void initState() {
    super.initState();
    _loadRequests();
  }

  Future<void> _loadRequests({bool refresh = false}) async {
    if (refresh) {
      _page = 1;
      _hasMore = true;
      _requests.clear();
    }

    if (!_hasMore || _loading) return;
    setState(() => _loading = true);

    try {
      final items = await LeaveRequestApi.getLeaveRequests(page: _page, limit: _limit);
      setState(() {
        if (items.length < _limit) _hasMore = false;
        _requests.addAll(items);
        _page++;
      });
    } catch (e) {
      if (mounted) AppUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showProcessDialog(LeaveRequestDto req) {
    bool isApprove = true;
    final remarksCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateSB) => AlertDialog(
          title: const Text('Process Leave Request'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('User: ${req.userName}'),
              Text('Invested: ₹${req.totalInvested}'),
              if (req.refundAmount != null)
                Text('Refund Amount: ₹${req.refundAmount}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              const SizedBox(height: 16),
              Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: isApprove,
                    onChanged: (val) => setStateSB(() => isApprove = val!),
                  ),
                  const Text('Approve'),
                  Radio<bool>(
                    value: false,
                    groupValue: isApprove,
                    onChanged: (val) => setStateSB(() => isApprove = val!),
                  ),
                  const Text('Reject'),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: remarksCtrl,
                decoration: const InputDecoration(labelText: 'Remarks (Optional)'),
                maxLines: 2,
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(ctx);
                try {
                  await LeaveRequestApi.processLeaveRequest(req.id, isApprove, remarksCtrl.text);
                  _loadRequests(refresh: true);
                } catch (e) {
                  if (mounted) AppUtils.showError(this.context, e.toString());
                }
              },
              child: const Text('Submit'),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.bgGrey,
      appBar: AppBar(title: const Text('Leave Requests')),
      body: _requests.isEmpty && _loading
          ? Center(child: CircularProgressIndicator(color: context.colors.primary))
          : _requests.isEmpty
              ? const EmptyState(icon: Icons.exit_to_app, title: 'No leave requests')
              : RefreshIndicator(
                  onRefresh: () => _loadRequests(refresh: true),
                  color: context.colors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _requests.length + (_hasMore ? 1 : 0),
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      if (index == _requests.length) {
                        _loadRequests();
                        return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
                      }
                      final req = _requests[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: context.colors.surfaceWhite,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: context.colors.divider),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(req.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: req.status == 'Pending' ? Colors.orange.withOpacity(0.2) : req.status == 'Approved' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(req.status, style: TextStyle(
                                    color: req.status == 'Pending' ? Colors.orange : req.status == 'Approved' ? Colors.green : Colors.red,
                                    fontSize: 12, fontWeight: FontWeight.bold,
                                  )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Reason: ${req.reason}', style: TextStyle(color: context.colors.textDark)),
                            const SizedBox(height: 4),
                            Text('Total Invested: ₹${req.totalInvested}', style: TextStyle(color: context.colors.textGrey)),
                            if (req.refundAmount != null)
                              Text('Refund Amount: ₹${req.refundAmount}', style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(DateFormat('d MMM yyyy').format(req.requestedAt), style: TextStyle(color: context.colors.textGrey, fontSize: 12)),
                                if (req.status == 'Pending')
                                  ElevatedButton(
                                    onPressed: () => _showProcessDialog(req),
                                    style: ElevatedButton.styleFrom(visualDensity: VisualDensity.compact),
                                    child: const Text('Process'),
                                  )
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
