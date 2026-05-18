import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_fr.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('es'),
    Locale('fr'),
  ];

  /// No description provided for @appName.
  ///
  /// In es, this message translates to:
  /// **'TopnisMatch'**
  String get appName;

  /// No description provided for @crearCuenta.
  ///
  /// In es, this message translates to:
  /// **'Crear Cuenta'**
  String get crearCuenta;

  /// No description provided for @nombreCompleto.
  ///
  /// In es, this message translates to:
  /// **'Nombre completo'**
  String get nombreCompleto;

  /// No description provided for @email.
  ///
  /// In es, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @contrasena.
  ///
  /// In es, this message translates to:
  /// **'Contraseña'**
  String get contrasena;

  /// No description provided for @fechaNacimiento.
  ///
  /// In es, this message translates to:
  /// **'Fecha de nacimiento'**
  String get fechaNacimiento;

  /// No description provided for @genero.
  ///
  /// In es, this message translates to:
  /// **'Género'**
  String get genero;

  /// No description provided for @masculino.
  ///
  /// In es, this message translates to:
  /// **'Masculino'**
  String get masculino;

  /// No description provided for @femenino.
  ///
  /// In es, this message translates to:
  /// **'Femenino'**
  String get femenino;

  /// No description provided for @noBinario.
  ///
  /// In es, this message translates to:
  /// **'No binario'**
  String get noBinario;

  /// No description provided for @registrarse.
  ///
  /// In es, this message translates to:
  /// **'Registrarse'**
  String get registrarse;

  /// No description provided for @iniciarSesion.
  ///
  /// In es, this message translates to:
  /// **'Iniciar Sesión'**
  String get iniciarSesion;

  /// No description provided for @discover.
  ///
  /// In es, this message translates to:
  /// **'Discover'**
  String get discover;

  /// No description provided for @matches.
  ///
  /// In es, this message translates to:
  /// **'Matches'**
  String get matches;

  /// No description provided for @perfil.
  ///
  /// In es, this message translates to:
  /// **'Perfil'**
  String get perfil;

  /// No description provided for @sobreMi.
  ///
  /// In es, this message translates to:
  /// **'Sobre mí'**
  String get sobreMi;

  /// No description provided for @ciudad.
  ///
  /// In es, this message translates to:
  /// **'Ciudad'**
  String get ciudad;

  /// No description provided for @intereses.
  ///
  /// In es, this message translates to:
  /// **'Mis intereses'**
  String get intereses;

  /// No description provided for @guardar.
  ///
  /// In es, this message translates to:
  /// **'Guardar'**
  String get guardar;

  /// No description provided for @cancelar.
  ///
  /// In es, this message translates to:
  /// **'Cancelar'**
  String get cancelar;

  /// No description provided for @eliminar.
  ///
  /// In es, this message translates to:
  /// **'Eliminar'**
  String get eliminar;

  /// No description provided for @cambiarFoto.
  ///
  /// In es, this message translates to:
  /// **'Cambiar foto'**
  String get cambiarFoto;

  /// No description provided for @eliminarFoto.
  ///
  /// In es, this message translates to:
  /// **'Eliminar foto'**
  String get eliminarFoto;

  /// No description provided for @eliminarMatch.
  ///
  /// In es, this message translates to:
  /// **'Eliminar match'**
  String get eliminarMatch;

  /// No description provided for @errorAlGuardar.
  ///
  /// In es, this message translates to:
  /// **'Error al guardar'**
  String get errorAlGuardar;

  /// No description provided for @errorAlSubirFoto.
  ///
  /// In es, this message translates to:
  /// **'Error al subir foto'**
  String get errorAlSubirFoto;

  /// No description provided for @aunNoTienesMatches.
  ///
  /// In es, this message translates to:
  /// **'Aún no tienes matches'**
  String get aunNoTienesMatches;

  /// No description provided for @hasVistoTodosLosPerfiles.
  ///
  /// In es, this message translates to:
  /// **'✨ Mostrandote más personas...'**
  String get hasVistoTodosLosPerfiles;

  /// No description provided for @encontramosPersonas.
  ///
  /// In es, this message translates to:
  /// **'Encontramos más personas para ti'**
  String get encontramosPersonas;

  /// No description provided for @esUnMatch.
  ///
  /// In es, this message translates to:
  /// **'🎉 ¡Es un Match!'**
  String get esUnMatch;

  /// No description provided for @felicidades.
  ///
  /// In es, this message translates to:
  /// **'¡Felicidades! Ahora pueden chatear.'**
  String get felicidades;

  /// No description provided for @genial.
  ///
  /// In es, this message translates to:
  /// **'¡Genial!'**
  String get genial;

  /// No description provided for @cerrarSesion.
  ///
  /// In es, this message translates to:
  /// **'Cerrar Sesión'**
  String get cerrarSesion;

  /// No description provided for @soleterasyEspacios.
  ///
  /// In es, this message translates to:
  /// **'Solo letras y espacios'**
  String get soleterasyEspacios;

  /// No description provided for @minimoCaracteres.
  ///
  /// In es, this message translates to:
  /// **'Mínimo {n} caracteres'**
  String minimoCaracteres(int n);

  /// No description provided for @maximoCaracteres.
  ///
  /// In es, this message translates to:
  /// **'Máximo {n} caracteres'**
  String maximoCaracteres(int n);

  /// No description provided for @emailInvalido.
  ///
  /// In es, this message translates to:
  /// **'Email no válido'**
  String get emailInvalido;

  /// No description provided for @contrasenaRequisitos.
  ///
  /// In es, this message translates to:
  /// **'Debe tener mayúscula y número'**
  String get contrasenaRequisitos;

  /// No description provided for @seleccionaFecha.
  ///
  /// In es, this message translates to:
  /// **'Selecciona tu fecha de nacimiento'**
  String get seleccionaFecha;

  /// No description provided for @tocarParaVer.
  ///
  /// In es, this message translates to:
  /// **'Toca para ver • Mantén presionado para opciones'**
  String get tocarParaVer;

  /// No description provided for @completadoPerfil.
  ///
  /// In es, this message translates to:
  /// **'Completado del perfil'**
  String get completadoPerfil;

  /// No description provided for @busco.
  ///
  /// In es, this message translates to:
  /// **'¿Qué busco?'**
  String get busco;

  /// No description provided for @relacionSeria.
  ///
  /// In es, this message translates to:
  /// **'Relación seria'**
  String get relacionSeria;

  /// No description provided for @amistad.
  ///
  /// In es, this message translates to:
  /// **'Amistad'**
  String get amistad;

  /// No description provided for @casual.
  ///
  /// In es, this message translates to:
  /// **'Algo casual'**
  String get casual;

  /// No description provided for @noSe.
  ///
  /// In es, this message translates to:
  /// **'No sé aún'**
  String get noSe;

  /// No description provided for @estiloDeVida.
  ///
  /// In es, this message translates to:
  /// **'Estilo de vida'**
  String get estiloDeVida;

  /// No description provided for @redesSociales.
  ///
  /// In es, this message translates to:
  /// **'Redes sociales'**
  String get redesSociales;

  /// No description provided for @conectar.
  ///
  /// In es, this message translates to:
  /// **'Conectar'**
  String get conectar;

  /// No description provided for @agregarFoto.
  ///
  /// In es, this message translates to:
  /// **'Agregar foto'**
  String get agregarFoto;

  /// No description provided for @crearPerfil.
  ///
  /// In es, this message translates to:
  /// **'Crear Perfil'**
  String get crearPerfil;

  /// No description provided for @editarPerfil.
  ///
  /// In es, this message translates to:
  /// **'Editar Perfil'**
  String get editarPerfil;

  /// No description provided for @compatibilidad.
  ///
  /// In es, this message translates to:
  /// **'Compatibilidad'**
  String get compatibilidad;

  /// No description provided for @premium.
  ///
  /// In es, this message translates to:
  /// **'Premium'**
  String get premium;

  /// No description provided for @enviarMensaje.
  ///
  /// In es, this message translates to:
  /// **'Enviar mensaje'**
  String get enviarMensaje;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'es', 'fr'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'fr':
      return AppLocalizationsFr();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
