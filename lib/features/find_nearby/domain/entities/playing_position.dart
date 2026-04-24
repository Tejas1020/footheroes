/// Position options for match requests.
enum PlayingPosition {
  any,
  gk,
  def,
  mid,
  att,
}

extension PlayingPositionX on PlayingPosition {
  String get value {
    switch (this) {
      case PlayingPosition.any:
        return 'ANY';
      case PlayingPosition.gk:
        return 'GK';
      case PlayingPosition.def:
        return 'DEF';
      case PlayingPosition.mid:
        return 'MID';
      case PlayingPosition.att:
        return 'ATT';
    }
  }

  static PlayingPosition fromString(String value) {
    switch (value) {
      case 'GK':
        return PlayingPosition.gk;
      case 'DEF':
        return PlayingPosition.def;
      case 'MID':
        return PlayingPosition.mid;
      case 'ATT':
        return PlayingPosition.att;
      default:
        return PlayingPosition.any;
    }
  }
}
