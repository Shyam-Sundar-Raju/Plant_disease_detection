import 'package:flutter/material.dart';
import '../services/app_localizations.dart';

class SafetyBanner extends StatelessWidget {
  const SafetyBanner({
    super.key,
    required this.type,
    required this.ppe,
    this.environmental = const [],
    this.soilProtection,
  });

  final String type; // 'organic' or 'chemical'
  final List<String> ppe;
  final List<String> environmental;
  final String? soilProtection;

  @override
  Widget build(BuildContext context) {
    // Determine styling based on type
    final isChemical = type == 'chemical';
    final backgroundColor = isChemical ? Colors.red.shade50 : Colors.green.shade50;
    final borderColor = isChemical ? Colors.red.shade200 : Colors.green.shade200;
    final iconColor = isChemical ? Colors.red.shade700 : Colors.green.shade700;
    final textColor = isChemical ? Colors.red.shade900 : Colors.green.shade900;
    
    final title = isChemical 
        ? context.t('safety_high_risk') 
        : context.t('Safety warnings');

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
               Icon(Icons.warning_amber_rounded, color: iconColor),
               const SizedBox(width: 8),
               Text(
                 title,
                 style: TextStyle(
                   color: textColor,
                   fontWeight: FontWeight.bold,
                   fontSize: 14,
                 ),
               ),
            ],
          ),
          if (ppe.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              context.t('Required PPE:'),
              style: TextStyle(color: textColor, fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ppe.map((item) {
                // Map ppe keys to localized strings if possible, else use raw
                // We expect keys like 'gloves', 'mask' -> 'ppe_gloves', 'ppe_mask'
                final key = 'ppe_$item';
                final localized = context.t(key);
                // If localization is same as key (fallback), and key starts with ppe_, display item
                final display = localized == key ? item : localized;
                
                return Chip(
                  label: Text(
                    display, 
                    style: TextStyle(fontSize: 10, color: textColor),
                  ),
                  backgroundColor: Colors.white,
                  side: BorderSide(color: borderColor.withOpacity(0.5)),
                  padding: EdgeInsets.zero,
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                  visualDensity: VisualDensity.compact,
                );
              }).toList(),
            ),
          ],
          if (environmental.isNotEmpty) ...[
             const SizedBox(height: 8),
             ...environmental.map((item) {
               final key = 'env_$item';
               final localized = context.t(key);
               final display = localized == key ? item : localized;
               return Padding(
                 padding: const EdgeInsets.only(bottom: 2),
                 child: Row(
                   children: [
                     Icon(Icons.eco_outlined, size: 12, color: iconColor),
                     const SizedBox(width: 4),
                     Text(display, style: TextStyle(color: textColor, fontSize: 12)),
                   ],
                 ),
               );
             }),
          ],
          if (soilProtection != null && soilProtection!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                 Icon(Icons.landscape, size: 12, color: iconColor),
                 const SizedBox(width: 4),
                 // soilProtection is likely English text from JSON, might not be localized yet
                 // But we should try or just display it.
                 Text(soilProtection!, style: TextStyle(color: textColor, fontSize: 12)),
              ],
            ),
          ]
        ],
      ),
    );
  }
}
