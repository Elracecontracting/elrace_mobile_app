import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:chewie/chewie.dart';
import 'package:video_player/video_player.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';
import '../models/qr_media_model.dart';

class ListMediaScreen extends StatefulWidget {
  final List<dynamic> mediaList;

  const ListMediaScreen({
    Key? key,
    required this.mediaList,
  }) : super(key: key);

  @override
  State<ListMediaScreen> createState() => _ListMediaScreenState();
}

class _ListMediaScreenState extends State<ListMediaScreen> {
  late List<QrMediaModel> _mediaList;
  late List<QrMediaModel> _filteredList;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _mediaList = widget.mediaList.cast<QrMediaModel>();
    _filteredList = _mediaList;
  }

  void _filterMedia(String query) {
    setState(() {
      if (query.isEmpty) {
        _filteredList = _mediaList;
      } else {
        _filteredList = _mediaList
            .where((media) =>
                media.name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Media'),
        backgroundColor: Colors.blue,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _filterMedia,
              decoration: InputDecoration(
                hintText: 'Search media...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredList.length,
              itemBuilder: (context, index) {
                final media = _filteredList[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(16),
                    leading: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: media.isVideo
                            ? Colors.blue.shade50
                            : Colors.purple.shade50,
                        borderRadius: BorderRadius.circular(8),
                        image: media.thumbnailUrl != null
                            ? DecorationImage(
                                image: NetworkImage(media.thumbnailUrl!),
                                fit: BoxFit.cover,
                              )
                            : null,
                      ),
                      child: media.thumbnailUrl == null
                          ? Icon(
                              media.isVideo ? Icons.videocam : Icons.image,
                              color:
                                  media.isVideo ? Colors.blue : Colors.purple,
                              size: 30,
                            )
                          : null,
                    ),
                    title: Text(
                      media.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: media.description != null
                        ? Text(
                            media.description!,
                            style: GoogleFonts.inter(fontSize: 14),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          )
                        : null,
                    trailing: const Icon(Icons.play_circle, size: 32),
                    onTap: () {
                      if (media.isVideo) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => VideoPlayerScreen(
                              media: media,
                            ),
                          ),
                        );
                      }
                    },
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

class VideoPlayerScreen extends StatefulWidget {
  final QrMediaModel media;

  const VideoPlayerScreen({
    Key? key,
    required this.media,
  }) : super(key: key);

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;
  YoutubePlayerController? _youtubeController;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  void _initializePlayer() {
    if (widget.media.isYouTube) {
      final videoId = YoutubePlayer.convertUrlToId(widget.media.url);
      if (videoId != null) {
        _youtubeController = YoutubePlayerController(
          initialVideoId: videoId,
          flags: const YoutubePlayerFlags(
            autoPlay: true,
            mute: false,
          ),
        );
      }
    } else {
      _videoPlayerController =
          VideoPlayerController.networkUrl(Uri.parse(widget.media.url));
      _videoPlayerController!.initialize().then((_) {
        _chewieController = ChewieController(
          videoPlayerController: _videoPlayerController!,
          autoPlay: true,
          looping: false,
        );
        setState(() {});
      });
    }
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoPlayerController?.dispose();
    _youtubeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.media.name),
        backgroundColor: Colors.blue,
      ),
      body: Center(
        child: widget.media.isYouTube && _youtubeController != null
            ? YoutubePlayer(
                controller: _youtubeController!,
                showVideoProgressIndicator: true,
              )
            : _chewieController != null
                ? Chewie(controller: _chewieController!)
                : const CircularProgressIndicator(),
      ),
    );
  }
}
