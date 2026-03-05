import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:on_audio_query/on_audio_query.dart';

void main() => runApp(const RetroAudioApp());

class RetroAudioApp extends StatefulWidget {
  const RetroAudioApp({super.key});
  @override
  State<RetroAudioApp> createState() => _RetroAudioAppState();
}

class _RetroAudioAppState extends State<RetroAudioApp> {
  bool isDarkMode = false;
  
  @override
  Widget build(BuildContext context) {
    // Cores: Bege/Off-white e Cinza
    final Color bgColor = isDarkMode ? const Color(0xFF2E2E2E) : const Color(0xFFF5F5DC);
    final Color textColor = isDarkMode ? const Color(0xFFF5F5DC) : const Color(0xFF808080);

    return MaterialApp(
      title: 'SOUND BIT',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: bgColor,
        fontFamily: 'monospace', 
      ),
      home: HomeScreen(
        textColor: textColor, 
        isDarkMode: isDarkMode,
        toggleTheme: () => setState(() => isDarkMode = !isDarkMode)
      ),
    );
  }
}

class HomeScreen extends StatefulWidget {
  final Color textColor;
  final bool isDarkMode;
  final VoidCallback toggleTheme;
  const HomeScreen({super.key, required this.textColor, required this.toggleTheme, required this.isDarkMode});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  final OnAudioQuery _audioQuery = OnAudioQuery();
  final AudioPlayer _player = AudioPlayer();

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      _buildMusicList(),
      Center(child: Text("PLAYLISTS", style: TextStyle(color: widget.textColor))),
      Center(child: Text("FAVORITAS", style: TextStyle(color: widget.textColor))),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("SOUND BIT", style: TextStyle(color: widget.textColor, fontSize: 16, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: widget.textColor),
            onPressed: () => _showSettings(context),
          )
        ],
      ),
      body: pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        currentIndex: _selectedIndex,
        selectedItemColor: widget.textColor,
        unselectedItemColor: widget.textColor.withOpacity(0.3),
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.music_note), label: 'MÚSICAS'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'PLAYLISTS'),
          BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'FAVORITAS'),
        ],
      ),
    );
  }

  Widget _buildMusicList() {
    return FutureBuilder<List<SongModel>>(
      future: _audioQuery.querySongs(sortType: null, orderType: OrderType.ASC_OR_SMALLER, uriType: UriType.EXTERNAL, ignoreCase: true),
      builder: (context, item) {
        if (item.data == null) return const Center(child: CircularProgressIndicator());
        if (item.data!.isEmpty) return const Center(child: Text("SEM MÚSICAS"));
        return ListView.builder(
          itemCount: item.data!.length,
          itemBuilder: (context, index) => ListTile(
            leading: Icon(Icons.audiotrack, color: widget.textColor),
            title: Text(item.data![index].title, style: TextStyle(color: widget.textColor, fontSize: 14)),
            subtitle: Text(item.data![index].artist ?? "Desconhecido", style: TextStyle(color: widget.textColor.withOpacity(0.6), fontSize: 12)),
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerDisplay(song: item.data![index], player: _player, textColor: widget.textColor))),
          ),
        );
      },
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("CONFIGURAÇÕES", style: TextStyle(color: widget.textColor, fontWeight: FontWeight.bold)),
            SwitchListTile(
              title: Text("TEMA ESCURO", style: TextStyle(color: widget.textColor)),
              value: widget.isDarkMode,
              onChanged: (val) { widget.toggleTheme(); Navigator.pop(context); },
            ),
          ],
        ),
      ),
    );
  }
}

class PlayerDisplay extends StatefulWidget {
  final SongModel song;
  final AudioPlayer player;
  final Color textColor;
  const PlayerDisplay({super.key, required this.song, required this.player, required this.textColor});

  @override
  State<PlayerDisplay> createState() => _PlayerDisplayState();
}

class _PlayerDisplayState extends State<PlayerDisplay> {
  bool isShuffle = false;

  @override
  void initState() {
    super.initState();
    _play();
  }

  void _play() async {
    try {
      await widget.player.setAudioSource(AudioSource.uri(Uri.parse(widget.song.uri!)));
      widget.player.play();
    } catch (e) {
      print("Erro: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Icon(Icons.unfold_more, color: widget.textColor),
                  Container(width: 40, height: 4, color: widget.textColor),
                  IconButton(
                    icon: Icon(isShuffle ? Icons.shuffle_on_outlined : Icons.shuffle, color: widget.textColor),
                    onPressed: () {
                      setState(() => isShuffle = !isShuffle);
                      widget.player.setShuffleModeEnabled(isShuffle);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 60),
              Text(widget.song.title.toUpperCase(), textAlign: TextAlign.center, style: TextStyle(fontSize: 22, color: widget.textColor, fontWeight: FontWeight.bold)),
              Text(widget.song.artist?.toUpperCase() ?? "UNKNOWN", style: TextStyle(fontSize: 14, color: widget.textColor.withOpacity(0.7))),
              const SizedBox(height: 50),
              StreamBuilder<Duration>(
                stream: widget.player.positionStream,
                builder: (context, snapshot) {
                  final pos = snapshot.data ?? Duration.zero;
                  final dur = widget.player.duration ?? Duration.zero;
                  return LinearProgressIndicator(
                    value: dur.inSeconds > 0 ? pos.inSeconds / dur.inSeconds : 0,
                    backgroundColor: widget.textColor.withOpacity(0.1),
                    color: widget.textColor,
                    minHeight: 8,
                  );
                }
              ),
              const SizedBox(height: 60),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _btn(Icons.skip_previous),
                  _btn(Icons.pause, large: true),
                  _btn(Icons.skip_next),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _btn(IconData icon, {bool large = false}) {
    return Container(
      padding: EdgeInsets.all(large ? 20 : 10),
      decoration: BoxDecoration(
        border: Border.all(color: widget.textColor, width: 2),
        boxShadow: [BoxShadow(color: widget.textColor.withOpacity(0.15), offset: const Offset(4, 4))],
      ),
      child: Icon(icon, color: widget.textColor, size: large ? 40 : 30),
    );
  }
}
