import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/auth_providers.dart';
import '../../common/page_list.dart';
import '../paged_notifier.dart';
import 'promotion.dart';
import 'promotions_repository.dart';

final promotionsRepositoryProvider = Provider<PromotionsRepository>(
  (ref) => HttpPromotionsRepository(ref.watch(authedApiProvider)),
);

/// Las promociones, filtradas por estado (null: todas).
final promotionsProvider = AsyncNotifierProvider.autoDispose
    .family<PromotionsNotifier, PageList<Promotion>, PromotionStatus?>(
      PromotionsNotifier.new,
    );

class PromotionsNotifier extends PagedNotifier<Promotion> {
  PromotionsNotifier(this.status);

  final PromotionStatus? status;

  @override
  Future<PageList<Promotion>> fetch(int page) =>
      ref.read(promotionsRepositoryProvider).list(page: page, status: status);
}
