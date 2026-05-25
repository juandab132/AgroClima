from telegram import Update, ReplyKeyboardMarkup, ReplyKeyboardRemove
from telegram.ext import ContextTypes, ConversationHandler
from .services.frost_predictor import FrostPredictor, SprayPredictor
from .services.weather_service import WeatherService
from .services.nlp_engine import NLPEngine
import datetime

weather_svc = WeatherService()
frost_svc = FrostPredictor()
spray_svc = SprayPredictor()
nlp_svc = NLPEngine()

# State for registration conversation
MUNICIPIO, VEREDA, ALTITUD = range(3)

# Datos de cultivos
CULTIVOS = {
    "papa": "🥔 *Ficha de la Papa*\n- Altitud: 2.000-3.500 m.s.n.m.\n- Ciclo: 5-7 meses.\n- Consejos: Aporcar bien, controlar la Gota y rotar con arveja.",
    "mora": "🍇 *Ficha de la Mora*\n- Altitud: 1.800-2.800 m.s.n.m.\n- Ciclo: Cosecha continua.\n- Consejos: Podar ramas macho y fertilizar con potasio.",
    "cafe": "☕ *Ficha del Café*\n- Altitud: 1.200-2.100 m.s.n.m.\n- Ciclo: Anual.\n- Consejos: Controlar la broca y mantener sombra regulada."
}

async def start(update: Update, context: ContextTypes.DEFAULT_TYPE):
    user = update.effective_user
    await update.message.reply_text(
        f"¡Buenas, {user.first_name}! 👨‍🌾\n"
        "Soy el bot de *AgroClima Nariño*. Le ayudo a cuidar sus cultivos del frío y la lluvia.\n"
        "Escriba /ayuda para ver qué puedo hacer por usted.",
        parse_mode='Markdown'
    )

async def help_command(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(
        "📍 *Comandos para el campo:*\n"
        "/helada - ¿Hay riesgo de helada hoy?\n"
        "/fumigar - ¿Es buen día para echar veneno?\n"
        "/hoy - Resumen del clima ahora.\n"
        "/semana - El tiempo para los próximos 7 días.\n"
        "/registrar - Registrar los datos de su finca.\n\n"
        "🌱 *Fichas de cultivos:*\n"
        "/papa, /mora, /cafe\n\n"
        "También puede preguntarme cosas como '¿va a llover?' o '¿tengo riesgo de helada?'",
        parse_mode='Markdown'
    )

async def get_user_finca(context):
    # Simulación de persistencia (usar DB en producción)
    return context.user_data.get('finca')

async def helada(update: Update, context: ContextTypes.DEFAULT_TYPE):
    finca = await get_user_finca(context)
    if not finca:
        await update.message.reply_text("Todavía no sé dónde queda su finca. Por favor use /registrar primero.")
        return

    muns = weather_svc.get_municipios()
    # Búsqueda insensible a mayúsculas
    data = next((v for k, v in muns.items() if k.lower() == finca['municipio'].lower()), muns.get("Pasto"))
    forecast = await weather_svc.get_forecast(data['lat'], data['lon'])
    
    if forecast:
        today = forecast['daily']
        temp_min = today['temperature_2m_min'][0]
        # Humedad estimada ( Open-Meteo daily no da humedad media fácilmente sin más params, usamos rain_prob como proxy )
        rain_prob = today['precipitation_probability_mean'][0]
        
        res = frost_svc.predict(
            altitud=finca['altitud'],
            temp_min=temp_min,
            humedad=80 if rain_prob > 50 else 40,
            mes=datetime.datetime.now().month
        )
        
        msg = (
            f"📊 *Reporte de Helada para {finca['municipio']}*\n"
            f"Riesgo: *{res['level']}*\n"
            f"Confianza: {res['confidence']}\n\n"
            f"💡 *Recomendación:* {res['recommendation']}\n"
            f"Factores: {', '.join(res['factors'])}"
        )
        await update.message.reply_text(msg, parse_mode='Markdown')

async def fumigar(update: Update, context: ContextTypes.DEFAULT_TYPE):
    finca = await get_user_finca(context)
    if not finca:
        await update.message.reply_text("Por favor use /registrar para saber el clima de su zona.")
        return

    muns = weather_svc.get_municipios()
    data = next((v for k, v in muns.items() if k.lower() == finca['municipio'].lower()), muns.get("Pasto"))
    forecast = await weather_svc.get_forecast(data['lat'], data['lon'])
    
    if forecast:
        today = forecast['daily']
        wind = today['windspeed_10m_max'][0]
        rain = today['precipitation_probability_mean'][0]
        
        res = spray_svc.is_good_to_spray(wind, rain)
        await update.message.reply_text(
            f"💊 *¿Se puede fumigar hoy?*\n\n{res['message']}\n"
            f"🕒 *Mejor hora:* {res['best_time']}",
            parse_mode='Markdown'
        )

async def hoy(update: Update, context: ContextTypes.DEFAULT_TYPE):
    finca = await get_user_finca(context)
    if not finca:
        await update.message.reply_text("Use /registrar para ver el clima de su vereda.")
        return

    muns = weather_svc.get_municipios()
    data = next((v for k, v in muns.items() if k.lower() == finca['municipio'].lower()), muns.get("Pasto"))
    forecast = await weather_svc.get_forecast(data['lat'], data['lon'])
    
    if forecast:
        d = forecast['daily']
        msg = (
            f"☀️ *Clima de Hoy en {finca['municipio']}*\n"
            f"🌡️ T. Mín: {d['temperature_2m_min'][0]}°C\n"
            f"🔥 T. Máx: {d['temperature_2m_max'][0]}°C\n"
            f"🌧️ Prob. Lluvia: {d['precipitation_probability_mean'][0]}%\n"
            f"💨 Viento: {d['windspeed_10m_max'][0]} km/h"
        )
        await update.message.reply_text(msg, parse_mode='Markdown')

async def semana(update: Update, context: ContextTypes.DEFAULT_TYPE):
    finca = await get_user_finca(context)
    if not finca:
        await update.message.reply_text("Use /registrar primero.")
        return

    muns = weather_svc.get_municipios()
    data = next((v for k, v in muns.items() if k.lower() == finca['municipio'].lower()), muns.get("Pasto"))
    forecast = await weather_svc.get_forecast(data['lat'], data['lon'])
    
    if forecast:
        d = forecast['daily']
        lines = [f"📅 *Semana en {finca['municipio']}*"]
        days = ["Lun", "Mar", "Mie", "Jue", "Vie", "Sab", "Dom"]
        start_day = datetime.datetime.now().weekday()
        
        for i in range(7):
            day_name = days[(start_day + i) % 7]
            tmin = d['temperature_2m_min'][i]
            rain = d['precipitation_probability_mean'][i]
            emoji = "☀️" if rain < 20 else "🌤️" if rain < 50 else "🌧️"
            frost = "🔴" if tmin < 3 else "🟡" if tmin < 6 else "🟢"
            lines.append(f"{day_name}: {emoji} {tmin}°C {frost}")
            
        await update.message.reply_text("\n".join(lines), parse_mode='Markdown')

# Crop Handlers
async def papa(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text(CULTIVOS['papa'], parse_mode='Markdown')

async def mora(update: Update, context: Update):
    await update.message.reply_text(CULTIVOS['mora'], parse_mode='Markdown')

async def cafe(update: Update, context: Update):
    await update.message.reply_text(CULTIVOS['cafe'], parse_mode='Markdown')

# Registration Flow
async def registrar(update: Update, context: ContextTypes.DEFAULT_TYPE):
    muns = list(weather_svc.get_municipios().keys())
    reply_keyboard = [muns[i:i+2] for i in range(0, len(muns), 2)]
    
    await update.message.reply_text(
        "¡Listo! Vamos a registrar su finca. 🏡\n¿En qué municipio queda?",
        reply_markup=ReplyKeyboardMarkup(reply_keyboard, one_time_keyboard=True),
    )
    return MUNICIPIO

async def reg_municipio(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data['temp_reg'] = {'municipio': update.message.text}
    await update.message.reply_text(
        "¿Y cómo se llama su vereda?",
        reply_markup=ReplyKeyboardRemove(),
    )
    return VEREDA

async def reg_vereda(update: Update, context: ContextTypes.DEFAULT_TYPE):
    context.user_data['temp_reg']['vereda'] = update.message.text
    muns = weather_svc.get_municipios()
    # Buscar ignorando mayúsculas, si no se encuentra usar 2500 como default
    mun_data = next((v for k, v in muns.items() if k.lower() == context.user_data['temp_reg']['municipio'].lower()), {})
    def_alt = mun_data.get('altitud', 2500)
    
    await update.message.reply_text(
        f"¿A qué altitud está su finca? (En metros)\n"
        f"Por defecto en este municipio es {def_alt}m. Escriba el número:",
    )
    return ALTITUD

async def reg_altitud(update: Update, context: ContextTypes.DEFAULT_TYPE):
    try:
        alt = int(update.message.text)
        context.user_data['finca'] = context.user_data['temp_reg']
        context.user_data['finca']['altitud'] = alt
        
        await update.message.reply_text(
            "✅ ¡Finca registrada con éxito!\n"
            "Ya puede usar comandos como /helada o /hoy para estar al tanto de su campo."
        )
    except:
        await update.message.reply_text("Por favor escriba solo el número de la altitud.")
        return ALTITUD
        
    return ConversationHandler.END

async def cancel(update: Update, context: ContextTypes.DEFAULT_TYPE):
    await update.message.reply_text("Registro cancelado.", reply_markup=ReplyKeyboardRemove())
    return ConversationHandler.END

# NLP Handler
async def handle_nlp(update: Update, context: ContextTypes.DEFAULT_TYPE):
    text = update.message.text
    
    # Mostrar un indicador de "escribiendo..." si la IA tarda un poquito
    await context.bot.send_chat_action(chat_id=update.effective_chat.id, action='typing')
    
    intent = nlp_svc.analyze_intent(text)
    
    if intent == "HELADA":
        await helada(update, context)
    elif intent == "FUMIGAR":
        await fumigar(update, context)
    elif intent == "CLIMA_HOY":
        await hoy(update, context)
    elif intent == "CLIMA_SEMANA":
        await semana(update, context)
    elif intent == "AYUDA":
        await help_command(update, context)
    else:
        # Fallback inteligente
        await update.message.reply_text(
            "Mmm... creo que no le entendí bien, patroncito. 🤔\n"
            "Puede preguntarme directamente sobre heladas, fumigación o el clima. "
            "Si soy yo el que está despistado, escriba /ayuda para ver todos mis comandos."
        )
