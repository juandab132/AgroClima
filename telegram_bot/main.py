import os
import asyncio
import logging
from dotenv import load_dotenv
from telegram.ext import (
    Application,
    CommandHandler,
    MessageHandler,
    ConversationHandler,
    filters,
)
from telegram import Update
from bot.handlers import (
    start, help_command, helada, fumigar, hoy, semana,
    papa, mora, cafe, registrar, reg_municipio, reg_vereda, reg_altitud, cancel,
    handle_nlp, MUNICIPIO, VEREDA, ALTITUD
)

# Configurar logging
logging.basicConfig(
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    level=logging.INFO
)
logger = logging.getLogger(__name__)

# Cargar variables de entorno
load_dotenv()
token = os.getenv("TELEGRAM_BOT_TOKEN")

if not token:
    raise ValueError("No se encontró TELEGRAM_BOT_TOKEN en .env")


def main():
    """Inicia el bot con polling."""
    # Crear la aplicación
    application = Application.builder().token(token).build()

    # Comandos simples
    application.add_handler(CommandHandler("start", start))
    application.add_handler(CommandHandler("ayuda", help_command))
    application.add_handler(CommandHandler("helada", helada))
    application.add_handler(CommandHandler("fumigar", fumigar))
    application.add_handler(CommandHandler("hoy", hoy))
    application.add_handler(CommandHandler("semana", semana))
    application.add_handler(CommandHandler("papa", papa))
    application.add_handler(CommandHandler("mora", mora))
    application.add_handler(CommandHandler("cafe", cafe))

    # Conversación de registro (/registrar)
    conv_handler = ConversationHandler(
        entry_points=[CommandHandler("registrar", registrar)],
        states={
            MUNICIPIO: [MessageHandler(filters.TEXT & ~filters.COMMAND, reg_municipio)],
            VEREDA: [MessageHandler(filters.TEXT & ~filters.COMMAND, reg_vereda)],
            ALTITUD: [MessageHandler(filters.TEXT & ~filters.COMMAND, reg_altitud)],
        },
        fallbacks=[CommandHandler("cancel", cancel)],
    )
    application.add_handler(conv_handler)

    # Mensajes de texto libre (NLP)
    application.add_handler(MessageHandler(filters.TEXT & ~filters.COMMAND, handle_nlp))

    # Iniciar polling
    logger.info("🚀 AgroClima Bot iniciado. Esperando mensajes...")
    application.run_polling(allowed_updates=Update.ALL_TYPES)


if __name__ == "__main__":
    main()