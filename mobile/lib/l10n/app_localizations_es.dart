// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'TodoTrip';

  @override
  String get commonCancel => 'Cancelar';

  @override
  String get commonDelete => 'Eliminar';

  @override
  String get commonRemove => 'Quitar';

  @override
  String get commonUndo => 'Deshacer';

  @override
  String get commonTryAgain => 'Reintentar';

  @override
  String get commonClear => 'Borrar';

  @override
  String get commonCopy => 'Copiar';

  @override
  String get commonOk => 'OK';

  @override
  String get commonYou => 'Tú';

  @override
  String get commonYouLower => 'ti';

  @override
  String get commonSomeone => 'Alguien';

  @override
  String get commonSomeoneLower => 'alguien';

  @override
  String get commonUnknown => 'Desconocido';

  @override
  String get commonOwner => 'Propietario';

  @override
  String get commonMember => 'Miembro';

  @override
  String get commonComingSoon => 'Próximamente';

  @override
  String get errorGeneric => 'Algo ha ido mal. Inténtalo de nuevo.';

  @override
  String get errorSlowConnection => 'Conexión lenta. Inténtalo de nuevo.';

  @override
  String get errorNoConnection => 'No se puede contactar con el servidor.';

  @override
  String get errorInvalidData => 'Revisa los datos que has introducido';

  @override
  String get errorWrongCredentials => 'Correo o contraseña incorrectos';

  @override
  String get errorEmailTaken => 'Este correo ya está registrado';

  @override
  String get errorInvalidCode => 'El código no es válido o ha caducado';

  @override
  String get errorNoMapsApp => 'No hay ninguna app de mapas para abrirlo.';

  @override
  String get errorNotAllowed => 'No tienes permiso para hacer eso.';

  @override
  String get errorNotFound => 'Ya no está ahí.';

  @override
  String get authCreateAccount => 'Crea tu cuenta';

  @override
  String get authWelcomeBack => 'Bienvenido de nuevo';

  @override
  String get authTagline => 'Organiza viajes con tus amigos';

  @override
  String get authNameLabel => 'Nombre';

  @override
  String get authNameEmpty => 'Escribe tu nombre';

  @override
  String get authEmailLabel => 'Correo';

  @override
  String get authEmailEmpty => 'Escribe tu correo';

  @override
  String get authEmailInvalid => 'Escribe un correo válido';

  @override
  String get authPasswordLabel => 'Contraseña';

  @override
  String get authPasswordEmpty => 'Escribe tu contraseña';

  @override
  String get authPasswordTooShort => 'Al menos 8 caracteres';

  @override
  String get authShowPassword => 'Mostrar contraseña';

  @override
  String get authHidePassword => 'Ocultar contraseña';

  @override
  String get authSignIn => 'Iniciar sesión';

  @override
  String get authSignUp => 'Registrarse';

  @override
  String get authSwitchToSignIn => '¿Ya tienes cuenta? Inicia sesión';

  @override
  String get authSwitchToSignUp => '¿No tienes cuenta? Regístrate';

  @override
  String get navTrips => 'Viajes';

  @override
  String get navAdd => 'Añadir';

  @override
  String get navSettings => 'Ajustes';

  @override
  String get tripsTitle => 'Mis viajes';

  @override
  String get tripsEmptyTitle => 'Ningún viaje';

  @override
  String get tripsEmptyBody =>
      'Crea tu primer viaje, o únete a uno\ncon el código de un amigo.';

  @override
  String get tripsEmptyAction => 'Empezar';

  @override
  String get addTripTitle => 'Añadir un viaje';

  @override
  String get addTripCreate => 'Crear un viaje';

  @override
  String get addTripCreateBody => 'Empieza a organizar e invita a tus amigos';

  @override
  String get addTripJoin => 'Unirse con un código';

  @override
  String get addTripJoinBody =>
      'Alguien te ha compartido un código de invitación';

  @override
  String get tripNewTitle => 'Nuevo viaje';

  @override
  String get tripNameLabel => 'Nombre del viaje';

  @override
  String get tripNameEmpty => 'Ponle un nombre al viaje';

  @override
  String get tripAddDates => 'Añadir fechas (opcional)';

  @override
  String get tripClearDates => 'Borrar fechas';

  @override
  String get tripCreate => 'Crear viaje';

  @override
  String get tripJoinTitle => 'Unirse a un viaje';

  @override
  String get tripJoinBody => 'Escribe el código que te ha compartido un amigo';

  @override
  String get tripJoinCodeEmpty => 'Escribe el código que te han dado';

  @override
  String get tripJoin => 'Unirse';

  @override
  String get tripNoDates => 'Sin fechas';

  @override
  String tripDatesFrom(String date) {
    return 'Desde el $date';
  }

  @override
  String tripDatesUntil(String date) {
    return 'Hasta el $date';
  }

  @override
  String get tripFallbackName => 'Viaje';

  @override
  String get tabCalendar => 'Calendario';

  @override
  String get tabTasks => 'Tareas';

  @override
  String get tabMoney => 'Gastos';

  @override
  String get tabMap => 'Mapa';

  @override
  String get tabGroup => 'Grupo';

  @override
  String get fabEvent => 'Evento';

  @override
  String get fabTask => 'Tarea';

  @override
  String get fabList => 'Lista';

  @override
  String get fabExpense => 'Gasto';

  @override
  String get calendarEmptyTitle => 'Nada planeado';

  @override
  String get calendarEmptyBody =>
      'Añade vuelos, entradas y\ntodo lo que tenga una hora.';

  @override
  String get calendarToday => 'Hoy';

  @override
  String get calendarTomorrow => 'Mañana';

  @override
  String get tasksViewTodo => 'Pendientes';

  @override
  String get tasksViewLists => 'Listas';

  @override
  String get tasksEmptyTitle => 'Nada que hacer';

  @override
  String get tasksEmptyBody =>
      'Reservar el hostal, comprar crema,\nrepartir la conducción.';

  @override
  String tasksCompletedCount(int count) {
    return '$count completadas';
  }

  @override
  String tasksOverdue(String date) {
    return 'Vencida · $date';
  }

  @override
  String tasksDueToday(String time) {
    return 'Hoy, $time';
  }

  @override
  String tasksDueTomorrow(String time) {
    return 'Mañana, $time';
  }

  @override
  String get listsEmptyTitle => 'Ninguna lista';

  @override
  String get listsEmptyBody =>
      'La compra, qué llevar,\nsitios que quieres probar.';

  @override
  String get listEmpty => 'Vacía';

  @override
  String get listAllDone => 'Todo hecho';

  @override
  String listLeftOf(int left, int total) {
    return '$left de $total por coger';
  }

  @override
  String listProgress(int checked, int total) {
    return '$checked de $total';
  }

  @override
  String get listTitle => 'Lista';

  @override
  String get listGoneTitle => 'Esta lista ya no existe';

  @override
  String get listGoneBody => 'Alguien del grupo la ha eliminado.';

  @override
  String get listEntriesEmptyTitle => 'Todavía vacía';

  @override
  String get listEntriesEmptyBody =>
      'Escribe abajo y toca +.\nEl campo se queda listo para la siguiente.';

  @override
  String get listAddItem => 'Añadir un elemento';

  @override
  String get itemNewEvent => 'Nuevo evento';

  @override
  String get itemNewTask => 'Nueva tarea';

  @override
  String get itemNewList => 'Nueva lista';

  @override
  String get itemEventLabel => '¿Qué pasa?';

  @override
  String get itemTaskLabel => '¿Qué hay que hacer?';

  @override
  String get itemListLabel => '¿Para qué es la lista?';

  @override
  String get itemListHint => 'Compra';

  @override
  String get itemPickDateTime => 'Elige fecha y hora';

  @override
  String get itemAddDeadline => 'Añadir un plazo (opcional)';

  @override
  String get itemWhereOptional => '¿Dónde? (opcional)';

  @override
  String get itemAssignTo => 'ASIGNAR A';

  @override
  String get itemAssignHint => 'Déjalo vacío y puede hacerlo cualquiera.';

  @override
  String get itemAddEvent => 'Añadir evento';

  @override
  String get itemAddTask => 'Añadir tarea';

  @override
  String get itemAddList => 'Añadir lista';

  @override
  String get moneyAllSettled => 'Todo saldado';

  @override
  String get moneyYouAreOwed => 'Te deben';

  @override
  String get moneyYouOwe => 'Debes';

  @override
  String moneyTripTotal(String amount) {
    return 'Total del viaje $amount';
  }

  @override
  String get moneySettleUp => 'Saldar cuentas';

  @override
  String get moneyEveryonesBalance => 'Saldos de todos';

  @override
  String get moneyEmptyTitle => 'Ningún gasto';

  @override
  String get moneyEmptyBody =>
      'Añade el primero y llevaremos\nla cuenta de quién debe qué.';

  @override
  String moneyPaidBy(String name) {
    return 'Pagado por $name';
  }

  @override
  String moneyYourShare(String amount) {
    return 'tu parte: $amount';
  }

  @override
  String get moneyNotInvolved => 'no participas';

  @override
  String get moneyRepayment => 'Devolución';

  @override
  String moneyPaidSomeone(String payer, String payee) {
    return '$payer pagó a $payee';
  }

  @override
  String get moneyToday => 'Hoy';

  @override
  String get moneyYesterday => 'Ayer';

  @override
  String get expenseNewTitle => 'Nuevo gasto';

  @override
  String get expenseWhatFor => '¿Para qué?';

  @override
  String get expensePaidBy => 'PAGADO POR';

  @override
  String get expenseSplitBetween => 'REPARTIDO ENTRE';

  @override
  String get expenseSplitEqually => 'Repartir por igual';

  @override
  String get expenseCustomAmounts => 'Importes personalizados';

  @override
  String get expenseRemaining => 'Restante';

  @override
  String get expenseSave => 'Guardar gasto';

  @override
  String get expenseSplitLabel => 'REPARTO';

  @override
  String get expenseDelete => 'Eliminar gasto';

  @override
  String get expenseDeleting => 'Eliminando…';

  @override
  String get expenseSuggestionExamples => 'Cena';

  @override
  String get expenseSuggestionGroceries => 'Compra';

  @override
  String get expenseSuggestionTaxi => 'Taxi';

  @override
  String get expenseSuggestionHotel => 'Hotel';

  @override
  String get expenseSuggestionDrinks => 'Bebidas';

  @override
  String get settleTitle => 'Saldar cuentas';

  @override
  String get settleBody => 'La forma más simple de dejarlo todo a cero:';

  @override
  String get settleAllSquare => 'Estáis en paz.';

  @override
  String settleSummary(int payments, int expenses) {
    String _temp0 = intl.Intl.pluralLogic(
      payments,
      locale: localeName,
      other: '$payments pagos',
      one: '1 pago',
    );
    return '$_temp0 en lugar de $expenses';
  }

  @override
  String get settleMarkAsPaid => 'Marcar como pagado';

  @override
  String get settleUndoTitle => '¿Deshacer esta devolución?';

  @override
  String get settleUndoBody =>
      'Los saldos de todos vuelven a como estaban antes de registrarla.';

  @override
  String get settleUndoAction => 'Deshacer esta devolución';

  @override
  String get settleUndoing => 'Deshaciendo…';

  @override
  String settleOnlySenderCanUndo(String name) {
    return 'Solo $name puede deshacerlo.';
  }

  @override
  String get settleRepaymentTitle => 'Devolución';

  @override
  String groupPeopleCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count personas',
      one: '1 persona',
    );
    return '$_temp0';
  }

  @override
  String get groupInvitePeople => 'Invitar gente';

  @override
  String get groupDangerZone => 'Zona de riesgo';

  @override
  String get groupDeleteTrip => 'Eliminar viaje';

  @override
  String get groupLeaveTrip => 'Salir del viaje';

  @override
  String groupJoined(String date) {
    return 'Se unió el $date';
  }

  @override
  String get inviteTitle => 'Invitar gente';

  @override
  String get inviteBody =>
      'Comparte un código y cualquiera puede unirse a este viaje.';

  @override
  String get inviteCreate => 'Crear un código de invitación';

  @override
  String get inviteNewCode => 'Nuevo código';

  @override
  String get inviteNotUsedYet => 'Sin usar todavía';

  @override
  String inviteUsedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Usado $count veces',
      one: 'Usado una vez',
    );
    return '$_temp0';
  }

  @override
  String get inviteCodeCopied => 'Código copiado';

  @override
  String get inviteRevoke => 'Revocar este código';

  @override
  String get inviteCodeHint => 'ABCD1234';

  @override
  String get memberNoLongerHere => 'Esta persona ya no está en el viaje.';

  @override
  String get memberMakeOwner => 'Hacer propietario';

  @override
  String get memberMakeOwnerDetail =>
      'Se queda el viaje, tú pasas a ser miembro.';

  @override
  String get memberRemove => 'Quitar del viaje';

  @override
  String get memberRemoveDetail => 'Pierde el acceso al instante.';

  @override
  String get memberLeaveAndDelete => 'Salir y eliminar el viaje';

  @override
  String get memberLeaveBlocked =>
      'Eres el propietario. Haz propietario a alguien más primero.';

  @override
  String get memberLeaveLastOne =>
      'Eres el último, así que el viaje se va contigo.';

  @override
  String get memberOwnerOnly =>
      'Solo el propietario puede gestionar los miembros.';

  @override
  String memberMakeOwnerTitle(String name) {
    return '¿Hacer propietario a $name?';
  }

  @override
  String memberMakeOwnerBody(String name) {
    return '$name podrá invitar gente, quitar miembros y eliminar el viaje. Tú pasas a ser un miembro normal, y solo $name podrá devolvértelo.';
  }

  @override
  String memberRemoveTitle(String name) {
    return '¿Quitar a $name?';
  }

  @override
  String get memberRemoveBody =>
      'Pierde el acceso a este viaje al instante. Lo que añadió se queda: gastos, tareas y los saldos de los demás no cambian.';

  @override
  String get memberNotSettledTitle => 'Cuentas sin saldar';

  @override
  String memberOwesAmount(String name, String amount) {
    return '$name debe $amount. Saldad antes de quitarlo.';
  }

  @override
  String memberIsOwedAmount(String name, String amount) {
    return 'A $name le deben $amount. Saldad antes de quitarlo.';
  }

  @override
  String memberYouOweAmount(String amount) {
    return 'Debes $amount. Salda antes de salir.';
  }

  @override
  String memberYouAreOwedAmount(String amount) {
    return 'Te deben $amount. Saldad antes de que salgas.';
  }

  @override
  String get memberOwnerTitle => 'Eres el propietario';

  @override
  String get memberOwnerBody =>
      'Haz propietario a alguien más antes de salir, para que el grupo se quede con alguien que pueda gestionar el viaje.';

  @override
  String memberLeaveTitle(String trip) {
    return '¿Salir de $trip?';
  }

  @override
  String get memberLeaveBody =>
      'Perderás el acceso al plan y a los gastos. Lo que ya añadiste se queda con el grupo.';

  @override
  String memberLeaveDeleteTitle(String trip) {
    return '¿Salir y eliminar $trip?';
  }

  @override
  String get memberLeaveDeleteBody =>
      'Eres el último. Al salir, este viaje se elimina con todo lo que contiene: gastos, calendario, tareas y listas. No se puede deshacer.';

  @override
  String get memberLeaveDeleteAction => 'Salir y eliminar';

  @override
  String get memberLeaveAction => 'Salir';

  @override
  String tripDeleteTitle(String trip) {
    return '¿Eliminar $trip?';
  }

  @override
  String get tripDeleteBody =>
      'Esto elimina para siempre el plan, cada gasto y los saldos de todos. No se puede deshacer.';

  @override
  String deleteItemTitle(String title) {
    return '¿Eliminar «$title»?';
  }

  @override
  String deleteListTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get deleteListEmptyBody => 'La lista se quita para todos.';

  @override
  String deleteListBody(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Sus $count elementos se van con ella, para todos.',
      one: 'Su elemento se va con ella, para todos.',
    );
    return '$_temp0';
  }

  @override
  String deleteEntryTitle(String text) {
    return '¿Quitar «$text»?';
  }

  @override
  String deleteExpenseTitle(String description) {
    return '¿Eliminar «$description»?';
  }

  @override
  String get deleteExpenseBody => 'Se recalcularán los saldos de todos.';

  @override
  String get deleteExpenseWithRepayments =>
      'En este viaje hay devoluciones registradas. Eliminar este gasto cambiará los saldos de todos.';

  @override
  String get mapShareOn => 'Estás compartiendo tu ubicación';

  @override
  String get mapShareOff => 'Compartir mi ubicación';

  @override
  String get mapShareForegroundOnly => 'Solo mientras este mapa esté abierto.';

  @override
  String get mapServicesOff =>
      'La ubicación está desactivada en este dispositivo.';

  @override
  String get mapPermissionDenied => 'Permiso de ubicación denegado.';

  @override
  String get mapPermissionBlocked =>
      'La ubicación está bloqueada para TodoTrip.';

  @override
  String get mapOpenSettings => 'Abrir ajustes';

  @override
  String get mapFitEveryone => 'Ver a todos';

  @override
  String get mapCentreOnMe => 'Centrar en mí';

  @override
  String get mapEmptyHint => 'Mantén pulsado para dejar un marcador.';

  @override
  String get mapAttribution => 'colaboradores de OpenStreetMap';

  @override
  String get mapRightNow => 'Ahora mismo';

  @override
  String mapMinutesAgo(int count) {
    return 'hace $count minutos';
  }

  @override
  String mapLastSeen(String time) {
    return 'Visto a las $time';
  }

  @override
  String get mapGetDirections => 'Cómo llegar';

  @override
  String get mapAppleMaps => 'Apple Mapas';

  @override
  String get mapGoogleMaps => 'Google Maps';

  @override
  String get pinNewTitle => 'Nuevo marcador';

  @override
  String get pinNameLabel => '¿Qué hay aquí?';

  @override
  String get pinNameHint => 'Hostal Lisboa';

  @override
  String get pinCategoryLabel => 'CATEGORÍA';

  @override
  String get pinNotesLabel => 'Notas (opcional)';

  @override
  String get pinDrop => 'Poner marcador';

  @override
  String get pinDelete => 'Eliminar marcador';

  @override
  String pinDeleteTitle(String name) {
    return '¿Eliminar «$name»?';
  }

  @override
  String get pinDeleteBody => 'Desaparece del mapa para todos.';

  @override
  String pinAddedBy(String name, String date) {
    return 'Añadido por $name · $date';
  }

  @override
  String get pinCategoryLodging => 'Alojamiento';

  @override
  String get pinCategoryFood => 'Comida';

  @override
  String get pinCategoryMeetingPoint => 'Punto de encuentro';

  @override
  String get pinCategoryParking => 'Aparcamiento';

  @override
  String get pinCategorySight => 'Que ver';

  @override
  String get pinCategoryOther => 'Otro';

  @override
  String get settingsTitle => 'Ajustes';

  @override
  String get settingsNotifications => 'Notificaciones';

  @override
  String get settingsPushNotifications => 'Notificaciones push';

  @override
  String get settingsPushNotificationsBody =>
      'Novedades del viaje y tareas nuevas';

  @override
  String get settingsExpenseAlerts => 'Avisos de gastos';

  @override
  String get settingsExpenseAlertsBody => 'Cuando alguien añade un gasto';

  @override
  String get settingsPreferences => 'Preferencias';

  @override
  String get settingsLanguage => 'Idioma';

  @override
  String get settingsLanguageSystem => 'Sistema';

  @override
  String get settingsDefaultCurrency => 'Moneda predeterminada';

  @override
  String get settingsAbout => 'Información';

  @override
  String get settingsVersion => 'Versión';

  @override
  String get settingsPrivacyPolicy => 'Política de privacidad';

  @override
  String get settingsSignOut => 'Cerrar sesión';

  @override
  String get settingsSignOutTitle => '¿Cerrar sesión?';

  @override
  String get settingsSignOutBody =>
      'Necesitarás tu correo y contraseña para volver.';

  @override
  String get tripStageNow => 'En curso';

  @override
  String tripStageDayOf(int day, int total) {
    return 'Día $day de $total';
  }

  @override
  String get tripStageToday => 'Empieza hoy';

  @override
  String get tripStageTomorrow => 'Mañana';

  @override
  String tripStageInDays(int days) {
    return 'En $days días';
  }

  @override
  String get tripStageEnded => 'Terminado';

  @override
  String get moneySettledShort => 'En paz';

  @override
  String get commonJustNow => 'Ahora mismo';

  @override
  String commonMinutesAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count minutos',
      one: 'hace 1 minuto',
    );
    return '$_temp0';
  }

  @override
  String commonHoursAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count horas',
      one: 'hace 1 hora',
    );
    return '$_temp0';
  }

  @override
  String commonDaysAgo(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'hace $count días',
      one: 'hace 1 día',
    );
    return '$_temp0';
  }

  @override
  String get tripIconLabel => 'Icono';

  @override
  String get tripColorLabel => 'Color';

  @override
  String get tripAddDescription => 'Añadir una descripción';

  @override
  String get tripDescriptionLabel => 'Descripción';

  @override
  String get commonSave => 'Guardar';

  @override
  String get settingsAppearance => 'Apariencia';

  @override
  String get settingsAccentColour => 'Color principal';

  @override
  String get settingsAccentColourBody =>
      'Se usa en los botones, los elementos activos y la barra de pestañas.';

  @override
  String get profileTitle => 'Perfil';

  @override
  String get profileSaved => 'Perfil actualizado';

  @override
  String get profileEmailLocked =>
      'Cambiar el correo exige verificar la nueva dirección, algo que todavía no está disponible.';

  @override
  String get profileChangePassword => 'Cambiar contraseña';

  @override
  String get profileChangePasswordBody =>
      'Cierra la sesión en los demás dispositivos';

  @override
  String get profileChangePasswordWarning =>
      'Se cerrará la sesión en todos los demás dispositivos de esta cuenta.';

  @override
  String get profileCurrentPassword => 'Contraseña actual';

  @override
  String get profileNewPassword => 'Nueva contraseña';

  @override
  String get profileRepeatPassword => 'Repite la nueva contraseña';

  @override
  String get profilePasswordMismatch => 'Las dos contraseñas no coinciden';

  @override
  String get profileWrongPassword => 'Esa no es tu contraseña actual';

  @override
  String get profilePasswordChanged => 'Contraseña cambiada';

  @override
  String get profileDeleteAccount => 'Eliminar cuenta';

  @override
  String get profileDeleteTitle => '¿Eliminar tu cuenta?';

  @override
  String get profileDeleteBody =>
      'Tu nombre, tu correo y tu contraseña se borran y se cierra la sesión en todas partes. Los gastos en los que participaste se mantienen, sin tu nombre, porque determinan lo que deben los demás. No se puede deshacer.';

  @override
  String get profileDeleteConfirm => 'Eliminar';

  @override
  String get profileDeleteOwnsTrips =>
      'Todavía eres propietario de un viaje en el que hay otras personas. Pásalo a alguien o elimínalo y vuelve a intentarlo.';

  @override
  String get tripSettingsTitle => 'Ajustes del viaje';

  @override
  String get tripSettingsEdit => 'Editar';

  @override
  String get tripSettingsInfo => 'Información';

  @override
  String get tripSettingsPersonal => 'Solo para ti';

  @override
  String get tripSettingsDanger => 'Zona peligrosa';

  @override
  String get tripCurrencyLabel => 'Moneda';

  @override
  String get tripCurrencyWarning =>
      'Cambiar la moneda no convierte los gastos ya registrados. Los importes siguen igual, solo cambia el símbolo.';

  @override
  String get tripSaveChanges => 'Guardar los cambios';

  @override
  String get tripSaved => 'Viaje actualizado';

  @override
  String tripCreatedByOn(String name, String date) {
    return 'Creado por $name el $date';
  }

  @override
  String tripStatMembers(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count miembros',
      one: '1 miembro',
    );
    return '$_temp0';
  }

  @override
  String tripStatExpenses(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count gastos',
      one: '1 gasto',
    );
    return '$_temp0';
  }

  @override
  String tripStatItems(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count elementos del plan',
      one: '1 elemento del plan',
    );
    return '$_temp0';
  }

  @override
  String get tripTotalSpent => 'Total gastado';

  @override
  String get tripExportCsv => 'Exportar los gastos en CSV';

  @override
  String get tripExportEmpty => 'Todavía no hay gastos que exportar.';

  @override
  String tripExportShareText(String trip) {
    return '$trip — gastos';
  }

  @override
  String get tripMuteLabel => 'Silenciar este viaje';

  @override
  String get tripMuteBody => 'Deja de recibir notificaciones';

  @override
  String get tripArchive => 'Archivar viaje';

  @override
  String get tripArchiveBody =>
      'Lo saca de tu lista. Todos siguen leyéndolo, nadie puede añadir nada.';

  @override
  String get tripArchiveTitle => '¿Archivar este viaje?';

  @override
  String get tripUnarchive => 'Sacar del archivo';

  @override
  String get tripArchivedBanner =>
      'Este viaje está archivado. Ya no se le puede añadir nada.';

  @override
  String get tripsArchivedTitle => 'Archivados';

  @override
  String tripsArchivedCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count viajes archivados',
      one: '1 viaje archivado',
    );
    return '$_temp0';
  }

  @override
  String get tripsArchivedEmpty => 'Todavía no has archivado nada.';

  @override
  String get tripUnsavedChanges => 'Tienes cambios sin guardar';

  @override
  String get calendarYesterday => 'Ayer';

  @override
  String get calendarStartsNow => 'Ahora';

  @override
  String calendarStartsInMinutes(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count min',
      one: 'en 1 min',
    );
    return '$_temp0';
  }

  @override
  String calendarStartsInHours(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'en $count horas',
      one: 'en 1 hora',
    );
    return '$_temp0';
  }

  @override
  String get notificationsTitle => 'Notificaciones';

  @override
  String get notificationsMarkAllRead => 'Marcar todo como leído';

  @override
  String get notificationsEmptyTitle => 'Estás al día';

  @override
  String get notificationsEmptyBody =>
      'Los nuevos gastos, planes y personas\naparecerán aquí.';

  @override
  String notificationExpenseAdded(
    String actor,
    String amount,
    String description,
  ) {
    return '$actor ha añadido $amount por $description';
  }

  @override
  String notificationExpenseDeleted(String actor, String description) {
    return '$actor ha eliminado el gasto de $description';
  }

  @override
  String notificationSettlement(String actor, String amount) {
    return '$actor te ha devuelto $amount';
  }

  @override
  String notificationTaskAssigned(String actor, String title) {
    return '$actor te ha asignado «$title»';
  }

  @override
  String notificationEventAdded(String actor, String title) {
    return '$actor ha añadido $title al plan';
  }

  @override
  String notificationMemberJoined(String actor) {
    return '$actor se ha unido al viaje';
  }

  @override
  String notificationSomethingHappened(String actor) {
    return '$actor ha hecho algo en este viaje';
  }

  @override
  String get settingsMuteTrip => 'Silenciar este viaje';

  @override
  String get settingsMuteTripBody => 'Deja de recibir notificaciones';

  @override
  String get notificationsClearAll => 'Eliminar todas';

  @override
  String get notificationsClearAllTitle =>
      '¿Eliminar todas las notificaciones?';

  @override
  String get notificationsClearAllBody =>
      'Desaparecen solo para ti. No se puede deshacer.';

  @override
  String get notificationDeleteTitle => '¿Eliminar esta notificación?';

  @override
  String get notificationDeleteBody =>
      'Desaparece solo para ti. Aquello de lo que hablaba se mantiene.';
}
