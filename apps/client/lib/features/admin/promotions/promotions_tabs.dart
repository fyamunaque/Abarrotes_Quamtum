import 'package:flutter/material.dart';

import '../../../router/routes.dart';
import '../shared/panel_tabs.dart';

/// Las dos vistas de Promociones: las promociones y los códigos que las dan.
const promotionsTabs = <PanelTab>[
  (
    label: 'Promociones',
    icon: Icons.local_offer_outlined,
    path: Routes.adminPromotions,
  ),
  (
    label: 'Códigos',
    icon: Icons.confirmation_number_outlined,
    path: Routes.adminPromoCodes,
  ),
];
