import 'dart:io';
import 'package:flutter_svg/svg.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sample_app/utils/constants.dart';
import 'package:sn_progress_dialog/progress_dialog.dart';
import 'package:spotify/spotify.dart' as sp;
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

class SpotifyDownloader extends StatefulWidget {
  const SpotifyDownloader({Key? key}) : super(key: key);

  @override
  State<SpotifyDownloader> createState() => _SpotifyDownloaderState();
}

class _SpotifyDownloaderState extends State<SpotifyDownloader> {
  var yt = YoutubeExplode();
  var videoId;
  var _controller = TextEditingController();

  Directory dir = Directory("/storage/emulated/0/Download/music/");

  List<String> tracks = <String>[];

  String regex =
      r'[^\p{Alphabetic}\p{Mark}\p{Decimal_Number}\p{Connector_Punctuation}\p{Join_Control}\s]+';

  Future<void> download(String song) async {
    ProgressDialog pd = ProgressDialog(context: context);
    pd.show(
      max: 100,
      msg: "Preparing Download...",
      progressType: ProgressType.valuable,
      msgColor: textColor,
      backgroundColor: customBackgroundColor,
      valueColor: textColor,
      progressValueColor: spotifyColor,
    );

    await yt.search.getVideos(song).then((value) => videoId = value.first.id);
    await yt.videos.get(videoId);
    if (kDebugMode) {
      print("[DEBUG] Song name: $song");
    }

    // Get the streams manifest and the audio track.
    var manifest = await yt.videos.streamsClient.getManifest(videoId);
    var audio = manifest.audioOnly.first;

    var audioStream = yt.videos.streamsClient.get(audio);

    var filePath = path.join(dir.uri.toFilePath(), '$song.mp3');

    var file = File(filePath);
    if (await file.exists()) {
      if (kDebugMode) {
        print("[DEBUG] $filePath exists...");
      }
      await file.delete();
    }
    var output = file.openWrite(mode: FileMode.writeOnlyAppend);

    var len = audio.size.totalBytes;
    var count = 0;

    // Listen for data received.

    await for (final data in audioStream) {
      // Keep track of the current downloaded data.
      count += data.length;
      int progress = ((count / len) * 100).ceil();
      pd.update(msg: "Downloading $song", value: progress);

      // Write to file.
      output.add(data);
    }
    await output.close();
    if (kDebugMode) {
      print("[DEBUG] $song Download Completed.");
    }
    pd.close();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: customBackgroundColor,
      body: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          //appbar
          _appBar(context),
          // home body
          SliverList(
            delegate: SliverChildListDelegate(
              [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    10.0,
                    10.0,
                    10.0,
                    10.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AppBar(
                        backgroundColor: Colors.transparent,
                        title: TextField(
                          controller: _controller,
                          decoration: const InputDecoration(
                            fillColor: Color.fromRGBO(20, 20, 20, 1),
                            hintText: "Playlist URL here",
                          ),
                          onSubmitted: (text) async {
                            // Take the ID from the URL
                            if (text.contains("playlist/")) {
                              final playlistID =
                                  // ignore: unnecessary_string_escapes
                                  RegExp("playlist\/([a-zA-Z0-9]{22})");
                              if (playlistID.hasMatch(text)) {
                                var match = playlistID
                                    .firstMatch(text)
                                    ?.group(1)
                                    .toString();
                                text = match.toString();
                              }
                            }

                            final spotify = sp.SpotifyApi(credentials);
                            final items = await spotify.playlists
                                .getTracksByPlaylistId(text)
                                .all();

                            String title =
                                await spotify.playlists.get(text).then((value) {
                              return value.name
                                  .toString()
                                  .replaceAll(RegExp(regex, unicode: true), '');
                            });

                            if (kDebugMode) {
                              print("[DEBUG] Playlist Title: $title");
                            }
                            await Permission.storage.request();
                            dir = await Directory(
                                    "/storage/emulated/0/Download/music/$title")
                                .create(recursive: true);
                            if (kDebugMode) {
                              print("[DEBUG] Directory created: ${dir.path}");
                            }

                            for (var track in items) {
                              var artist = track.artists!.first.name
                                  .toString()
                                  .replaceAll(RegExp(regex, unicode: true), '');
                              var song = track.name
                                  .toString()
                                  .replaceAll(RegExp(regex, unicode: true), '');
                              setState(() {
                                tracks.add('$artist - $song ');
                                if (kDebugMode) {
                                  print(
                                      '[DEBUG] Added $artist - $song to tracks list');
                                }
                              });
                            }
                          },
                        ),
                        actions: [
                          IconButton(
                            splashRadius: 24,
                            onPressed: () {
                              setState(() {
                                tracks.clear();
                                _controller.clear();
                              });
                            },
                            icon: const Icon(Icons.clear_rounded),
                          ),
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                            ),
                            onPressed: () async {
                              Future.forEach(tracks, (element) async {
                                await download(element.toString());
                              });
                            },
                            icon: const Icon(Icons.downloading_rounded),
                            label: const Text(
                              'Download All',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                tracks.isNotEmpty
                    ? ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: tracks.length,
                        itemBuilder: (BuildContext context, int index) {
                          double boxSize = MediaQuery.of(context).size.height >
                                  MediaQuery.of(context).size.width
                              ? MediaQuery.of(context).size.width / 2
                              : MediaQuery.of(context).size.height / 2.5;
                          return InkWell(
                            onTap: () async {
                              if (kDebugMode) {
                                print('[DEBUG] Clicked: ${tracks[index]}');
                              }

                              await download(tracks[index]);
                            },
                            child: SizedBox(
                              height: boxSize - 100,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.start,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 70,
                                    width: 70,
                                    child: Image.asset(
                                      "assets/images/cover.jpg",
                                    ),
                                  ),
                                  Expanded(
                                    child: ListTile(
                                      title: Text(
                                        tracks[index],
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 17),
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(right: 3.0),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        IconButton(
                                          splashRadius: 24,
                                          onPressed: () async {
                                            if (kDebugMode) {
                                              print(
                                                  '[DEBUG] Clicked: ${tracks[index]}');
                                            }

                                            await download(tracks[index]);
                                          },
                                          icon: const Icon(
                                            Icons.file_download_outlined,
                                          ),
                                        )
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          );
                        },
                      )
                    // pending search page
                    : pendingSearchPage(context)
              ],
            ),
          )
        ],
      ),
    );
  }

  _appBar(BuildContext context) {
    return SliverAppBar(
      elevation: 0,
      stretch: true,
      pinned: true,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Theme.of(context).colorScheme.secondary
          : null,
      expandedHeight: MediaQuery.of(context).size.height / 4.5,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        background: ShaderMask(
          shaderCallback: (rect) {
            return const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Colors.black, Colors.transparent],
            ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
          },
          blendMode: BlendMode.dstIn,
          child: Center(
            child: Text(
              "Spotify Downloader",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 70,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  pendingSearchPage(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.only(top: 5.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SvgPicture.asset("assets/svg/search.svg", height: 200, width: 100),
            const SizedBox(height: 20),
            Icon(
              Icons.download_outlined,
              color: Theme.of(context).colorScheme.secondary,
              size: 50,
            ),
            Text(
              "Paste URL to fetch songs",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
