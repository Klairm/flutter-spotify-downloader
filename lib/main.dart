import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sn_progress_dialog/sn_progress_dialog.dart';
import 'package:path/path.dart' as path;
import 'package:flutter/material.dart';

import 'package:permission_handler/permission_handler.dart';
import 'package:spotify/spotify.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

var yt = YoutubeExplode();
var video_Id;
var _controller = TextEditingController();
Directory dir = Directory("/storage/emulated/0/Download/music/");
void main() => runApp(const MaterialApp(
      home: Body(),
    ));

class Body extends StatefulWidget {
  const Body({Key? key}) : super(key: key);

  @override
  _BodyState createState() => _BodyState();
}

class _BodyState extends State<Body> {
  List<String> tracks = <String>[];
  final credentials =
      SpotifyApiCredentials('CLIENT_ID_HERE', 'CLIENT_SECRET_HERE');

  Color spotifyColor = const Color.fromRGBO(30, 215, 96, 1);
  Color customBackgroundColor = const Color.fromRGBO(12, 12, 12, 1);
  Color textColor = Colors.white;
  final String regex =
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
        progressValueColor: spotifyColor);

    await yt.search.getVideos(song).then((value) => video_Id = value.first.id);

    await yt.videos.get(video_Id);
    if (kDebugMode) {
      print("[DEBUG] Song name: $song");
    }

    // Get the streams manifest and the audio track.
    var manifest = await yt.videos.streamsClient.getManifest(video_Id);
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
    return MaterialApp(
        home: Scaffold(
            backgroundColor: customBackgroundColor,
            appBar: AppBar(
              title: const Text("Spotify Downloader"),
              centerTitle: true,
              foregroundColor: textColor,
              backgroundColor: spotifyColor,
            ),
            body: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Row(children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 0),
                        child: SizedBox(
                            width: 230,
                            child: TextField(
                                controller: _controller,
                                decoration: const InputDecoration(
                                  fillColor: Color.fromRGBO(20, 20, 20, 1),
                                  filled: true,
                                  hintStyle: TextStyle(color: Colors.white),
                                  hintText: "Playlist URL here",
                                ),
                                style: TextStyle(color: textColor),
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

                                  final spotify = SpotifyApi(credentials);
                                  final items = await spotify.playlists
                                      .getTracksByPlaylistId(text)
                                      .all();

                                  String title = await spotify.playlists
                                      .get(text)
                                      .then((value) {
                                    return value.name.toString().replaceAll(
                                        RegExp(regex, unicode: true), '');
                                  });

                                  if (kDebugMode) {
                                    print("[DEBUG] Playlist Title: $title");
                                  }
                                  await Permission.storage.request();
                                  dir = await Directory(
                                          "/storage/emulated/0/Download/music/$title")
                                      .create(recursive: true);
                                  if (kDebugMode) {
                                    print(
                                        "[DEBUG] Directory created: ${dir.path}");
                                  }

                                  for (var track in items) {
                                    var artist = track.artists!.first.name
                                        .toString()
                                        .replaceAll(
                                            RegExp(regex, unicode: true), '');
                                    var song = track.name.toString().replaceAll(
                                        RegExp(regex, unicode: true), '');
                                    setState(() {
                                      tracks.add('$artist - $song ');
                                      if (kDebugMode) {
                                        print(
                                            '[DEBUG] Added $artist - $song to tracks list');
                                      }
                                    });
                                  }
                                }))),
                    Flexible(
                        flex: 1,
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.8),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(
                                        3, 5), // changes position of shadow
                                  ),
                                ],
                                color: spotifyColor),
                            child: TextButton(
                              child: const Text("Clear"),
                              style: TextButton.styleFrom(primary: textColor),
                              onPressed: () async {
                                setState(() {
                                  tracks.clear();
                                  _controller.clear();
                                });
                              },
                            ))),
                    Flexible(
                        flex: 1,
                        child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.8),
                                    spreadRadius: 1,
                                    blurRadius: 5,
                                    offset: const Offset(3, 5),
                                  ),
                                ],
                                color: spotifyColor),
                            child: TextButton(
                              child: const Text("Get all"),
                              style: TextButton.styleFrom(primary: textColor),
                              onPressed: () async {
                                Future.forEach(tracks, (element) async {
                                  await download(element.toString());
                                });
                              },
                            )))
                  ]),
                  Expanded(
                      flex: 1,
                      child: ListView.builder(
                          scrollDirection: Axis.vertical,
                          shrinkWrap: true,
                          itemCount: tracks.length,
                          itemBuilder: (BuildContext context, int index) {
                            return Container(
                              height: 40,
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.8),
                                      spreadRadius: 1,
                                      blurRadius: 5,
                                      offset: const Offset(3, 5),
                                    ),
                                  ],
                                  color: spotifyColor),
                              width: 10,
                              margin: const EdgeInsets.only(
                                  top: 16, bottom: 0, left: 20, right: 20),
                              child: Center(
                                child: TextButton(
                                  child: Text(tracks[index]),
                                  onPressed: () async {
                                    if (kDebugMode) {
                                      print(
                                          '[DEBUG] Clicked: ${tracks[index]}');
                                    }

                                    await download(tracks[index]);
                                  },
                                  style:
                                      TextButton.styleFrom(primary: textColor),
                                ),
                              ),
                            );
                          }))
                ])));
  }
}
