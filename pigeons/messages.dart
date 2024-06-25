// Copyright 2013 The Flutter Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(PigeonOptions(
  dartOut: 'lib/src/messages.g.dart',
  dartTestOut: 'test/test_api.g.dart',
  javaOut: 'android/src/main/java/io/flutter/plugins/videoplayer/Messages.java',
  javaOptions: JavaOptions(
    package: 'io.flutter.plugins.videoplayer',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
))
class TextureMessage {
  TextureMessage(this.textureId);
  int textureId;
}

class LoopingMessage {
  LoopingMessage(this.textureId, this.isLooping);
  int textureId;
  bool isLooping;
}

class VolumeMessage {
  VolumeMessage(this.textureId, this.volume);
  int textureId;
  double volume;
}

class TrackFormatMessage {
  TrackFormatMessage(
    this.textureId,
    this.id,
    this.label,
    this.language,
    this.formatIndex,
  );
  int textureId;
  String id;
  String? label;
  String? language;
  int formatIndex;
}

class TrackGroupMessage {
  TrackGroupMessage(
    this.textureId,
    this.adaptiveSupported,
    this.trackSelected,
    this.trackSupported,
    this.formats,
    this.trackType,
    this.groupIndex,
  );
  int textureId;
  bool adaptiveSupported;
  List<bool?> trackSelected;
  List<bool?> trackSupported;
  List<TrackFormatMessage?> formats;
  int trackType;
  int groupIndex;
}

class TracksMessage {
  TracksMessage(this.textureId, this.groups);
  int textureId;
  List<TrackGroupMessage?> groups;
}

class SubtitleMessage {
  SubtitleMessage(this.textureId, this.value);
  int textureId;
  String value;
}

class TrackSelectionMessage {
  TrackSelectionMessage(this.textureId, this.groupIndex, this.formatIndex);
  int textureId;
  int groupIndex;
  int formatIndex;
}

class PlaybackSpeedMessage {
  PlaybackSpeedMessage(this.textureId, this.speed);
  int textureId;
  double speed;
}

class PositionMessage {
  PositionMessage(this.textureId, this.position);
  int textureId;
  int position;
}

class CreateMessage {
  CreateMessage({required this.httpHeaders});
  String? asset;
  String? uri;
  String? packageName;
  String? formatHint;
  Map<String?, String?> httpHeaders;
}

class MixWithOthersMessage {
  MixWithOthersMessage(this.mixWithOthers);
  bool mixWithOthers;
}

@HostApi(dartHostTestHandler: 'TestHostVideoPlayerApi')
abstract class AndroidVideoPlayerApi {
  void initialize();
  TextureMessage create(CreateMessage msg);
  void dispose(TextureMessage msg);
  void setLooping(LoopingMessage msg);
  void setVolume(VolumeMessage msg);
  void setPlaybackSpeed(PlaybackSpeedMessage msg);
  void play(TextureMessage msg);
  TracksMessage getTracks(TextureMessage msg);
  SubtitleMessage getCurrentSubtitle(TextureMessage msg);
  void setTrackGroup(TrackSelectionMessage msg);
  PositionMessage position(TextureMessage msg);
  void seekTo(PositionMessage msg);
  void pause(TextureMessage msg);
  void setMixWithOthers(MixWithOthersMessage msg);
}
