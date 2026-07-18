import 'package:flutter/material.dart';
import 'package:plately_app/core/services/api_service.dart';
import 'package:plately_app/core/services/auth_helper.dart';

class SquadScreen extends StatefulWidget {
  const SquadScreen({super.key});

  @override
  State<SquadScreen> createState() => _SquadScreenState();
}

class _SquadScreenState extends State<SquadScreen> {
  bool _loading = true;
  List<dynamic> _squads = [];
  Map<String, List<dynamic>> _leaderboards = {};

  final _inviteController = TextEditingController();
  final _createController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final squads = await ApiService().getMySquads();
      
      final leaderboards = <String, List<dynamic>>{};
      for (final squad in squads) {
        final lb = await ApiService().getSquadLeaderboard(squad['id']);
        leaderboards[squad['id']] = lb;
      }
      
      if (!mounted) return;
      setState(() {
        _squads = squads;
        _leaderboards = leaderboards;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to load squads: $e')));
    }
  }

  Future<void> _createSquad() async {
    if (_createController.text.isEmpty) return;
    try {
      await ApiService().createSquad(_createController.text);
      _createController.clear();
      _loadData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _joinSquad() async {
    if (_inviteController.text.isEmpty) return;
    try {
      await ApiService().joinSquad(_inviteController.text);
      _inviteController.clear();
      _loadData();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _showCreateOrJoinDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Squads'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _createController,
              decoration: const InputDecoration(labelText: 'Create New Squad Name', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _createSquad, child: const Text('Create')),
            const Divider(height: 32),
            TextField(
              controller: _inviteController,
              decoration: const InputDecoration(labelText: 'Enter Invite Code', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 8),
            ElevatedButton(onPressed: _joinSquad, child: const Text('Join')),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Squads'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _showCreateOrJoinDialog,
          )
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _squads.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.group, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('You are not in any squads.'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _showCreateOrJoinDialog,
                        child: const Text('Join or Create a Squad'),
                      )
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _squads.length,
                  itemBuilder: (ctx, i) {
                    final squad = _squads[i];
                    final leaderboard = _leaderboards[squad['id']] ?? [];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(squad['name'], style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text('Code: ${squad['invite_code']}', style: TextStyle(fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.onPrimaryContainer)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text('Leaderboard', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 8),
                            ...leaderboard.map((user) {
                              final isMe = user['user_id'] == currentUserId();
                              return ListTile(
                                leading: CircleAvatar(
                                  backgroundImage: user['avatar_url'] != null ? NetworkImage(user['avatar_url']) : null,
                                  child: user['avatar_url'] == null ? Text(user['name'][0]) : null,
                                ),
                                title: Text(user['name'], style: TextStyle(fontWeight: isMe ? FontWeight.bold : FontWeight.normal)),
                                subtitle: Text('Lvl ${user['level']} • ${user['total_xp']} XP'),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.local_fire_department, color: Colors.orange, size: 16),
                                    Text(' ${user['cooking_streak']}'),
                                    const SizedBox(width: 8),
                                    const Icon(Icons.eco, color: Colors.green, size: 16),
                                    Text(' ${user['items_saved']}'),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
