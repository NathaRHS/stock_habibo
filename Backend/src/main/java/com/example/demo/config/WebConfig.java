package com.example.demo.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {

    private final JournalUserInterceptor journalUserInterceptor;

    public WebConfig(JournalUserInterceptor journalUserInterceptor) {
        this.journalUserInterceptor = journalUserInterceptor;
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOriginPatterns("http://localhost:*", "http://127.0.0.1:*", "https://*.devtunnels.ms")
                .allowedMethods("GET", "POST", "PUT", "PATCH", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .maxAge(3600);
    }

    // Journal d'activite : enregistre les actions d'administration des referentiels.
    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        registry.addInterceptor(journalUserInterceptor);
    }
}
