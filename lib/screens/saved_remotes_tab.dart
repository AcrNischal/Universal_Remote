import 'package:flutter/material.dart';
import '../models/remote_model.dart';
import 'remote_screen.dart';

class SavedRemotesTab extends StatelessWidget {
  final List<RemoteConfig> savedRemotes;
  final Function(RemoteConfig) onRemoveRemote;
  final Function(RemoteConfig, RemoteConfig) onRemoteUpdated;

  const SavedRemotesTab({
    Key? key,
    required this.savedRemotes,
    required this.onRemoveRemote,
    required this.onRemoteUpdated,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Remotes'),
      ),
      body: savedRemotes.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.tv_off, size: 64, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    const Text(
                      'No saved remotes yet.',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Explore remotes from the Home tab and tap "Save" to keep them here for quick access.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: savedRemotes.length,
              itemBuilder: (context, index) {
                final remote = savedRemotes[index];
                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      backgroundColor: Colors.blueAccent.withOpacity(0.1),
                      child: const Icon(Icons.settings_remote, color: Colors.blueAccent),
                    ),
                    title: Text(remote.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${remote.manufacturer} | Protocol: ${remote.protocol}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => onRemoveRemote(remote),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => RemoteScreen(
                            remoteConfig: remote,
                            onRemoteUpdated: (updated) => onRemoteUpdated(remote, updated),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
    );
  }
}
