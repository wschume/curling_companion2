import 'package:dart_mappable/dart_mappable.dart';

part 'models.mapper.dart';

@MappableEnum()
enum TournamentStatus { upcoming, past }

@MappableClass()
class MarketplaceListing with MarketplaceListingMappable {
  const MarketplaceListing({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.ownerId,
  });

  final String id;
  final String title;
  final String description;
  final double price;
  final String ownerId;
}

@MappableClass()
class Tournament with TournamentMappable {
  const Tournament({
    required this.id,
    required this.name,
    required this.location,
    required this.date,
    required this.status,
    required this.organizerId,
  });

  final String id;
  final String name;
  final String location;
  final DateTime date;
  final TournamentStatus status;
  final String organizerId;
}

@MappableClass()
class PlayerAvailability with PlayerAvailabilityMappable {
  const PlayerAvailability({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.displayName,
    required this.note,
  });

  final String id;
  final String eventId;
  final String userId;
  final String displayName;
  final String note;
}
