import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import '../services/ir_parser_service.dart';
import 'remote_screen.dart';

class RemoteExplorerScreen extends StatefulWidget {
  final Function(RemoteConfig) onRemoteSaved;
  final String? initialSearchQuery;

  const RemoteExplorerScreen({
    Key? key,
    required this.onRemoteSaved,
    this.initialSearchQuery,
  }) : super(key: key);

  @override
  State<RemoteExplorerScreen> createState() => _RemoteExplorerScreenState();
}

class _RemoteExplorerScreenState extends State<RemoteExplorerScreen> {
  late Future<List<ManufacturerGroup>> _remotesFuture;
  String _searchQuery = '';
  String _selectedCategory = 'ALL';
  String? _expandedManufacturer;
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'ALL', 'icon': Icons.devices_other},
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
    if (widget.initialSearchQuery != null && widget.initialSearchQuery!.isNotEmpty) {
      _searchQuery = widget.initialSearchQuery!;
      _searchController.text = _searchQuery;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.initialSearchQuery != null ? '${widget.initialSearchQuery} Remotes' : 'Explore Remotes'),
        elevation: 0,
      ),
      body: FutureBuilder<List<ManufacturerGroup>>(
        future: _remotesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Loading 1,600+ IR remotes...', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No remotes found.'));
          }

          final allGroups = snapshot.data!;

          List<ManufacturerGroup> categoryFiltered = allGroups;
          if (_selectedCategory != 'ALL') {
            categoryFiltered = allGroups.where((group) {
              return group.models.any((model) {
                final nameUpper = model.name.toUpperCase();
                final mfrUpper = group.manufacturer.toUpperCase();
                if (_selectedCategory == 'TV') {
                  return nameUpper.contains('TV') || mfrUpper.contains('SAMSUNG') || mfrUpper.contains('LG') || mfrUpper.contains('SONY');
                } else if (_selectedCategory == 'AC') {
                  return nameUpper.contains('AC') || nameUpper.contains('CLIMATE') || nameUpper.contains('AIR');
                } else if (_selectedCategory == 'AUDIO') {
                  return nameUpper.contains('AUDIO') || nameUpper.contains('SOUND') || nameUpper.contains('AMP') || mfrUpper.contains('YAMAHA') || mfrUpper.contains('DENON');
                } else if (_selectedCategory == 'STB') {
                  return nameUpper.contains('STB') || nameUpper.contains('BOX') || nameUpper.contains('TUNER');
                } else if (_selectedCategory == 'DVD') {
                  return nameUpper.contains('DVD') || nameUpper.contains('BLURAY');
                }
                return true;
              });
            }).toList();
          }

          final query = _searchQuery.toLowerCase();
          final filteredGroups = categoryFiltered.map((group) {
            if (query.isEmpty) return group;
            final matchesMfr = group.manufacturer.toLowerCase().contains(query);
            final matchingModels = group.models.where((m) => m.name.toLowerCase().contains(query) || m.manufacturer.toLowerCase().contains(query)).toList();
            if (matchesMfr) return group;
            if (matchingModels.isNotEmpty) {
              return ManufacturerGroup(manufacturer: group.manufacturer, models: matchingModels);
            }
            return null;
          }).whereType<ManufacturerGroup>().toList();

          return Column(
            children: [
              // Modern Search Bar
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                color: Theme.of(context).cardColor,
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search brand or model (e.g. Samsung, LG)...',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: Colors.blueAccent),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              setState(() {
                                _searchQuery = '';
                                _searchController.clear();
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey.withOpacity(0.1),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                  onChanged: (value) => setState(() => _searchQuery = value),
                ),
              ),

              // Modern Category Filter Chips (Fixed checkmark/avatar overlap)
              Container(
                height: 60,
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat['name'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        selected: isSelected,
                        showCheckmark: true,
                        checkmarkColor: Colors.white,
                        // Avoid avatar & checkmark overlap when selected
                        avatar: isSelected
                            ? null
                            : Icon(
                                cat['icon'],
                                size: 16,
                                color: Colors.blueAccent,
                              ),
                        label: Text(cat['name']),
                        labelStyle: TextStyle(
                          color: isSelected ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white70 : Colors.black87),
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                        backgroundColor: Colors.grey.withOpacity(0.1),
                        selectedColor: Colors.blueAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        onSelected: (selected) {
                          setState(() {
                            _selectedCategory = cat['name'];
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const Divider(height: 1, thickness: 1),

              // Modern Manufacturer & Model List (Accordion expansion behavior)
              Expanded(
                child: filteredGroups.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            const Text(
                              'No matching remotes found',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredGroups.length,
                        itemBuilder: (context, index) {
                          final group = filteredGroups[index];
                          final isExpanded = _expandedManufacturer == group.manufacturer;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            decoration: BoxDecoration(
                              color: Theme.of(context).cardColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.withOpacity(0.15)),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ExpansionTile(
                              key: Key(group.manufacturer),
                              initiallyExpanded: isExpanded,
                              onExpansionChanged: (expanded) {
                                setState(() {
                                  _expandedManufacturer = expanded ? group.manufacturer : null;
                                });
                              },
                              tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.folder_outlined, color: Colors.blueAccent),
                              ),
                              title: Text(
                                group.manufacturer,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              subtitle: Text(
                                '${group.models.length} model(s) available',
                                style: TextStyle(color: Colors.grey[600], fontSize: 13),
                              ),
                              children: group.models.map((model) {
                                return Container(
                                  margin: const EdgeInsets.only(top: 8),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.grey.withOpacity(0.05),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              model.name,
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                            ),
                                            const SizedBox(height: 4),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.blueAccent.withOpacity(0.1),
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Text(
                                                'Protocol: ${model.protocol}',
                                                style: const TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.blueAccent,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) => RemoteScreen(remoteConfig: model),
                                            ),
                                          );
                                        },
                                        child: const Text('Use', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                      const SizedBox(width: 6),
                                      OutlinedButton(
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green,
                                          side: const BorderSide(color: Colors.green),
                                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        onPressed: () {
                                          widget.onRemoteSaved(model);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text('Saved "${model.name}" to My Remotes!')),
                                          );
                                        },
                                        child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
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
