Future<void> _search(String query) async {
  if (query.isEmpty) return;
  setState(() { _isLoading = true; _results = []; });
  
  try {
    final stream = widget.scClient.search(query, searchFilter: SearchFilter.tracks);
    final trackResults = await stream.first;

    List<Track> foundTracks = [];
    for (var result in trackResults) {
      if (result is TrackSearchResult) {
        // result сам является треком, поле .track не нужно
        final track = result; 
        
        final streams = await widget.scClient.tracks.getStreams(track.id);
        // В версии 1.1.0 container - это строка, а не enum
        final streamInfo = streams.firstWhere(
          (s) => s.container == 'mp3' || s.container == 'audio/mpeg', 
          orElse: () => streams.first
        );

        foundTracks.add(Track(
          title: track.title,
          artist: track.user.username,
          // artworkUrl имеет тип Uri?, поэтому используем toString()
          thumbnail: track.artworkUrl?.toString() ?? '', 
          streamUrl: streamInfo.url.toString(),
          // duration в TrackSearchResult имеет тип double (секунды)
          duration: Duration(milliseconds: (track.duration * 1000).toInt()),
        ));
      }
    }

    setState(() {
      _results = foundTracks;
    });

  } catch (e) {
    debugPrint('Search error: $e');
  } finally {
    if (mounted) setState(() => _isLoading = false);
  }
}
