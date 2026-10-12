import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import '../services/ir_parser_service.dart';
import 'remote_screen.dart';

class RemoteExplorerScreen extends StatefulWidget {
  final Function(RemoteConfig) onRemoteSaved;

  const RemoteExplorerScreen({Key? key, required this.onRemoteSaved}) : super(key: key);

  @override
  State<RemoteExplorerScreen> createState() => _RemoteExplorerScreenState();
}

class _RemoteExplorerScreenState extends State<RemoteExplorerScreen> {
  late Future<List<ManufacturerGroup>> _remotesFuture;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';

  final List<Map<String, dynamic>> _categories = [
    {'name': 'ALL', 'icon': Icons.devices},
    {'name': 'TV', 'icon': Icons.tv},
    {'name': 'AC', 'icon': Icons.ac_unit},
    {'name': 'AUDIO', 'icon': Icons.speaker},
    {'name': 'STB', 'icon': Icons.settings_input_antenna},
    {'name': 'DVD', 'icon': Icons.disc_full},
  ];

  @override
  void initState() {
    super.initState();
    _remotesFuture = IrParserService.loadAllRemotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Remote'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<ManufacturerGroup>>(
        future: _remotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error loading remotes: ${snapshot.error}'));
          }

          final data = snapshot.data;
          if (data == null || data.isEmpty) {
            return const Center(child: Text('No remotes found'));
          }

          // Filter groups by search query and category
          final filteredGroups = data.where((group) {
            final query = _searchQuery.toLowerCase();
            final matchesMfr = group.manufacturer.toLowerCase().contains(query);
            final matchesModel = group.models.any((m) => m.name.toLowerCase().contains(query));
            
            // Category filter check
            bool matchesCategory = true;
            if (_selectedCategory != 'ALL') {
              final cat = _selectedCategory.toLowerCase();
              final folderName = group.manufacturer.toLowerCase();
              matchesCategory = folderName.contains(cat) || group.models.any((m) => m.name.toLowerCase().contains(cat));
            }

            return (matchesMfr || matchesModel) && matchesCategory;
          }).toList();

          return Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.all(12.0),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'Search manufacturer or model...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Category Icons Row
              SizedBox(
                height: 60,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Row(
                          children: [
                            Icon(cat['icon'], size: 18, color: isSelected ? Colors.white : Colors.blueAccent),
                            const SizedBox(width: 6),
                            Text(cat['name']),
                          ],
                        ),
                        selectedColor: Colors.blueAccent,
                        labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black87),
                        onSelected: (selected) {
                          setState(() => _selectedCategory = cat['name']);
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1),

              // Manufacturer & Model List
              Expanded(
                child: filteredGroups.isEmpty
                    ? const Center(child: Text('No matching remotes found'))
                    : ListView.builder(
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          return ExpansionTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              child: const Icon(Icons.folder, color: Colors.blueAccent),
                            ),
                            title: Text(
                              group.manufacturer,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text('${group.models.length} model(s)'),
                            children: group.models.map((model) {
                              return ListTile(
                                contentPadding: const EdgeInsets.only(left: 32, right: 16),
                                title: Text(model.name),
                                subtitle: Text('Protocol: ${model.protocol}'),
                                trailing: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  ),
                                  icon: const Icon(Icons.bookmark_add, size: 16),
                                  label: const Text('Save'),
                                  onPressed: () {
                                    widget.onRemoteSaved(model);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Saved ${model.name} to your remotes!')),
                                    );
                                  },
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => RemoteScreen(remoteConfig: model),
                                    ),
                                  );
                                },
                              );
                            }).toList(),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
