import 'package:flutter/material.dart';
import 'package:peya_app/models/product_category_model.dart';

/// Icono Material según nombre/icono guardado en `Category` (Supabase).
IconData iconForProductCategory(ProductCategoryModel c) {
  final iconKey = (c.icon ?? '').toLowerCase().trim();
  final name = c.name.toLowerCase();

  bool has(String s) => name.contains(s) || iconKey.contains(s);

  if (has('pizza')) return Icons.local_pizza;
  if (has('pollo') || has('brasa')) return Icons.outdoor_grill;
  if (has('ceviche') || has('maris')) return Icons.set_meal;
  if (has('chifa') || has('oriental')) return Icons.ramen_dining;
  if (has('hamburg') || has('sanguch') || has('sandwich')) return Icons.lunch_dining;
  if (has('bebida')) return Icons.local_drink;
  if (has('postre')) return Icons.cake;
  if (has('desayuno')) return Icons.breakfast_dining;
  if (has('parrilla') || has('bbq')) return Icons.outdoor_grill;
  if (has('café') || has('cafe')) return Icons.local_cafe;
  if (has('helado')) return Icons.icecream;
  if (has('taco') || has('mex')) return Icons.fastfood;
  if (has('sushi')) return Icons.restaurant;
  if (has('plato') || has('fondo')) return Icons.restaurant_menu;
  if (iconKey == 'utensils' || iconKey.contains('utensil')) return Icons.restaurant_menu;
  if (iconKey.contains('cup') || iconKey.contains('soda')) return Icons.local_drink;
  if (iconKey.contains('ice-cream') || iconKey.contains('icecream')) return Icons.cake;

  return Icons.storefront;
}
