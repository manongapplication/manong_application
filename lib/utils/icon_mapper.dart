import 'package:flutter/material.dart';

IconData getIconFromName(String iconName) {
  switch (iconName) {
    // Plumbing
    case 'water_drop':
      return Icons.water_drop;
    case 'plumbing':
      return Icons.plumbing;
    case 'wc':
      return Icons.wc;
    case 'thermostat':
      return Icons.thermostat;
    case 'water_damage':
      return Icons.water_damage;
    case 'tap':
      return Icons.tap_and_play; // closest match for faucet
    case 'search':
      return Icons.search;
    case 'shower':
      return Icons.shower;
    case 'delete':
      return Icons.delete;

    // Electrical
    case 'power':
      return Icons.power;
    case 'lightbulb':
      return Icons.lightbulb;
    case 'electrical_services':
      return Icons.electrical_services;
    case 'flash_on':
      return Icons.flash_on;

    // Carpentry
    case 'door_front':
      return Icons.door_front_door;
    case 'shelves':
      return Icons.shelves;
    case 'chair':
      return Icons.chair;
    case 'format_shapes':
      return Icons.format_shapes;
    case 'handyman':
      return Icons.handyman;
    case 'door_sliding':
      return Icons.door_sliding;

    // Painting
    case 'brush':
      return Icons.brush;
    case 'format_paint':
      return Icons.format_paint;

    // Appliance & HVAC
    case 'ac_unit':
      return Icons.ac_unit;
    case 'kitchen':
      return Icons.kitchen;
    case 'settings':
      return Icons.settings;

    // Security
    case 'videocam':
      return Icons.videocam;
    case 'security':
      return Icons.security;
    case 'lock':
      return Icons.lock;
    case 'shield':
      return Icons.shield;

    // Home Maintenance
    case 'air':
      return Icons.air;
    case 'fireplace':
      return Icons.fireplace;
    case 'build':
      return Icons.build;
    case 'cleaning_services':
      return Icons.cleaning_services;
    case 'home_repair_service':
      return Icons.home_repair_service;
    case 'water':
      return Icons.water;
    case 'window':
      return Icons.window;
    case 'inventory_2':
      return Icons.inventory_2;
    case 'garage':
      return Icons.garage;
    case 'fence':
      return Icons.fence;
    case 'deck':
      return Icons.deck;
    case 'pool':
      return Icons.pool;
    case 'smoke_detector':
      return Icons.smoke_free;
    case 'smart_home':
      return Icons.home;

    // Construction & Tools
    case 'construction':
      return Icons.construction;
    case 'tools':
      return Icons.build_circle;
    case 'repair':
      return Icons.handyman;

    // Cleaning & Miscellaneous
    case 'local_laundry_service':
      return Icons.local_laundry_service;
    case 'misc_services':
      return Icons.miscellaneous_services;

    // Transport & Delivery
    case 'local_shipping':
      return Icons.local_shipping;
    case 'directions_car':
      return Icons.directions_car;

    case 'cash':
      return Icons.money;
    case 'card':
      return Icons.credit_card;
    case 'gcash':
      return Icons.account_balance_wallet;
    case 'paypal':
      return Icons.paypal;
    case 'maya':
      return Icons.account_balance;

    // Default / Fallback
    default:
      return Icons.miscellaneous_services;
  }
}
