import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Category data model
class NannyCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color bgColor;

  const NannyCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.bgColor,
  });
}

/// Default nanny categories
const kNannyCategories = [
  NannyCategory(id: 'all', label: 'All', icon: Icons.grid_view_rounded, bgColor: AppColors.catAll),
  NannyCategory(id: 'infant', label: 'Infant', icon: Icons.child_friendly_rounded, bgColor: AppColors.catInfant),
  NannyCategory(id: 'toddler', label: 'Toddler', icon: Icons.child_care_rounded, bgColor: AppColors.catToddler),
  NannyCategory(id: 'school', label: 'School Age', icon: Icons.school_rounded, bgColor: AppColors.catSchool),
  NannyCategory(id: 'special', label: 'Special Needs', icon: Icons.accessibility_new_rounded, bgColor: AppColors.catSpecial),
  NannyCategory(id: 'night', label: 'Night Care', icon: Icons.nightlight_round, bgColor: AppColors.catNight),
  NannyCategory(id: 'weekend', label: 'Weekend', icon: Icons.wb_sunny_rounded, bgColor: AppColors.catWeekend),
];

/// Wolt-style horizontal scrolling category strip with circular icons
class CategoryStrip extends StatelessWidget {
  final String selectedId;
  final ValueChanged<String> onSelected;
  final List<NannyCategory> categories;

  const CategoryStrip({
    super.key,
    required this.selectedId,
    required this.onSelected,
    this.categories = kNannyCategories,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final cat = categories[index];
          final isSelected = cat.id == selectedId;
          return GestureDetector(
            onTap: () => onSelected(cat.id),
            child: Container(
              width: 76,
              margin: const EdgeInsets.only(right: 8),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : cat.bgColor,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(color: AppColors.primary, width: 2.5)
                          : Border.all(color: Colors.transparent, width: 2.5),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.25),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      cat.icon,
                      size: 28,
                      color: isSelected ? Colors.white : AppColors.textPrimary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.label,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
