import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:neils/auth/auth_providers.dart';
import 'package:neils/auth/auth_repository.dart';
import 'package:neils/session/session.dart';
import 'package:neils/session/session_provider.dart';

import '../fakes.dart';

void main() {
  late FakeAuthRepository auth;
  late FakeUserRepository users;

  setUp(() {
    auth = FakeAuthRepository();
    users = FakeUserRepository(auth);
  });

  /// Arranca la sesión, como la app al abrirse (el router la lee de entrada).
  ProviderContainer start() {
    final container = ProviderContainer.test(
      overrides: [
        authRepositoryProvider.overrideWithValue(auth),
        userRepositoryProvider.overrideWithValue(users),
      ],
    );
    container.read(sessionProvider);
    return container;
  }

  const serverDown = AuthFailure('El servidor no está disponible.');

  group('al arrancar', () {
    test('sin cuenta abierta: carga y queda sin sesión', () async {
      final container = start();

      expect(container.read(sessionProvider), isA<SessionLoading>());
      await flushEvents();
      expect(container.read(sessionProvider), isA<SignedOut>());
    });

    test('restaura la cuenta que quedó abierta, con su rol', () async {
      final ana = auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      users.roles[ana.uid] = UserRole.staff;
      final container = start();

      expect(container.read(sessionProvider), isA<SessionLoading>());
      await flushEvents();
      final session = container.read(sessionProvider);
      expect(session, isA<SignedIn>());
      expect((session as SignedIn).user.role, UserRole.staff);
    });

    test('si el servidor no responde, queda sin sesión y cierra la cuenta '
        'de Firebase', () async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      users.failure = serverDown;
      final container = start();

      await flushEvents();
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(auth.current, isNull);
    });
  });

  group('ingresar', () {
    test('devuelve la cuenta y pide el perfil una sola vez', () async {
      final ana = auth.addAccount('ana@tienda.pe', 'secreta', name: 'Ana');
      users.roles[ana.uid] = UserRole.admin;
      final container = start();
      await flushEvents();

      final user = await container
          .read(sessionProvider.notifier)
          .signIn(email: 'ana@tienda.pe', password: 'secreta');
      await flushEvents();

      expect(user.role, UserRole.admin);
      expect((container.read(sessionProvider) as SignedIn).user, same(user));
      // Firebase avisó del cambio de cuenta, pero el ingreso ya tenía el perfil.
      expect(users.calls, 1);
    });

    test('con la contraseña incorrecta falla y sigue sin sesión', () async {
      auth.addAccount('ana@tienda.pe', 'secreta');
      final container = start();
      await flushEvents();

      await expectLater(
        container
            .read(sessionProvider.notifier)
            .signIn(email: 'ana@tienda.pe', password: 'otra'),
        throwsA(
          isA<AuthFailure>().having(
            (failure) => failure.message,
            'message',
            contains('no son correctos'),
          ),
        ),
      );
      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(users.calls, 0);
    });

    test(
      'si el servidor no responde, falla y cierra la cuenta de Firebase',
      () async {
        auth.addAccount('ana@tienda.pe', 'secreta');
        users.failure = serverDown;
        final container = start();
        await flushEvents();

        await expectLater(
          container
              .read(sessionProvider.notifier)
              .signIn(email: 'ana@tienda.pe', password: 'secreta'),
          throwsA(same(serverDown)),
        );
        await flushEvents();
        expect(container.read(sessionProvider), isA<SignedOut>());
        expect(auth.current, isNull);
      },
    );
  });

  test('registrarse crea un cliente con su nombre', () async {
    final container = start();
    await flushEvents();

    final user = await container
        .read(sessionProvider.notifier)
        .register(
          name: 'Ana Quispe',
          email: 'ana@tienda.pe',
          password: '123456',
        );
    await flushEvents();

    expect(user.role, UserRole.customer);
    // Firebase avisa de la cuenta nueva antes de guardar el nombre. Si la
    // sesión pidiera el perfil con ese aviso, el servidor la crearía sin él.
    expect(user.name, 'Ana Quispe');
    expect(container.read(sessionProvider), isA<SignedIn>());
    expect(users.calls, 1);
  });

  group('salir', () {
    test('cierra la cuenta y la sesión', () async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      final container = start();
      await flushEvents();
      expect(container.read(sessionProvider), isA<SignedIn>());

      await container.read(sessionProvider.notifier).signOut();

      expect(container.read(sessionProvider), isA<SignedOut>());
      expect(auth.current, isNull);
    });

    test('también si la cuenta se cierra por fuera (otra pestaña)', () async {
      auth.addAccount('ana@tienda.pe', 'secreta', signedIn: true);
      final container = start();
      await flushEvents();

      await auth.signOut();
      await flushEvents();

      expect(container.read(sessionProvider), isA<SignedOut>());
    });
  });
}
