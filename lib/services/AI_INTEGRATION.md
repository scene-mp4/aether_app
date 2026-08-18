AI Assistant integration notes

Overview
- `AiService` is a minimal placeholder used by the `AiAssistant` widget.
- Replace the placeholder `query()` implementation with real calls to Google
  Gemini (or another LLM) and inject app context (AQI, pollutant readings, etc.)

Recommended approach
1. Securely store API credentials (do NOT hardcode keys). Use platform
   secure storage or server-side proxy.
2. Build a context object from your app state (for example, from
   `AppDataStore`) containing the latest tracker values: AQI, PM2.5, PM10,
   CO, CO2, temperature, humidity, tracker name and location.
3. When querying, pass a structured prompt + context to the model. Example:

  "System: You are AETHER assistant helping users with air quality.\n"
  "Context: {tracker: 'Tracker 6', aqi: 352, pm2_5: 220, co2: 5500} \n"
  "User: How worried should I be about the current air?"

4. Use streaming responses where available to improve UX.

Security & cost
- Throttle queries and add rate limiting.
- Consider a server-side mediator to avoid shipping secrets in the app.

Example TODOs
- Implement Gemini client in `AiService.query()` using HTTP or an SDK.
- Add a small adapter method in `AppDataStore` to produce the context payload.
- Improve UI to show suggestions, quick prompts, and helpful links.
