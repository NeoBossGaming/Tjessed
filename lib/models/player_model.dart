/// Represents a player's account data from Firebase
class PlayerModel {
  final String uid;
  final String username;
  final String dob;
  final int elo;
  final int matchesPlayed;
  final int matchesWon;
  final int matchesLost;
  final int powerupsUsed;

  const PlayerModel({
    required this.uid,
    required this.username,
    this.dob = '01/01/2000',
    this.elo = 1500,
    this.matchesPlayed = 0,
    this.matchesWon = 0,
    this.matchesLost = 0,
    this.powerupsUsed = 0,
  });

  /// Create from Firebase snapshot data
  factory PlayerModel.fromJson(String uid, Map<dynamic, dynamic> json) {
    return PlayerModel(
      uid: uid,
      username: json['Username'] as String? ?? 'Unknown',
      dob: json['DOB'] as String? ?? '01/01/2000',
      elo: json['Elo'] as int? ?? 1500,
      matchesPlayed: json['Matches Played'] as int? ?? 0,
      matchesWon: json['Matches Won'] as int? ?? 0,
      matchesLost: json['Matches Lost'] as int? ?? 0,
      powerupsUsed: (json['Stats'] as Map?)?['PowerupsUsed'] as int? ?? 0,
    );
  }

  /// Convert to Firebase-compatible JSON (matches existing DB format)
  Map<String, dynamic> toJson() => {
        'Username': username,
        'DOB': dob,
        'Elo': elo,
        'Matches Played': matchesPlayed,
        'Matches Won': matchesWon,
        'Matches Lost': matchesLost,
        'Stats': {
          'PowerupsUsed': powerupsUsed,
        },
      };

  PlayerModel copyWith({
    String? username,
    int? elo,
    int? matchesPlayed,
    int? matchesWon,
    int? matchesLost,
    int? powerupsUsed,
  }) {
    return PlayerModel(
      uid: uid,
      username: username ?? this.username,
      dob: dob,
      elo: elo ?? this.elo,
      matchesPlayed: matchesPlayed ?? this.matchesPlayed,
      matchesWon: matchesWon ?? this.matchesWon,
      matchesLost: matchesLost ?? this.matchesLost,
      powerupsUsed: powerupsUsed ?? this.powerupsUsed,
    );
  }
}
