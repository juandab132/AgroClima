class AppStrings {
  AppStrings._();

  static const String appName = '🌿 AgroClima Nariño';
  static const String appSubtitle = 'Su compañero del campo';

  // Dashboard
  static const String bienvenido = 'Buenas, compadre';
  static const String misFinca = 'Mi finca';
  static const String sinDatos = 'Sin datos disponibles';
  static const String cargando = 'Cargando...';
  static const String recargar = 'Recargar';

  // Predicción
  static const String prediccion = 'Predicción de Helada';
  static const String altitud = 'Altitud (m.s.n.m.)';
  static const String tempMin = 'Temperatura mínima (°C)';
  static const String humedad = 'Humedad (%)';
  static const String viento = 'Viento (km/h)';
  static const String mes = 'Mes del año';
  static const String calcular = 'Calcular riesgo';

  // Riesgo
  static const String riesgoBajo = '✅ Sin Riesgo';
  static const String riesgoMedio = '⚠️ Riesgo Medio';
  static const String riesgoAlto = '🚨 Riesgo Alto';

  // Fumigación
  static const String fumigacion = 'Día para fumigar';
  static const String aptoPara = '✅ Hoy es buen día para fumigar';
  static const String noApto = '❌ Hoy no conviene fumigar';
  static const String mejorDia = 'Mejor día:';
  static const String mejorHora = '7–10am o después de las 4pm';

  // Pronóstico
  static const String pronostico = 'Pronóstico 7 días';
  static const String municipio = 'Seleccione su municipio';
  static const String datosGuardados = 'Mostrando datos guardados';
  static const String sinConexion = 'Sin conexión a internet';

  // Finca
  static const String finca = 'Mi Finca';
  static const String nombreAgri = 'Su nombre';
  static const String nombreFinca = 'Nombre de su finca';
  static const String vereda = 'Vereda (opcional)';
  static const String guardarFinca = 'Guardar mi finca';
  static const String cargarEjemplo = 'Cargar datos de ejemplo';
  static const String fincaGuardada = '¡Finca guardada con éxito!';

  // Cultivos
  static const String cultivos = 'Mis cultivos activos';
  static const String selCultivos = 'Toque los cultivos que tiene en su finca';

  // Historial
  static const String historial = 'Historial Climático';
  static const String fuenteIdeam = 'Fuente: IDEAM Colombia';

  // Calendario
  static const String calendario = 'Calendario Agrícola';

  // Ajustes
  static const String ajustes = 'Ajustes';
  static const String alertasHelada = '🔔 Alertas nocturnas de helada';
  static const String modoOscuro = '🌙 Modo oscuro';
  static const String tamanoLetra = 'Tamaño de letra';
  static const String version = 'Versión 1.0.0';
  static const String limpiarDatos = 'Limpiar datos de mi finca';

  // Meses
  static const List<String> meses = [
    'Enero', 'Febrero', 'Marzo', 'Abril', 'Mayo', 'Junio',
    'Julio', 'Agosto', 'Septiembre', 'Octubre', 'Noviembre', 'Diciembre',
  ];

  // Días
  static const List<String> dias = [
    'Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo',
  ];
}
