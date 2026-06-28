package com.photoalbum.telemetry;

import io.micrometer.core.instrument.MeterRegistry;
import io.opentelemetry.api.GlobalOpenTelemetry;
import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.api.trace.StatusCode;
import io.opentelemetry.api.trace.Tracer;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;

import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.TimeUnit;

@Service
public class AppTelemetryService {

    private static final Logger logger = LoggerFactory.getLogger(AppTelemetryService.class);

    private final MeterRegistry meterRegistry;
    private final Tracer tracer;

    public AppTelemetryService(MeterRegistry meterRegistry) {
        this.meterRegistry = meterRegistry;
        this.tracer = GlobalOpenTelemetry.getTracer("com.photoalbum.telemetry", "1.0.0");
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

        recordSpan("photo.upload.batch", attributes, null);

        meterRegistry.counter("photo.upload.batch.count", "result", attributes.get("result")).increment();
        meterRegistry.summary("photo.upload.batch.size").record(requestedCount);
        meterRegistry.timer("photo.upload.batch.duration", "result", attributes.get("result"))
                .record(durationMs, TimeUnit.MILLISECONDS);

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

        recordSpan("photo.upload.file", attributes, success ? null : new RuntimeException(fallback(errorMessage)));

        meterRegistry.counter("photo.upload.file.count", "result", attributes.get("result"), "mimeType", attributes.get("mimeType"))
                .increment();
        meterRegistry.summary("photo.upload.file.size", "mimeType", attributes.get("mimeType")).record(fileSizeBytes);
        meterRegistry.timer("photo.upload.file.duration", "result", attributes.get("result"))
                .record(durationMs, TimeUnit.MILLISECONDS);

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

        recordSpan("photo.delete", attributes, success ? null : new RuntimeException(fallback(errorMessage)));

        meterRegistry.counter("photo.delete.count", "result", attributes.get("result")).increment();
        meterRegistry.timer("photo.delete.duration", "result", attributes.get("result"))
                .record(durationMs, TimeUnit.MILLISECONDS);

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

        recordSpan("photo.session.started", attributes, null);
        meterRegistry.counter("photo.session.started.count").increment();

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

        recordSpan("photo.session.activity", attributes, null);

        meterRegistry.timer("photo.request.duration", "method", attributes.get("method"), "path", attributes.get("path"))
                .record(requestDurationMs, TimeUnit.MILLISECONDS);
        meterRegistry.summary("photo.session.duration").record(sessionDurationMs);

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

    public void trackSessionEnded(String sessionId, String visitorId, long totalSessionDurationMs) {
        Map<String, String> attributes = baseAttributes(sessionId, visitorId);
        attributes.put("totalSessionDurationMs", Long.toString(totalSessionDurationMs));

        recordSpan("photo.session.ended", attributes, null);
        meterRegistry.summary("photo.session.total-duration").record(totalSessionDurationMs);

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

    private void recordSpan(String spanName, Map<String, String> attributes, Throwable throwable) {
        Span span = tracer.spanBuilder(spanName).setSpanKind(SpanKind.INTERNAL).startSpan();
        try {
            for (Map.Entry<String, String> entry : attributes.entrySet()) {
                if (entry.getValue() != null) {
                    span.setAttribute(entry.getKey(), entry.getValue());
                }
            }
            if (throwable != null) {
                span.recordException(throwable);
                span.setStatus(StatusCode.ERROR, throwable.getMessage());
            }
        } finally {
            span.end();
        }
    }

    private String fallback(String value) {
        return value == null || value.isBlank() ? "unknown" : value;
    }
}
