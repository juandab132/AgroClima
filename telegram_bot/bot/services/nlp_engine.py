import os
import google.generativeai as genai

class NLPEngine:
    def __init__(self):
        self.api_key = os.getenv("GEMINI_API_KEY")
        self.is_enabled = bool(self.api_key)
        if self.is_enabled:
            genai.configure(api_key=self.api_key)
            # Usar modelo base flash que es muy rápido y barato
            self.model = genai.GenerativeModel('gemini-1.5-flash')
        else:
            print("⚠️ GEMINI_API_KEY no encontrada. El bot usará NLP básico (búsqueda por palabras clave).")

    def analyze_intent(self, user_text: str) -> str:
        """
        Retorna una de estas intenciones: 
        HELADA, FUMIGAR, CLIMA_HOY, CLIMA_SEMANA, AYUDA, DESCONOCIDO
        """
        # Fallback si no hay API key
        if not self.is_enabled:
            text = user_text.lower()
            if any(word in text for word in ["helada", "frosta", "frío", "frio", "hielo"]): return "HELADA"
            if any(word in text for word in ["fumigar", "pulverizar", "veneno", "agroquímico", "agroquimico"]): return "FUMIGAR"
            if any(word in text for word in ["lluvia", "llover", "agua", "mojar", "hoy", "ahora"]): return "CLIMA_HOY"
            if any(word in text for word in ["clima", "tiempo", "pronóstico", "pronostico", "semana"]): return "CLIMA_SEMANA"
            if any(word in text for word in ["ayuda", "comandos", "qué haces"]): return "AYUDA"
            return "DESCONOCIDO"

        prompt = f"""
Eres el "Cerebro" de un bot de Telegram diseñado para campesinos en Nariño, Colombia.
Tu tarea es leer el mensaje del campesino y clasificar su intención EXACTA en UNA de las siguientes categorías en mayúsculas (y NADA MÁS):

- HELADA: El usuario pregunta si va a hacer mucho frío, si va a caer hielo, escarcha, helada, o si la temperatura va a bajar mucho.
- FUMIGAR: El usuario pregunta si es buen momento para aplicar químicos, veneno, rociar, fumigar, fertilizar foliar.
- CLIMA_HOY: El usuario pregunta por el clima actual, si va a llover, si hace sol hoy o si va a caer agua pronto.
- CLIMA_SEMANA: El usuario pregunta por el pronóstico de varios días, cómo va a estar la semana, el clima general.
- AYUDA: El usuario está saludando, o pidiendo ayuda, o preguntando qué puedes hacer.
- DESCONOCIDO: El usuario habla de un tema que no tiene NADA que ver con agricultura, clima, fumigación o no se entiende.

Responde SOLO con la palabra en MAYÚSCULAS que mejor describa la intención. No añadas puntos ni explicaciones.

Mensaje del usuario: "{user_text}"
Intención:"""

        try:
            response = self.model.generate_content(prompt)
            intent = response.text.strip().upper()
            
            # Limpiar posible basura del LLM
            for valid_intent in ["HELADA", "FUMIGAR", "CLIMA_HOY", "CLIMA_SEMANA", "AYUDA"]:
                if valid_intent in intent:
                    return valid_intent
            
            return "DESCONOCIDO"
        except Exception as e:
            print(f"Error en Gemini API: {e}")
            # Fallback en caso de error de red
            self.is_enabled = False 
            return self.analyze_intent(user_text)

