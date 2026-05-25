# 🤖 Bot de Telegram - AgroClima Nariño

Este es un bot independiente desarrollado en Python para brindar información climática a agricultores andinos a través de Telegram.

## 🚀 Despliegue Rápido en Render.com

1. Crea un nuevo **Web Service** en Render.
2. Conecta este repositorio.
3. Render detectará automáticamente el archivo `render.yaml`.
4. Configura la variable de entorno `TELEGRAM_BOT_TOKEN` con el token obtenido de [@BotFather](https://t.me/BotFather).
5. ¡Listo! El bot estará activo.

## 🛠️ Ejecución Local

1. Asegúrate de tener Python 3.11+.
2. Ve a la carpeta `telegram_bot/`.
3. Crea un entorno virtual: `python -m venv venv`.
4. Actívalo:
   - Windows: `venv\Scripts\activate`
   - Linux/Mac: `source venv/bin/activate`
5. Instala dependencias: `pip install -r requirements.txt`.
6. Crea un archivo `.env` basado en `.env.example` y pon tu token.
7. Corre el servidor: `uvicorn main:app --reload`.

## 📍 Comandos Principales

- `/start` - Iniciar conversación.
- `/registrar` - Registrar ubicación de la finca.
- `/helada` - Riesgo de helada hoy.
- `/fumigar` - ¿Es buen día para fumigar?
- `/hoy` - Resumen del día.
- `/semana` - Pronóstico 7 días.
- `/papa`, `/mora`, `/cafe` - Fichas técnicas.
- `/ayuda` - Lista de comandos en lenguaje campesino.

## 🧠 NLP Básico

El bot entiende palabras clave como "frío", "lluvia" o "clima" sin necesidad de usar comandos estrictos.
