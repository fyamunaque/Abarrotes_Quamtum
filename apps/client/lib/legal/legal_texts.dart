/// La versión vigente de los términos de uso y la política de privacidad: la
/// misma que `currentTermsVersion` en apps/server
/// (common/customer_requirements.dart). Si los textos cambian, se suben las
/// dos y cada cuenta los vuelve a aceptar antes de pedir.
const termsVersion = '2026-10-28';

/// Un texto legal: su título y sus secciones (título y párrafo).
typedef LegalText = ({String title, List<(String, String)> sections});

// Los dos textos son una base para que la tienda los revise con quien la
// asesore: no son asesoría legal.

const LegalText termsOfUse = (
  title: 'Términos de uso',
  sections: [
    (
      'La tienda',
      "Neil's Food Services (\"la tienda\") vende abarrotes por esta app y su "
          'web. Al crear una cuenta aceptas estos términos.',
    ),
    (
      'Tu cuenta',
      'Los datos de tu cuenta (nombre, correo, celular y, si lo agregas, tu '
          'DNI) tienen que ser tuyos y verdaderos. Cuida tu contraseña: lo que '
          'se haga con tu cuenta corre por tu cuenta. Para hacer pedidos tienes '
          'que confirmar tu correo.',
    ),
    (
      'Pedidos y precios',
      'El total del carrito es una estimación: el precio final lo pone la '
          'tienda al hacer el pedido, con los precios y promociones de ese '
          'momento. La tienda puede cancelar un pedido si no tiene stock o no '
          'puede entregarlo, y te avisa.',
    ),
    (
      'Entrega y recojo',
      'A domicilio, el pedido se lleva a la dirección que indiques. Para '
          'recogerlo en la tienda, muestras el código de tu pedido. La tienda '
          'puede pedir tu DNI para confirmar que eres tú.',
    ),
    (
      'Uso adecuado',
      'No uses la app para fines ilícitos ni crees cuentas a nombre de otra '
          'persona. La tienda puede desactivar una cuenta que lo haga.',
    ),
    (
      'Cambios',
      'Si estos términos cambian, la app te pedirá aceptarlos de nuevo antes '
          'de tu siguiente pedido.',
    ),
  ],
);

const LegalText privacyPolicy = (
  title: 'Política de privacidad',
  sections: [
    (
      'Quién trata tus datos',
      "Neil's Food Services, conforme a la Ley N.° 29733, Ley de Protección de "
          'Datos Personales, y su reglamento.',
    ),
    (
      'Qué datos pedimos',
      'Tu nombre, correo y celular; tu DNI, solo si decides agregarlo; las '
          'direcciones de entrega y los pedidos que haces.',
    ),
    (
      'Para qué los usamos',
      'Para crear y proteger tu cuenta, preparar y entregar tus pedidos, '
          'contactarte sobre ellos y, con tu DNI, confirmar que eres tú al '
          'entregarlos. No los vendemos ni los usamos para publicidad de otras '
          'empresas.',
    ),
    (
      'Con quién se comparten',
      'Con los servicios que hacen funcionar la app, como Firebase de Google '
          '(que guarda tu correo y tu contraseña: la tienda nunca ve tu '
          'contraseña), y con las autoridades cuando la ley lo exija.',
    ),
    (
      'Cuánto tiempo',
      'Mientras tengas tu cuenta. Los datos de tus pedidos, el tiempo que '
          'exijan las normas tributarias.',
    ),
    (
      'Tus derechos',
      'Puedes pedir acceder a tus datos, corregirlos, eliminarlos u oponerte '
          'a su uso (derechos ARCO) por los canales de contacto de la tienda. '
          'También puedes acudir a la Autoridad Nacional de Protección de Datos '
          'Personales.',
    ),
    (
      'Tu consentimiento',
      'Al marcar la casilla al crear tu cuenta aceptas este tratamiento. Si '
          'esta política cambia, la app te pedirá aceptarla de nuevo.',
    ),
  ],
);
