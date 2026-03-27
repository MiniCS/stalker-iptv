import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/app_state.dart';
import '../models/vod_item.dart';
import 'player_screen.dart';

class VodScreen extends StatefulWidget {
  const VodScreen({super.key});

  @override
  State<VodScreen> createState() => _VodScreenState();
}

class _VodScreenState extends State<VodScreen> {
  List<VodCategory> _categories = [];
  VodCategory? _selected;
  List<VodItem> _items = [];
  bool _loading = false;
  int _page = 1;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await context.read<AppState>().getVodCategories();
    setState(() => _categories = cats);
  }

  Future<void> _loadItems(VodCategory cat, {bool reset = false}) async {
    if (_loading) return;
    setState(() { _loading = true; if (reset) { _items = []; _page = 1; _hasMore = true; } });
    final state = context.read<AppState>();
    final result = await state.api.getVodItems(state.portal, state.mac, state.token, cat.id, _page);
    setState(() {
      _items.addAll(result.items);
      _hasMore = result.hasMore;
      _page++;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_selected == null) {
      return ListView.builder(
        itemCount: _categories.length,
        itemBuilder: (ctx, i) => ListTile(
          leading: const Icon(Icons.folder),
          title: Text(_categories[i].title),
          onTap: () {
            setState(() => _selected = _categories[i]);
            _loadItems(_categories[i], reset: true);
          },
        ),
      );
    }

    return Column(
      children: [
        ListTile(
          leading: const Icon(Icons.arrow_back),
          title: Text(_selected!.title),
          onTap: () => setState(() { _selected = null; _items = []; }),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _items.length + (_hasMore ? 1 : 0),
            itemBuilder: (ctx, i) {
              if (i == _items.length) {
                _loadItems(_selected!);
                return const Center(child: CircularProgressIndicator());
              }
              final item = _items[i];
              return GestureDetector(
                onTap: () async {
                  final state = context.read<AppState>();
                  final url = await state.getStreamUrl(item.cmd);
                  if (!context.mounted) return;
                  if (url == null) return;
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => PlayerScreen(title: item.name, streamUrl: url),
                  ));
                },
                child: Column(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.poster.isNotEmpty
                            ? CachedNetworkImage(imageUrl: item.poster, fit: BoxFit.cover,
                                errorWidget: (_, __, ___) => const Icon(Icons.movie, size: 40))
                            : const Icon(Icons.movie, size: 40),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(item.name, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 11)),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
