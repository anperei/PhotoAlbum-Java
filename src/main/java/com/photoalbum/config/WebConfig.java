package com.photoalbum.config;

import com.photoalbum.telemetry.AppTelemetryService;
import com.photoalbum.telemetry.SessionLifecycleListener;
import com.photoalbum.telemetry.SessionTelemetryInterceptor;
import org.springframework.boot.web.servlet.ServletListenerRegistrationBean;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final SessionTelemetryInterceptor sessionTelemetryInterceptor;

    public WebConfig(SessionTelemetryInterceptor sessionTelemetryInterceptor) {
        this.sessionTelemetryInterceptor = sessionTelemetryInterceptor;
    }

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(sessionTelemetryInterceptor)
                .addPathPatterns("/", "/detail/**", "/upload");
    }

    @Bean
    public ServletListenerRegistrationBean<SessionLifecycleListener> sessionLifecycleListener(
            AppTelemetryService telemetryService) {
        return new ServletListenerRegistrationBean<SessionLifecycleListener>(
                new SessionLifecycleListener(telemetryService));
    }
}
