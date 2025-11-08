import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class MaterialDetailsPage extends StatefulWidget {
  final String materialId;
  final String materialName;
  final String apiBase;
  final String userId;

  const MaterialDetailsPage({
    required this.materialId,
    required this.materialName,
    required this.apiBase,
    required this.userId,
    Key? key,
  }) : super(key: key);

  @override
  State<MaterialDetailsPage> createState() => _MaterialDetailsPageState();
}

class _MaterialDetailsPageState extends State<MaterialDetailsPage> {
  bool isLoading = false;
  List<Map<String, dynamic>> logs = [];

  final _deductQtyController = TextEditingController();
  final _deductReasonController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLogs();
  }

  Future<void> _fetchLogs() async {
    setState(() => isLoading = true);

    try {
      final res = await http.get(
        Uri.parse(
          '${widget.apiBase}/inventory/get_inventory_log.php?id=${widget.materialId}',
        ),
      );
      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        setState(() {
          logs = List<Map<String, dynamic>>.from(data['logs']);
        });
      } else {
        _showSnack("Failed to fetch logs: ${data['message']}");
      }
    } catch (e) {
      _showSnack("Error fetching logs: $e");
    }

    setState(() => isLoading = false);
  }

  Future<void> _deductStock() async {
    final qtyText = _deductQtyController.text.trim();
    final reason = _deductReasonController.text.trim();

    if (qtyText.isEmpty || reason.isEmpty) {
      _showSnack("Please enter both quantity and reason.");
      return;
    }

    try {
      final res = await http.post(
        Uri.parse('${widget.apiBase}/inventory/stock_out.php'),
        body: {
          'material_id': widget.materialId,
          'quantity': int.parse(qtyText).toString(),
          'reason': reason,
          'user_id': widget.userId,
        },
      );

      final data = jsonDecode(res.body);
      if (data['success'] == true) {
        _showSnack("✅ ${data['message']}");
        _deductQtyController.clear();
        _deductReasonController.clear();
        _fetchLogs();
      } else {
        _showSnack("⚠️ ${data['message']}");
      }
    } catch (e) {
      _showSnack("Error deducting stock: $e");
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.materialName),
        backgroundColor: Colors.orangeAccent,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: logs.isEmpty
                      ? const Center(child: Text("No logs available"))
                      : Center(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey[850],
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black54,
                                  blurRadius: 8,
                                  offset: Offset(2, 4),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              physics: const BouncingScrollPhysics(),
                              shrinkWrap: true,
                              itemCount: logs.length,
                              itemBuilder: (context, index) {
                                final log = logs[index];
                                final isOut = log['movement_type'] == 'OUT';
                                final isAuto = (log['reason'] ?? '')
                                    .toString()
                                    .toLowerCase()
                                    .contains('deduction');

                                return Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[800],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: ExpansionTile(
                                      leading: Icon(
                                        isOut
                                            ? Icons.remove_circle
                                            : Icons.add_box,
                                        color: isOut
                                            ? Colors.redAccent
                                            : Colors.greenAccent,
                                      ),
                                      title: Text(
                                        "${isOut ? '-' : '+'}${log['quantity']} ${log['unit']} (${log['movement_type']})",
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: isAuto
                                          ? const Text(
                                              "Auto-deduction from order",
                                              style: TextStyle(
                                                color: Colors.orangeAccent,
                                                fontSize: 12,
                                              ),
                                            )
                                          : null,
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(12),
                                          margin: const EdgeInsets.all(8),
                                          decoration: BoxDecoration(
                                            color: Colors.grey[700],
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              if (isOut)
                                                Text(
                                                  "Reason: ${log['reason'] ?? 'N/A'}",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              if (!isOut)
                                                Text(
                                                  "Expiration: ${log['expiration_date'] ?? 'N/A'}",
                                                  style: const TextStyle(
                                                    color: Colors.white70,
                                                  ),
                                                ),
                                              Text(
                                                "Logged by: ${log['user'] ?? 'N/A'}",
                                                style: const TextStyle(
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              if (log['timestamp'] != null)
                                                Text(
                                                  "Date: ${log['timestamp']}",
                                                  style: const TextStyle(
                                                    color: Colors.white54,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                ),

                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Deduct Stock",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _deductQtyController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: "Quantity",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _deductReasonController,
                        decoration: const InputDecoration(
                          labelText: "Reason",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _deductStock,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orangeAccent,
                          ),
                          child: const Text("Deduct Stock"),
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
