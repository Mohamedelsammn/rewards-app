import 'package:equatable/equatable.dart';

/// One page of a cursor-paginated list: `{ items, nextCursor }`.
class CursorPage<T> extends Equatable {
  const CursorPage({required this.items, this.nextCursor});

  static CursorPage<T> fromJson<T>(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) item,
  ) {
    final raw = json['items'];
    return CursorPage<T>(
      items: raw is List
          ? [
              for (final entry in raw)
                if (entry is Map) item(Map<String, dynamic>.from(entry)),
            ]
          : const [],
      nextCursor: json['nextCursor'] as String?,
    );
  }

  final List<T> items;
  final String? nextCursor;

  bool get hasMore => nextCursor != null;

  @override
  List<Object?> get props => [items, nextCursor];
}

/// Parses a list under [key] that may be absent.
List<T> parseList<T>(Object? raw, T Function(Map<String, dynamic>) item) => raw is List
    ? [
        for (final entry in raw)
          if (entry is Map) item(Map<String, dynamic>.from(entry)),
      ]
    : <T>[];

DateTime? parseDate(Object? raw) => raw is String ? DateTime.tryParse(raw)?.toLocal() : null;

int parseInt(Object? raw, [int fallback = 0]) =>
    raw is num ? raw.toInt() : int.tryParse('$raw') ?? fallback;
