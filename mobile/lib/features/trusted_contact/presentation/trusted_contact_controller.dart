import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/trusted_contact_repository.dart';
import '../domain/trusted_contact_models.dart';

class TrustedContactState {
  final bool loading;
  final List<TrustedContactLink> links;
  final String? error;

  const TrustedContactState({this.loading = false, this.links = const [], this.error});

  /// Para el usuario monitoreado: su invitación o vinculación vigente (solo puede haber una).
  TrustedContactLink? get current => links.isEmpty ? null : links.first;
}

class TrustedContactController extends Notifier<TrustedContactState> {
  @override
  TrustedContactState build() {
    // Si cambia el usuario, se reinicia el estado.
    final userId = ref.watch(authProvider.select((s) => s.user?.id));
    if (userId == null) return const TrustedContactState();
    Future.microtask(refresh);
    return const TrustedContactState(loading: true);
  }

  TrustedContactRepository get _repo => ref.read(trustedContactRepositoryProvider);

  /// [silent] = no muestra "cargando" ni errores (se usa para la actualización automática).
  Future<void> refresh({bool silent = false}) async {
    if (!silent) state = TrustedContactState(loading: true, links: state.links);
    try {
      final links = await _repo.list();
      state = TrustedContactState(links: links);
    } catch (e) {
      if (!silent) state = TrustedContactState(links: state.links, error: apiErrorMessage(e));
    }
  }

  /// Usuario monitoreado: crea (o recupera) la invitación. Lanza excepción si falla.
  Future<void> invite() async {
    final link = await _repo.invite();
    state = TrustedContactState(links: [link]);
  }

  /// Auxiliador: acepta una invitación con el código. Lanza excepción si falla.
  Future<void> accept(String code) async {
    final link = await _repo.accept(code);
    final others = state.links.where((l) => l.id != link.id).toList();
    state = TrustedContactState(links: [...others, link]);
  }

  /// Usuario monitoreado: revoca el acceso o cancela la invitación.
  Future<void> revoke(int id) async {
    await _repo.revoke(id);
    state = TrustedContactState(links: state.links.where((l) => l.id != id).toList());
  }
}

final trustedContactProvider =
    NotifierProvider<TrustedContactController, TrustedContactState>(TrustedContactController.new);
