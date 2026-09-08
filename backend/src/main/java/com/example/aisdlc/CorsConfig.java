package com.example.aisdlc;

import java.util.List;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.filter.CorsFilter;

/**
 * Allows the Flutter web app (served by `flutter run` on a random localhost
 * port) to call backend endpoints from the browser. Without this, the browser
 * blocks the health check as cross-origin and the smoke screen (story #1 AC5)
 * shows "Cannot reach the backend" on the web platform. Native platforms
 * (Android/iOS/macOS) are unaffected by CORS.
 *
 * Localhost origins only, any port — deliberately narrow for a scaffold.
 */
@Configuration
public class CorsConfig {

    @Bean
    CorsFilter corsFilter() {
        var config = new CorsConfiguration();
        config.setAllowedOriginPatterns(List.of("http://localhost:*", "http://127.0.0.1:*"));
        config.setAllowedMethods(List.of("GET"));
        var source = new org.springframework.web.cors.UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", config);
        return new CorsFilter(source);
    }
}
