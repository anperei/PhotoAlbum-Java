package com.photoalbum.telemetry;

import jakarta.servlet.http.Cookie;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import jakarta.servlet.http.HttpSession;
import org.springframework.lang.Nullable;
import org.springframework.stereotype.Component;
import org.springframework.web.servlet.HandlerInterceptor;

import java.util.UUID;

@Component
public class SessionTelemetryInterceptor implements HandlerInterceptor {

    private static final String VISITOR_COOKIE = "photoalbum_visitor";
    private static final String REQUEST_START_ATTR = "telemetry.request.startMs";
    private static final String SESSION_START_ATTR = "telemetry.session.startMs";
    private static final String VISITOR_ATTR = "telemetry.visitorId";

    private final AppTelemetryService telemetryService;

    public SessionTelemetryInterceptor(AppTelemetryService telemetryService) {
        this.telemetryService = telemetryService;
    }

    @Override
    public boolean preHandle(HttpServletRequest request, HttpServletResponse response, Object handler) {
        long now = System.currentTimeMillis();
        request.setAttribute(REQUEST_START_ATTR, now);

        HttpSession session = request.getSession(true);
        String sessionId = session.getId();

        String visitorId = resolveOrCreateVisitorId(request, response);
        session.setAttribute(VISITOR_ATTR, visitorId);
        request.setAttribute(VISITOR_ATTR, visitorId);

        if (session.getAttribute(SESSION_START_ATTR) == null) {
            session.setAttribute(SESSION_START_ATTR, now);
            telemetryService.trackSessionStarted(sessionId, visitorId);
        }

        return true;
    }

    @Override
    public void afterCompletion(
            HttpServletRequest request,
            HttpServletResponse response,
            Object handler,
            @Nullable Exception ex) {
        HttpSession session = request.getSession(false);
        if (session == null) {
            return;
        }

        Object requestStartObj = request.getAttribute(REQUEST_START_ATTR);
        Object sessionStartObj = session.getAttribute(SESSION_START_ATTR);

        if (!(requestStartObj instanceof Long) || !(sessionStartObj instanceof Long)) {
            return;
        }

        long now = System.currentTimeMillis();
        long requestDurationMs = now - (Long) requestStartObj;
        long sessionDurationMs = now - (Long) sessionStartObj;

        String sessionId = session.getId();
        String visitorId = toStringOrUnknown(session.getAttribute(VISITOR_ATTR));

        telemetryService.trackSessionActivity(
                sessionId,
                visitorId,
                request.getMethod(),
                request.getRequestURI(),
                response.getStatus(),
                requestDurationMs,
                sessionDurationMs);

        telemetryService.trackRequest(
            request.getMethod(),
            request.getRequestURI(),
            response.getStatus(),
            requestDurationMs);
    }

    private String resolveOrCreateVisitorId(HttpServletRequest request, HttpServletResponse response) {
        if (request.getCookies() != null) {
            for (Cookie cookie : request.getCookies()) {
                if (VISITOR_COOKIE.equals(cookie.getName()) && cookie.getValue() != null && !cookie.getValue().isBlank()) {
                    return cookie.getValue();
                }
            }
        }

        String visitorId = UUID.randomUUID().toString();
        Cookie cookie = new Cookie(VISITOR_COOKIE, visitorId);
        cookie.setHttpOnly(true);
        cookie.setPath("/");
        cookie.setMaxAge(60 * 60 * 24 * 365);
        cookie.setSecure(request.isSecure());
        response.addCookie(cookie);

        return visitorId;
    }

    private String toStringOrUnknown(Object value) {
        if (value == null) {
            return "unknown";
        }
        String text = value.toString();
        return text.isBlank() ? "unknown" : text;
    }
}
