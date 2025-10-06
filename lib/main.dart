import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

/// Simple Character model for Rick & Morty API
class Character {
  final int id;
  final String name;
  final String status;
  final String species;
  final String image;

  Character({
    required this.id,
    required this.name,
    required this.status,
    required this.species,
    required this.image,
  });

  factory Character.fromJson(Map<String, dynamic> json) {
    return Character(
      id: json['id'] as int,
      name: json['name'] as String,
      status: json['status'] as String,
      species: json['species'] as String,
      image: json['image'] as String,
    );
  }
}

/// Fetch characters; if [nameQuery] provided, API filters by name.
Future<List<Character>> fetchCharacters({String? nameQuery}) async {
  final baseUrl = 'https://rickandmortyapi.com/api/character';
  final uri = (nameQuery == null || nameQuery.trim().isEmpty)
      ? Uri.parse(baseUrl)
      : Uri.parse('$baseUrl/?name=${Uri.encodeQueryComponent(nameQuery.trim())}');

  final res = await http.get(uri);

  if (res.statusCode == 200) {
    final Map<String, dynamic> jsonBody = json.decode(res.body);
    final results = jsonBody['results'] as List<dynamic>;
    return results.map((e) => Character.fromJson(e as Map<String, dynamic>)).toList();
  } else if (res.statusCode == 404) {
    
    return [];
  } else {
    throw Exception('Failed to load characters (status ${res.statusCode})');
  }
}

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Solo 3 - Fetch & Display',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const CharacterListPage(),
    );
  }
}

class CharacterListPage extends StatefulWidget {
  const CharacterListPage({super.key});

  @override
  State<CharacterListPage> createState() => _CharacterListPageState();
}

class _CharacterListPageState extends State<CharacterListPage> {
  late Future<List<Character>> _futureCharacters;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _futureCharacters = fetchCharacters();
  }

  Future<void> _load({String? name}) async {
    setState(() {
      _errorMessage = null;
      _isSearching = true;
      _futureCharacters = fetchCharacters(nameQuery: name);
    });

    try {

      await _futureCharacters;
    } catch (e) {
      // store an error message so UI shows retry
      setState(() {
        _errorMessage = e.toString();
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _refresh() async {
    await _load(name: _searchQuery.isEmpty ? null : _searchQuery);
  }

  void _onSearchSubmitted(String value) {
    setState(() {
      _searchQuery = value;
    });
    _load(name: value);
  }

  void _onClearSearch() {
    _searchController.clear();
    setState(() {
      _searchQuery = '';
    });
    _load(name: null);
  }

  Widget _buildList(List<Character> characters) {
    if (characters.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox, size: 56, semanticLabel: 'Empty'),
            const SizedBox(height: 12),
            const Text(
              'No characters found.',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            )
          ],
        ),
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(12),
      itemCount: characters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final c = characters[index];
        return Semantics(
          container: true,
          label: 'Character: ${c.name}, ${c.species}, status ${c.status}',
          child: Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
            child: ListTile(
              contentPadding: const EdgeInsets.all(8.0),
              leading: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  c.image,
                  width: 64,
                  height: 64,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return SizedBox(
                      width: 64,
                      height: 64,
                      child: Center(child: CircularProgressIndicator(value: progress.expectedTotalBytes != null ? progress.cumulativeBytesLoaded / (progress.expectedTotalBytes as num) : null)),
                    );
                  },
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey[200],
                    child: const Icon(Icons.broken_image),
                  ),
                ),
              ),
              title: Text(c.name),
              subtitle: Text('${c.species} • ${c.status}'),
              trailing: IconButton(
                onPressed: () {

                  showModalBottomSheet(
                    context: context,
                    builder: (context) => Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(c.name, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Text('Species: ${c.species}'),
                        Text('Status: ${c.status}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Close'),
                        )
                      ]),
                    ),
                  );
                },
                tooltip: 'Show details',
                icon: const Icon(Icons.info_outline),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody() {
    // If there's an error message from fetch attempt, show an error state with retry
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off, size: 64),
              const SizedBox(height: 12),
              Text('Failed to load characters.', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                style: const TextStyle(color: Colors.redAccent),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => _load(name: _searchQuery.isEmpty ? null : _searchQuery),
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }


    return FutureBuilder<List<Character>>(
      future: _futureCharacters,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || _isSearching) {
          // Loading spinner UI
          return const Center(
            child: CircularProgressIndicator(semanticsLabel: 'Loading characters'),
          );
        } else if (snapshot.hasError) {
          // Unexpected error
          return Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.error_outline, size: 56),
                const SizedBox(height: 12),
                const Text('An error occurred'),
                const SizedBox(height: 8),
                Text(snapshot.error.toString(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.redAccent)),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () => _load(name: _searchQuery.isEmpty ? null : _searchQuery),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                )
              ]),
            ),
          );
        } else if (snapshot.hasData) {
          
          return RefreshIndicator(
            onRefresh: _refresh,
            child: _buildList(snapshot.data!),
          );
        } else {
          return const Center(child: Text('No data'));
        }
      },
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onSubmitted: _onSearchSubmitted,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: 'Search characters by name (e.g. Rick)',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                isDense: true,
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: _onClearSearch,
                  tooltip: 'Clear search',
                )
                    : null,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () => _onSearchSubmitted(_searchController.text),
            child: const Text('Search'),
          )
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = _searchQuery.isEmpty ? 'Characters' : 'Search: "$_searchQuery"';
    return Scaffold(
      appBar: AppBar(
        title: Text('Solo 3 — Fetch & Display'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => _load(name: _searchQuery.isEmpty ? null : _searchQuery),
            icon: const Icon(Icons.refresh),
          )
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }
}
