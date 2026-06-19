import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../core/constants/app_colors.dart';
import '../controllers/client_home_controller.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key, required this.controller});
  final ClientHomeController controller;

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late double _maxDistance;
  late double _maxPrice;
  late bool _onlyVerified;
  late SortBy _sortBy;

  @override
  void initState() {
    super.initState();
    final f = widget.controller.filters.value;
    _maxDistance = f.maxDistanceKm;
    _maxPrice = f.maxPricePerHour;
    _onlyVerified = f.onlyVerified;
    _sortBy = f.sortBy;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.fromLTRB(
          20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Título
          Row(
            children: [
              const Text('Filtros avançados',
                  style:
                      TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
              const Spacer(),
              TextButton(
                onPressed: () {
                  setState(() {
                    _maxDistance = 50;
                    _maxPrice = 500;
                    _onlyVerified = false;
                    _sortBy = SortBy.rating;
                  });
                },
                child: const Text('Limpar',
                    style: TextStyle(color: AppColors.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // ── Distância ──────────────────────────────────────────────────
          _SectionLabel(
              label: 'Distância máxima',
              value: '${_maxDistance.toInt()} km'),
          Slider(
            value: _maxDistance,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: AppColors.primary,
            label: '${_maxDistance.toInt()} km',
            onChanged: (v) => setState(() => _maxDistance = v),
          ),
          const SizedBox(height: 8),

          // ── Preço ──────────────────────────────────────────────────────
          _SectionLabel(
              label: 'Preço máximo por hora',
              value: 'R\$ ${_maxPrice.toInt()}'),
          Slider(
            value: _maxPrice,
            min: 0,
            max: 500,
            divisions: 50,
            activeColor: AppColors.primary,
            label: 'R\$ ${_maxPrice.toInt()}',
            onChanged: (v) => setState(() => _maxPrice = v),
          ),
          const SizedBox(height: 8),

          // ── Apenas verificados ──────────────────────────────────────────
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Apenas verificados',
                style: TextStyle(fontSize: 14)),
            subtitle: const Text('Mostrar só trabalhadores com badge ✓',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            value: _onlyVerified,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _onlyVerified = v),
          ),
          const Divider(height: 24),

          // ── Ordenar por ────────────────────────────────────────────────
          const Text('Ordenar por',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            children: [
              _SortChip(
                label: 'Avaliação',
                icon: Icons.star_rounded,
                value: SortBy.rating,
                selected: _sortBy,
                onTap: (v) => setState(() => _sortBy = v),
              ),
              _SortChip(
                label: 'Preço',
                icon: Icons.attach_money,
                value: SortBy.price,
                selected: _sortBy,
                onTap: (v) => setState(() => _sortBy = v),
              ),
              _SortChip(
                label: 'Proximidade',
                icon: Icons.near_me_rounded,
                value: SortBy.distance,
                selected: _sortBy,
                onTap: (v) => setState(() => _sortBy = v),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Aplicar ────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => widget.controller.applyFilters(
                WorkerFilters(
                  maxDistanceKm: _maxDistance,
                  maxPricePerHour: _maxPrice,
                  onlyVerified: _onlyVerified,
                  sortBy: _sortBy,
                ),
              ),
              child: const Text('Aplicar filtros'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600)),
        const Spacer(),
        Text(value,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary)),
      ],
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    required this.label,
    required this.icon,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final SortBy value;
  final SortBy selected;
  final void Function(SortBy) onTap;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;
    return GestureDetector(
      onTap: () => onTap(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary
              : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: isSelected ? Colors.white : AppColors.textSecondary),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
