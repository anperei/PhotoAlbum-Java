package com.photoalbum.telemetry;

import com.microsoft.applicationinsights.TelemetryClient;
import com.microsoft.applicationinsights.TelemetryConfiguration;
import com.microsoft.applicationinsights.telemetry.Duration;
import com.microsoft.applicationinsights.telemetry.RequestTelemetry;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;

@Service
public class AppTelemetryService {

    private static final Logger logger = LoggerFactory.getLogger(AppTelemetryService.class);

    private final TelemetryClient telemetryClient;
    private final boolean telemetryEnabled;

    public AppTelemetryService() {
        String connectionString = System.getenv("APPLICATIONINSIGHTS_CONNECTION_STRING");
        String instrumentationKey = extractInstrumentationKey(connectionString);

        if (isBlank(instrumentationKey)) {
            this.telemetryEnabled = false;
            this.telemetryClient = null;
            logger.warn("Application Insights instrumentation key was not resolved. Telemetry events will be logged locally only.");
            return;
        }

        TelemetryConfiguration configuration = TelemetryConfiguration.getActive();
        configuration.setInstrumentationKey(instrumentationKey);
        this.telemetryClient = new TelemetryClient(configuration);
        this.telemetryEnabled = true;
        logger.info("Application Insights telemetry initialized.");
    }

    public void trackUploadBatch(
            String sessionId,
            String visitorId,
            int requestedCount,
            int uploadedCount,
            int failedCount,
            long durationMs) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("requestedCount", Integer.toString(requestedCount));
        attributes.put("uploadedCount", Integer.toString(uploadedCount));
        attributes.put("failedCount", Integer.toString(failedCount));
        attributes.put("durationMs", Long.toString(durationMs));
        attributes.put("result", failedCount > 0 ? "partial" : "success");

        Map<String, Double> metrics = new HashMap<String, Double>();
        metrics.put("requestedCount", (double) requestedCount);
        metrics.put("uploadedCount", (double) uploadedCount);
        metrics.put("failedCount", (double) failedCount);
        metrics.put("durationMs", (double) durationMs);

        trackEvent("photo.upload.batch", attributes, metrics);

        logger.info(
                "telemetry_event name=photo.upload.batch sessionId={} visitorId={} requestedCount={} uploadedCount={} failedCount={} durationMs={} result={}",
                sessionId,
                visitorId,
                requestedCount,
                uploadedCount,
                failedCount,
                durationMs,
                attributes.get("result"));
    }

    public void trackUploadFile(
            String sessionId,
            String visitorId,
            String fileName,
            String mimeType,
            long fileSizeBytes,
            long durationMs,
            boolean success,
            String errorMessage) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("fileName", fallback(fileName));
        attributes.put("mimeType", fallback(mimeType));
        attributes.put("fileSizeBytes", Long.toString(fileSizeBytes));
        attributes.put("durationMs", Long.toString(durationMs));
        attributes.put("result", success ? "success" : "failure");
        if (!success && errorMessage != null) {
            attributes.put("error", errorMessage);
        }

        Map<String, Double> metrics = new HashMap<String, Double>();
        metrics.put("fileSizeBytes", (double) fileSizeBytes);
        metrics.put("durationMs", (double) durationMs);

        trackEvent("photo.upload.file", attributes, metrics);
        if (!success && errorMessage != null) {
            trackException(new RuntimeException(errorMessage), attributes);
        }

        logger.info(
                "telemetry_event name=photo.upload.file sessionId={} visitorId={} fileName={} mimeType={} fileSizeBytes={} durationMs={} result={} error={}",
                sessionId,
                visitorId,
                attributes.get("fileName"),
                attributes.get("mimeType"),
                fileSizeBytes,
                durationMs,
                attributes.get("result"),
                attributes.getOrDefault("error", ""));
    }

    public void trackDelete(
            String sessionId,
            String visitorId,
            String photoId,
            String fileName,
            long durationMs,
            boolean success,
            String errorMessage) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("photoId", fallback(photoId));
        attributes.put("fileName", fallback(fileName));
        attributes.put("durationMs", Long.toString(durationMs));
        attributes.put("result", success ? "success" : "failure");
        if (!success && errorMessage != null) {
            attributes.put("error", errorMessage);
        }

        Map<String, Double> metrics = new HashMap<String, Double>();
        metrics.put("durationMs", (double) durationMs);

        trackEvent("photo.delete", attributes, metrics);
        if (!success && errorMessage != null) {
            trackException(new RuntimeException(errorMessage), attributes);
        }

        logger.info(
                "telemetry_event name=photo.delete sessionId={} visitorId={} photoId={} fileName={} durationMs={} result={} error={}",
                sessionId,
                visitorId,
                attributes.get("photoId"),
                attributes.get("fileName"),
                durationMs,
                attributes.get("result"),
                attributes.getOrDefault("error", ""));
    }

    public void trackSessionStarted(String sessionId, String visitorId) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("result", "started");

        trackEvent("photo.session.started", attributes, null);

        logger.info("telemetry_event name=photo.session.started sessionId={} visitorId={}", sessionId, visitorId);
    }

    public void trackSessionActivity(
            String sessionId,
            String visitorId,
            String method,
            String path,
            int statusCode,
            long requestDurationMs,
            long sessionDurationMs) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("method", fallback(method));
        attributes.put("path", fallback(path));
        attributes.put("statusCode", Integer.toString(statusCode));
        attributes.put("requestDurationMs", Long.toString(requestDurationMs));
        attributes.put("sessionDurationMs", Long.toString(sessionDurationMs));

        Map<String, Double> metrics = new HashMap<String, Double>();
        metrics.put("statusCode", (double) statusCode);
        metrics.put("requestDurationMs", (double) requestDurationMs);
        metrics.put("sessionDurationMs", (double) sessionDurationMs);

        trackEvent("photo.session.activity", attributes, metrics);

        logger.info(
                "telemetry_event name=photo.session.activity sessionId={} visitorId={} method={} path={} statusCode={} requestDurationMs={} sessionDurationMs={}",
                sessionId,
                visitorId,
                attributes.get("method"),
                attributes.get("path"),
                statusCode,
                requestDurationMs,
                sessionDurationMs);
    }

    public void trackRequest(String method, String path, int statusCode, long requestDurationMs) {
        if (!telemetryEnabled) {
            return;
        }

        String normalizedMethod = fallback(method);
        String normalizedPath = fallback(path);
        String requestName = normalizedMethod + " " + normalizedPath;
        boolean success = statusCode < 400;

        RequestTelemetry requestTelemetry = new RequestTelemetry();
        requestTelemetry.setName(requestName);
        requestTelemetry.setDuration(new Duration(requestDurationMs));
        requestTelemetry.setResponseCode(Integer.toString(statusCode));
        requestTelemetry.setSuccess(success);

        telemetryClient.trackRequest(requestTelemetry);
        telemetryClient.flush();
    }

    public void trackSessionEnded(String sessionId, String visitorId, long totalSessionDurationMs) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("totalSessionDurationMs", Long.toString(totalSessionDurationMs));

        Map<String, Double> metrics = new HashMap<String, Double>();
        metrics.put("totalSessionDurationMs", (double) totalSessionDurationMs);

        trackEvent("photo.session.ended", attributes, metrics);

        logger.info(
                "telemetry_event name=photo.session.ended sessionId={} visitorId={} totalSessionDurationMs={}",
                sessionId,
                visitorId,
                totalSessionDurationMs);
    }

    private Map<String, String> baseAttributes(String sessionId, String visitorId) {
        Map<String, String> attributes = new HashMap<String, String>();
        attributes.put("sessionId", fallback(sessionId));
        attributes.put("visitorId", fallback(visitorId));
        return attributes;
    }

    private void trackEvent(String name, Map<String, String> properties, Map<String, Double> metrics) {
        if (!telemetryEnabled) {
            return;
        }

        telemetryClient.trackEvent(name, properties, metrics);
        telemetryClient.flush();
    }

    private void trackException(Exception exception, Map<String, String> properties) {
        if (!telemetryEnabled) {
            return;
        }

        telemetryClient.trackException(exception, properties, null);
        telemetryClient.flush();
    }

    private static String extractInstrumentationKey(String connectionString) {
        if (isBlank(connectionString)) {
            return null;
        }

        String[] pairs = connectionString.split(";");
        for (int i = 0; i < pairs.length; i++) {
            String pair = pairs[i];
            if (pair == null) {
                continue;
            }
            String trimmed = pair.trim();
            if (trimmed.startsWith("InstrumentationKey=")) {
                return trimmed.substring("InstrumentationKey=".length()).trim();
            }
        }
        return null;
    }

    private static String fallback(String value) {
        return isBlank(value) ? "unknown" : value;
    }

    private static boolean isBlank(String value) {
        return value == null || value.trim().isEmpty();
    }
}
