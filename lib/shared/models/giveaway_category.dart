import 'package:equatable/equatable.dart';

class GiveawayCategory extends Equatable {
  const GiveawayCategory({
    required this.id,
    required this.nameEn,
    required this.nameAr,
    this.icon,
    this.sortOrder = 0,
    this.isActive = true,
  });
  final String id;
  final String nameEn;
  final String nameAr;
  final String? icon;
  final int sortOrder;
  final bool isActive;
  String label(String language) => language == 'ar' ? nameAr : nameEn;
  factory GiveawayCategory.fromJson(Map<String, dynamic> json) => GiveawayCategory(
    id: json['id'] as String,
    nameEn: json['name_en'] as String,
    nameAr: json['name_ar'] as String,
    icon: json['icon'] as String?,
    sortOrder: json['sort_order'] as int? ?? 0,
    isActive: json['is_active'] as bool? ?? true,
  );
  Map<String, dynamic> toJson() => {
    'name_en': nameEn.trim(),
    'name_ar': nameAr.trim(),
    'icon': icon,
    'sort_order': sortOrder,
    'is_active': isActive,
  };
  @override
  List<Object?> get props => [id, nameEn, nameAr, icon, sortOrder, isActive];
}
