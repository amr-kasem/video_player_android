// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:video_player_platform_interface/video_player_platform_interface.dart';

import 'messages.g.dart';

/// An Android implementation of [VideoPlayerPlatform] that uses the
/// Pigeon-generated [VideoPlayerApi].
class AndroidVideoPlayer extends VideoPlayerPlatform {
  final AndroidVideoPlayerApi _api = AndroidVideoPlayerApi();

  /// Registers this class as the default instance of [PathProviderPlatform].
  static void registerWith() {
    VideoPlayerPlatform.instance = AndroidVideoPlayer();
  }

  @override
  Future<void> init() {
    return _api.initialize();
  }

  @override
  Future<void> dispose(int textureId) {
    return _api.dispose(TextureMessage(textureId: textureId));
  }

  @override
  Future<int?> create(DataSource dataSource) async {
    String? asset;
    String? packageName;
    String? uri;
    String? formatHint;
    Map<String, String> httpHeaders = <String, String>{};
    switch (dataSource.sourceType) {
      case DataSourceType.asset:
        asset = dataSource.asset;
        packageName = dataSource.package;
      case DataSourceType.network:
        uri = dataSource.uri;
        formatHint = _videoFormatStringMap[dataSource.formatHint];
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.file:
        uri = dataSource.uri;
        httpHeaders = dataSource.httpHeaders;
      case DataSourceType.contentUri:
        uri = dataSource.uri;
    }
    final CreateMessage message = CreateMessage(
      asset: asset,
      packageName: packageName,
      uri: uri,
      httpHeaders: httpHeaders,
      formatHint: formatHint,
    );

    final TextureMessage response = await _api.create(message);
    return response.textureId;
  }

  @override
  Future<void> setLooping(int textureId, bool looping) {
    return _api.setLooping(LoopingMessage(
      textureId: textureId,
      isLooping: looping,
    ));
  }

  @override
  Future<void> play(int textureId) {
    return _api.play(TextureMessage(textureId: textureId));
  }

  @override
  Future<void> pause(int textureId) {
    return _api.pause(TextureMessage(textureId: textureId));
  }

  @override
  Future<void> setVolume(int textureId, double volume) {
    return _api.setVolume(VolumeMessage(
      textureId: textureId,
      volume: volume,
    ));
  }

  @override
  Future<void> setTrack(int textureId, int groupIndex, int formatIndex) async {
    await _api.setTrackGroup(
      TrackSelectionMessage(
        textureId: textureId,
        groupIndex: groupIndex,
        formatIndex: formatIndex,
      ),
    );
  }

  @override
  Future<PlayerTracks> getTracks(int textureId) async {
    final tracks = await _api.getTracks(
      TextureMessage(textureId: textureId),
    );
    return PlayerTracks(
        groups: tracks.groups.map(
      (e) {
        late TrackType type;
        try {
          type = TrackType.values[e?.trackType ?? 0];
        } catch (e) {
          type = TrackType.TRACK_TYPE_UNKNOWN;
        } finally {
          return PlayerTrackGroup(
            adaptiveSupported: e?.adaptiveSupported ?? false,
            trackSupported: e?.trackSupported.map((e) => e ?? false).toList(),
            formats: e?.formats
                    .map(
                      (f) => PlayerTrackFormat(
                        id: f?.id,
                        label: f?.label,
                        language: f?.language,
                        index: f?.formatIndex ?? 0,
                      ),
                    )
                    .toList() ??
                [],
            trackSelected: e?.trackSelected.map((e) => e ?? false).toList(),
            trackType: type,
            index: e?.groupIndex ?? 0,
          );
        }
      },
    ).toList());
  }

  @override
  Future<String> getCurrentSubtitle(int textureId) async {
    final subtitle = await _api.getCurrentSubtitle(
      TextureMessage(textureId: textureId),
    );
    return subtitle.value;
  }

  @override
  Future<void> setPlaybackSpeed(int textureId, double speed) {
    assert(speed > 0);

    return _api.setPlaybackSpeed(PlaybackSpeedMessage(
      textureId: textureId,
      speed: speed,
    ));
  }

  @override
  Future<void> seekTo(int textureId, Duration position) {
    return _api.seekTo(PositionMessage(
      textureId: textureId,
      position: position.inMilliseconds,
    ));
  }

  @override
  Future<Duration> getPosition(int textureId) async {
    final PositionMessage response =
        await _api.position(TextureMessage(textureId: textureId));
    return Duration(milliseconds: response.position);
  }

  @override
  Stream<VideoEvent> videoEventsFor(int textureId) {
    return _eventChannelFor(textureId)
        .receiveBroadcastStream()
        .map((dynamic event) {
      final Map<dynamic, dynamic> map = event as Map<dynamic, dynamic>;
      switch (map['event']) {
        case 'initialized':
          return VideoEvent(
            eventType: VideoEventType.initialized,
            duration: Duration(milliseconds: map['duration'] as int),
            size: Size((map['width'] as num?)?.toDouble() ?? 0.0,
                (map['height'] as num?)?.toDouble() ?? 0.0),
            rotationCorrection: map['rotationCorrection'] as int? ?? 0,
          );
        case 'completed':
          return VideoEvent(
            eventType: VideoEventType.completed,
          );
        case 'bufferingUpdate':
          final List<dynamic> values = map['values'] as List<dynamic>;

          return VideoEvent(
            buffered: values.map<DurationRange>(_toDurationRange).toList(),
            eventType: VideoEventType.bufferingUpdate,
          );
        case 'bufferingStart':
          return VideoEvent(eventType: VideoEventType.bufferingStart);
        case 'bufferingEnd':
          return VideoEvent(eventType: VideoEventType.bufferingEnd);
        case 'isPlayingStateUpdate':
          return VideoEvent(
            eventType: VideoEventType.isPlayingStateUpdate,
            isPlaying: map['isPlaying'] as bool,
          );
        default:
          return VideoEvent(eventType: VideoEventType.unknown);
      }
    });
  }

  @override
  Widget buildView(int textureId) {
    return Stack(
      children: [
        Texture(textureId: textureId),
        // Texture(textureId: auxId),
      ],
    );
  }

  @override
  Future<void> setMixWithOthers(bool mixWithOthers) {
    return _api
        .setMixWithOthers(MixWithOthersMessage(mixWithOthers: mixWithOthers));
  }

  EventChannel _eventChannelFor(int textureId) {
    return EventChannel('flutter.io/videoPlayer/videoEvents$textureId');
  }

  static const Map<VideoFormat, String> _videoFormatStringMap =
      <VideoFormat, String>{
    VideoFormat.ss: 'ss',
    VideoFormat.hls: 'hls',
    VideoFormat.dash: 'dash',
    VideoFormat.other: 'other',
  };

  DurationRange _toDurationRange(dynamic value) {
    final List<dynamic> pair = value as List<dynamic>;
    return DurationRange(
      Duration(milliseconds: pair[0] as int),
      Duration(milliseconds: pair[1] as int),
    );
  }
}
