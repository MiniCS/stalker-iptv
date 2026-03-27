import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/channel.dart';
import 'player_screen.dart';
import 'vod_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0;
  String _search = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppState>().loadChannels();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _tab == 0
            ? TextField(
                decoration: const InputDecoration(
                  hintText: 'Hledat kanál...',
                  border: InputBorder.none,
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() => _search = v),
              )
            : const Text('VOD'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => context.read<AppState>().logout(),
          ),
        ],
      ),
      body: _tab == 0 ? _ChannelList(search: _search) : const VodScreen(),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.live_tv), label: 'Kanály'),
          NavigationDestination(icon: Icon(Icons.movie), label: 'VOD'),
        ],
      ),
    );
  }
}

class _ChannelList extends StatelessWidget {
  final String search;
  const _ChannelList({required this.search});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();

    if (state.loadingChannels) {
      return const Center(child: CircularProgressIndicator());
    }

    final channels = search.isEmpty
        ? state.channels
        : state.channels.where((c) => c.name.toLowerCase().contains(search.toLowerCase())).toList();

    if (channels.isEmpty) {
      return const Center(child: Text('Žádné kanály'));
    }

    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (ctx, i) => _ChannelTile(channel: channels[i]),
    );
  }
}

class _ChannelTile extends StatelessWidget {
  final Channel channel;
  const _ChannelTile({required this.channel});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: SizedBox(
        width: 50,
        height: 35,
        child: channel.logo.isNotEmpty
            ? CachedNetworkImage(
                imageUrl: channel.logo,
                fit: BoxFit.contain,
                errorWidget: (_, __, ___) => const Icon(Icons.tv),
              )
            : const Icon(Icons.tv),
      ),
      title: Text(channel.name),
      subtitle: channel.genreTitle.isNotEmpty ? Text(channel.genreTitle) : null,
      trailing: channel.hasArchive ? const Icon(Icons.history, size: 16, color: Colors.blue) : null,
      onTap: () async {
        final state = context.read<AppState>();
        final url = await state.getStreamUrl(channel.cmd);
        if (!context.mounted) return;
        if (url == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Nepodařilo se načíst stream')),
          );
          return;
        }
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PlayerScreen(title: channel.name, streamUrl: url)),
        );
      },
    );
  }
}
