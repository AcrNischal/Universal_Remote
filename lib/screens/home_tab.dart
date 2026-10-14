import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../models/remote_model.dart';
import 'remote_explorer_screen.dart';

class HomeTab extends StatefulWidget {
  final Function(RemoteConfig) onRemoteSaved;

  const HomeTab({Key? key, required this.onRemoteSaved}) : super(key: key);

  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  final List<String> _allBrands = [
    'samsung', 'lg', 'sony', 'panasonic', 'philips',
    'toshiba', 'sharp', 'tcl', 'xiaomi', 'hisense',
    'yamaha', 'pioneer', 'denon', 'onkyo', 'sansui',
  ];

  late List<String> _randomizedBrands;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _randomizedBrands = List.from(_allBrands)..shuffle(Random());
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    // 3 items per row * 3 rows = 9 items initially visible
    final displayedBrands = _showAll ? _randomizedBrands : _randomizedBrands.take(9).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Universal Remote'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add Remote',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RemoteExplorerScreen(
                    onRemoteSaved: widget.onRemoteSaved,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                height: 190,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue.shade800, Colors.blueAccent.shade200],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        Icons.settings_remote,
                        size: 160,
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Smart IR Remote',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Control TV, AC, STB & more with your phone.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: Colors.blueAccent,
                              elevation: 2,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text('Add Remote', style: TextStyle(fontWeight: FontWeight.bold)),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => RemoteExplorerScreen(
                                    onRemoteSaved: widget.onRemoteSaved,
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Categories Quick Icons
            const Text(
              'Categories',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildCategoryCard(context, 'TV', Icons.tv, Colors.blue),
                _buildCategoryCard(context, 'AC', Icons.ac_unit, Colors.cyan),
                _buildCategoryCard(context, 'Audio', Icons.speaker, Colors.orange),
                _buildCategoryCard(context, 'STB', Icons.settings_input_antenna, Colors.purple),
              ],
            ),
            const SizedBox(height: 28),

            // Popular Brands Grid (3 in a row)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Popular Brands',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _randomizedBrands.shuffle(Random());
                    });
                  },
                  icon: const Icon(Icons.shuffle, size: 16),
                  label: const Text('Shuffle'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayedBrands.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.5, // Slightly rectangle (less height)
              ),
              itemBuilder: (context, index) {
                final brand = displayedBrands[index];
                final displayName = brand.toUpperCase();
                return InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => RemoteExplorerScreen(
                          onRemoteSaved: widget.onRemoteSaved,
                          initialSearchQuery: displayName,
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDarkMode ? Colors.grey[850] : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDarkMode ? Colors.grey[700]! : Colors.grey.shade300),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.03),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: isDarkMode ? Colors.grey[800] : Colors.grey.shade50,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: SvgPicture.asset(
                              'assets/popularbrands/$brand.svg',
                              placeholderBuilder: (context) => const Icon(Icons.business, color: Colors.blueAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: isDarkMode ? Colors.white70 : Colors.black87),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),

            // See More / See Less Brands Button
            if (_allBrands.length > 9)
              Center(
                child: TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _showAll = !_showAll;
                    });
                  },
                  icon: Icon(_showAll ? Icons.expand_less : Icons.expand_more),
                  label: Text(_showAll ? 'Show Less Brands' : 'See More Brands'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryCard(BuildContext context, String label, IconData icon, Color color) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RemoteExplorerScreen(
              onRemoteSaved: widget.onRemoteSaved,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 75,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: ButtonTheme(
          child: Column(
            children: [
              Icon(icon, color: color, size: 30),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: color, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}
