package com.photoalbum.telemetry;

import jakarta.servlet.http.HttpSessionEvent;
import jakarta.servlet.http.HttpSessionListener;

public class SessionLifecycleListener implements HttpSessionListener {

    private static final String SESSION_START_ATTR = "telemetry.session.startMs";
    private static final String VISITOR_ATTR = "telemetry.visitorId";

    private final AppTelemetryService telemetryService;

    public SessionLifecycleListener(AppTelemetryService telemetryService) {
        this.telemetryService = telemetryService;
    }

    @Override
    public void sessionDestroyed(HttpSessionEvent se) {
        Object startObj = se.getSession().getAttribute(SESSION_START_ATTR);
        if (!(startObj instanceof Long)) {
            return;
        }

        long sessionDurationMs = System.currentTimeMillis() - (Long) startObj;
        String visitorId = "unknown";
        Object visitorObj = se.getSession().getAttribute(VISITOR_ATTR);
        if (visitorObj != null && !visitorObj.toString().isBlank()) {
            visitorId = visitorObj.toString();
        }

        telemetryService.trackSessionEnded(se.getSession().getId(), visitorId, sessionDurationMs);
    }
}
