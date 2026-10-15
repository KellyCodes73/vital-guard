Vital Guard

Aplicación móvil para el monitoreo preventivo durante el sueño

Vital Guard es una aplicación móvil en desarrollo que busca ayudar a identificar posibles patrones respiratorios inusuales durante el sueño y facilitar la comunicación de alertas a contactos de confianza.

La aplicación integra herramientas de monitoreo, gestión de eventos y notificaciones para ofrecer una experiencia de acompañamiento preventivo.

Aviso importante: Vital Guard no es un dispositivo médico, no realiza diagnósticos y no sustituye la evaluación de un profesional de la salud. El análisis de audio es experimental y puede generar falsas alarmas.
Funcionalidades
Gestión de usuarios: registro, inicio de sesión y administración del perfil.
Monitoreo durante el sueño: configuración y gestión de sesiones de monitoreo.
Análisis de audio: procesamiento experimental en el dispositivo móvil para evaluar posibles patrones inusuales.
Modo demostración: permite probar el flujo de monitoreo y alertas sin depender del análisis real del micrófono.
Eventos y alertas: registro de eventos, seguimiento de su estado y gestión de alertas.
Contactos de confianza: vinculación entre usuarios mediante invitaciones.
Notificaciones: integración con Firebase Cloud Messaging para el envío de notificaciones push cuando está configurado.
Ubicación temporal: permite compartir información de ubicación durante determinadas alertas, de acuerdo con las condiciones de la aplicación.
Tecnologías utilizadas
Aplicación móvil: Flutter y Dart.
Backend: Java 21 y Spring Boot.
API: REST con autenticación mediante JWT.
Base de datos: PostgreSQL.
Notificaciones push: Firebase Cloud Messaging (FCM).
Contenedores: Docker.
Despliegue del backend: Render.
Arquitectura

Vital Guard utiliza una arquitectura cliente-servidor. La aplicación móvil se comunica con el backend mediante una API REST autenticada.

El backend gestiona los usuarios, las sesiones de monitoreo, los eventos, las vinculaciones entre usuarios y las alertas. PostgreSQL se utiliza para almacenar los datos correspondientes.

El procesamiento experimental del audio se realiza en el dispositivo móvil. El audio no se envía al backend según el diseño de la aplicación; se transmiten los eventos generados durante el monitoreo.

Estructura del proyecto
vital-guard/
├── backend/       # API REST y lógica del servidor
├── mobile/        # Aplicación móvil Flutter para Android
├── scripts/       # Automatización de tareas del proyecto
├── docker-compose.yml
├── render.yaml
└── README.md

Requisitos de desarrollo
JDK 21.
Maven.
Flutter SDK.
Android Studio.
Docker y Docker Compose para los servicios locales que correspondan.
Un dispositivo Android para probar la aplicación móvil.
Aplicación móvil

La aplicación está desarrollada con Flutter y dispone de funcionalidades para gestionar usuarios, iniciar sesiones de monitoreo y consultar eventos y alertas.

Para las pruebas en un dispositivo Android, se puede construir el APK mediante el script incluido en el proyecto:

powershell -ExecutionPolicy Bypass -File .\scripts\construir-apk.ps1 -ApiUrl https://vitalguard-backend.onrender.com


La aplicación utiliza el backend desplegado para comunicarse con los servicios de Vital Guard.

Backend y servicios

El backend está desarrollado con Spring Boot y proporciona endpoints para:

Autenticación y gestión de usuarios.
Configuración y sesiones de monitoreo.
Administración de contactos de confianza.
Registro y seguimiento de eventos.
Gestión y confirmación de alertas.
Registro de tokens de notificaciones push.
Gestión de información de ubicación temporal cuando corresponde.

La API utiliza autenticación mediante JWT para las rutas protegidas.

Despliegue

El backend está desplegado en Render y utiliza PostgreSQL para la persistencia de datos.

Backend: https://vitalguard-backend.onrender.com
Comprobación del servicio: https://vitalguard-backend.onrender.com/api/health

La disponibilidad de los servicios depende de la configuración y las condiciones de la plataforma de despliegue.

Privacidad y seguridad
El diseño contempla el procesamiento del audio en el dispositivo móvil.
El audio no se almacena ni se envía al backend según el flujo de procesamiento previsto.
La API utiliza autenticación mediante JWT.
Las credenciales y los secretos de los servicios externos deben mantenerse fuera del repositorio.
La ubicación se comparte únicamente durante las condiciones previstas por el flujo de alertas.
Estado del desarrollo

Vital Guard se encuentra en desarrollo continuo. Sus funcionalidades se implementan y mejoran progresivamente, con especial atención al monitoreo, la gestión de alertas, la comunicación con contactos de confianza y la protección de los datos.

El análisis de audio continúa siendo experimental y no debe utilizarse para tomar decisiones médicas.
