import sys
import os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..'))

import pytest
from bot.services.frost_predictor import FrostPredictor, SprayPredictor


class TestFrostPredictor:
    """Tests unitarios de FrostPredictor — AGRO-16"""

    def setup_method(self):
        self.predictor = FrostPredictor()

    def test_temperatura_bajo_cero_es_riesgo_alto(self):
        result = self.predictor.predict(altitud=2500, temp_min=-1.0, humedad=60, mes=1)
        assert "ALTO" in result["level"]

    def test_altitud_alta_con_temp_baja_es_riesgo_alto(self):
        result = self.predictor.predict(altitud=3200, temp_min=1.0, humedad=60, mes=1)
        assert result["level"] in ["ALTO 🔴", "MEDIO 🟡"]

    def test_condiciones_normales_es_riesgo_bajo(self):
        result = self.predictor.predict(altitud=1800, temp_min=14.0, humedad=75, mes=5)
        assert "BAJO" in result["level"]

    def test_confianza_en_rango_valido(self):
        result = self.predictor.predict(altitud=2500, temp_min=5.0, humedad=60, mes=6)
        confianza = int(result["confidence"].replace("%", ""))
        assert 55 <= confianza <= 95

    def test_recomendacion_no_vacia(self):
        result = self.predictor.predict(altitud=2500, temp_min=3.0, humedad=60, mes=3)
        assert len(result["recommendation"]) > 0

    def test_factores_no_vacios(self):
        result = self.predictor.predict(altitud=3100, temp_min=-2.0, humedad=50, mes=1)
        assert len(result["factors"]) > 0

    def test_riesgo_alto_incluye_advertencia(self):
        result = self.predictor.predict(altitud=3100, temp_min=-2.0, humedad=50, mes=1)
        assert "ALTO" in result["level"]
        assert "🔴" in result["level"]

    def test_mes_seco_nariño_aumenta_riesgo(self):
        # Mes seco (enero) vs mes lluvioso (abril) con mismas condiciones
        result_seco = self.predictor.predict(altitud=2500, temp_min=4.0, humedad=60, mes=1)
        result_lluvioso = self.predictor.predict(altitud=2500, temp_min=4.0, humedad=60, mes=4)
        # El mes seco debe tener riesgo mayor o igual
        niveles = {"BAJO 🟢": 0, "MEDIO 🟡": 1, "ALTO 🔴": 2}
        nivel_seco = niveles.get(result_seco["level"], -1)
        nivel_lluvioso = niveles.get(result_lluvioso["level"], -1)
        assert nivel_seco >= nivel_lluvioso

    def test_cielo_despejado_y_seco_suma_riesgo(self):
        # Humedad baja + nubosidad baja = riesgo de helada radiativa
        result = self.predictor.predict(
            altitud=2800, temp_min=3.0, humedad=30, mes=6, nubosidad=20.0
        )
        assert any("radiativa" in f.lower() or "despejado" in f.lower()
                   for f in result["factors"])


class TestSprayPredictor:
    """Tests unitarios de SprayPredictor — AGRO-16"""

    def setup_method(self):
        self.predictor = SprayPredictor()

    def test_condiciones_ideales_retorna_si(self):
        result = self.predictor.is_good_to_spray(wind_speed=10.0, rain_prob=20)
        assert result["is_good"] is True
        assert "SÍ" in result["message"]

    def test_viento_fuerte_retorna_no(self):
        result = self.predictor.is_good_to_spray(wind_speed=25.0, rain_prob=10)
        assert result["is_good"] is False
        assert "viento" in result["message"].lower()

    def test_mucha_lluvia_retorna_no(self):
        result = self.predictor.is_good_to_spray(wind_speed=10.0, rain_prob=80)
        assert result["is_good"] is False
        assert "lluvia" in result["message"].lower() or "agua" in result["message"].lower()

    def test_mejor_hora_siempre_presente(self):
        result = self.predictor.is_good_to_spray(wind_speed=5.0, rain_prob=10)
        assert "best_time" in result
        assert len(result["best_time"]) > 0

    def test_viento_limite_19kmh_es_aceptable(self):
        result = self.predictor.is_good_to_spray(wind_speed=19.0, rain_prob=30)
        assert result["is_good"] is True

    def test_viento_limite_20kmh_no_es_aceptable(self):
        result = self.predictor.is_good_to_spray(wind_speed=20.0, rain_prob=30)
        assert result["is_good"] is False
