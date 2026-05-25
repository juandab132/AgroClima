import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

# Forzar modo sin API key para usar el fallback por palabras clave
os.environ.pop("GEMINI_API_KEY", None)

import pytest
from bot.services.nlp_engine import NLPEngine


class TestNLPEngineFallback:
    """Tests del motor NLP en modo fallback (sin API key) — AGRO-16"""

    def setup_method(self):
        self.nlp = NLPEngine()

    def test_detecta_intencion_helada(self):
        assert self.nlp.analyze_intent("¿va a hacer helada esta noche?") == "HELADA"
        assert self.nlp.analyze_intent("mucho frío esta madrugada") == "HELADA"
        assert self.nlp.analyze_intent("cae hielo en el encano?") == "HELADA"

    def test_detecta_intencion_fumigar(self):
        assert self.nlp.analyze_intent("¿puedo fumigar hoy?") == "FUMIGAR"
        assert self.nlp.analyze_intent("quiero pulverizar el cultivo") == "FUMIGAR"
        assert self.nlp.analyze_intent("voy a echar veneno a la papa") == "FUMIGAR"

    def test_detecta_intencion_clima_hoy(self):
        assert self.nlp.analyze_intent("¿va a llover hoy?") == "CLIMA_HOY"
        assert self.nlp.analyze_intent("está lloviendo ahora?") == "CLIMA_HOY"
        assert self.nlp.analyze_intent("¿cae agua hoy?") == "CLIMA_HOY"

    def test_detecta_intencion_clima_semana(self):
        assert self.nlp.analyze_intent("cómo está el clima esta semana?") == "CLIMA_SEMANA"
        assert self.nlp.analyze_intent("pronóstico para los próximos días") == "CLIMA_SEMANA"
        assert self.nlp.analyze_intent("¿cómo va a estar el tiempo?") == "CLIMA_SEMANA"

    def test_detecta_intencion_ayuda(self):
        assert self.nlp.analyze_intent("ayuda") == "AYUDA"
        assert self.nlp.analyze_intent("qué haces?") == "AYUDA"
        assert self.nlp.analyze_intent("comandos") == "AYUDA"

    def test_detecta_intencion_desconocida(self):
        assert self.nlp.analyze_intent("cuánto cuesta el kilo de papa?") == "DESCONOCIDO"
        assert self.nlp.analyze_intent("xyzabc") == "DESCONOCIDO"

    def test_respuesta_es_siempre_string(self):
        intenciones = [
            "helada esta noche",
            "fumigar mañana",
            "llover hoy",
            "clima semana",
            "ayuda",
            "texto irrelevante",
        ]
        for texto in intenciones:
            result = self.nlp.analyze_intent(texto)
            assert isinstance(result, str)
            assert len(result) > 0
