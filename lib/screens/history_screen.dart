import 'package:flutter/material.dart';
import '../models/activity_model.dart';
import '../repositories/activity_repository.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final ActivityRepository _repository = ActivityRepository();

  List<ActivityModel> _allActivities = [];
  List<ActivityModel> _filteredActivities = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  // 1. Fetch Data from API
  Future<void> _fetchData() async {
    List<ActivityModel> data = await _repository.fetchActivities();
    setState(() {
      _allActivities = data;
      _filteredActivities = data;
      _isLoading = false;
    });
  }

  // 2. Search Logic
  void _runSearch(String keyword) {
    if (keyword.isEmpty) {
      setState(() => _filteredActivities = _allActivities);
      return;
    }

    setState(() {
      _filteredActivities = _allActivities.where((item) {
        // Search by Date or Latitude
        return item.timestamp.toString().contains(keyword) ||
            item.latitude.toString().contains(keyword);
      }).toList();
    });
  }

  // 3. Delete Logic
  Future<void> _deleteItem(String id) async {
    bool success = await _repository.deleteActivity(id);
    if (success) {
      setState(() {
        _allActivities.removeWhere((item) => item.id == id);
        _filteredActivities.removeWhere((item) => item.id == id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Entry deleted successfully")),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to delete item")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Activity History"),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- Search Bar ---
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: TextField(
              controller: _searchController,
              onChanged: _runSearch,
              decoration: InputDecoration(
                labelText: 'Search (Date or Location)',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          // --- List View ---
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredActivities.isEmpty
                ? const Center(child: Text("No records found."))
                : ListView.builder(
              itemCount: _filteredActivities.length,
              itemBuilder: (context, index) {
                final item = _filteredActivities[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  child: ListTile(
                    leading: SizedBox(
                      width: 50, height: 50,
                      child: item.imagePath.isNotEmpty
                          ? Image.network(
                        item.imagePath, // URL from server
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image),
                      )
                          : const Icon(Icons.image_not_supported),
                    ),
                    title: Text("Lat: ${item.latitude.toStringAsFixed(4)}"),
                    subtitle: Text(item.timestamp.toString().split('.')[0]),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => _deleteItem(item.id ?? ''),
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
}