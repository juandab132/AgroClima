from datetime import datetime

class FrostPredictor:
    def predict(self, altitud: int, temp_min: float, humedad: float, mes: int, nubosidad: float = 40.0):
        risk = 0
        factors = []

        # Factor 1: Altitud
        if altitud > 3000:
            risk += 3
            factors.append('Altitud muy alta (más de 3.000m)')
        elif altitud > 2500:
            risk += 2
            factors.append('Altitud alta')
        elif altitud > 2000:
            risk += 1

        # Factor 2: Temperatura mínima
        if temp_min < 0:
            risk += 6
            factors.append('Temperatura bajo cero ❄️')
        elif temp_min < 2:
            risk += 3
            factors.append('Temperatura muy peligrosa')
        elif temp_min < 4:
            risk += 2
            factors.append('Temperatura baja')
        elif temp_min < 7:
            risk += 1
        else:
            risk -= 1

        # Factor 3: Cielo despejado (helada radiativa)
        if humedad < 40 and nubosidad < 30:
            risk += 2
            factors.append('Cielo despejado y seco — riesgo de helada radiativa')

        # Factor 4: Mes seco de Nariño
        if mes in [1, 2, 6, 7, 8, 12]:
            risk += 1

        risk = max(0, min(10, risk))

        if risk >= 6:
            level = "ALTO 🔴"
            recommendation = "⚠️ ¡Protege tus cultivos antes de las 6pm! Cubre la papa y la mora."
        elif risk >= 3:
            level = "MEDIO 🟡"
            recommendation = "🌡️ Esté pendiente esta noche. Revise a las 9pm."
        else:
            level = "BAJO 🟢"
            recommendation = "✅ Sin riesgo hoy. Buena noche para sus cultivos."

        confidence = max(0.55, min(0.95, (55 + risk * 4) / 100.0))

        return {
            "level": level,
            "confidence": f"{int(confidence * 100)}%",
            "factors": factors if factors else ["Condiciones normales"],
            "recommendation": recommendation
        }

class SprayPredictor:
    def is_good_to_spray(self, wind_speed: float, rain_prob: float):
        wind_ok = wind_speed < 20
        rain_ok = rain_prob < 40
        is_good = wind_ok and rain_ok

        if is_good:
            msg = "✅ SÍ — Condiciones ideales. El viento está calmado y no hay lluvia."
        elif not wind_ok:
            msg = "❌ NO — Viento muy fuerte. El veneno se lo lleva el viento."
        else:
            msg = "❌ NO — Mucha lluvia. El agua lava el producto."

        return {
            "is_good": is_good,
            "message": msg,
            "best_time": "7–10am o después de las 4pm"
        }
