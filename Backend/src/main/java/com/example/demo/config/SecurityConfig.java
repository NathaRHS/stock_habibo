package com.example.demo.config;

import java.util.ArrayList;
import java.util.Base64;
import java.util.Collection;
import java.util.List;

import javax.crypto.SecretKey;
import javax.crypto.spec.SecretKeySpec;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.HttpMethod;
import org.springframework.security.config.Customizer;
import org.springframework.security.config.annotation.method.configuration.EnableMethodSecurity;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.NimbusJwtDecoder;
import org.springframework.security.oauth2.jwt.NimbusJwtEncoder;
import org.springframework.security.oauth2.server.resource.authentication.JwtAuthenticationConverter;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.web.SecurityFilterChain;

@Configuration
@EnableMethodSecurity
public class SecurityConfig {

    private static final MacAlgorithm JWT_ALGORITHM = MacAlgorithm.HS256;

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .cors(Customizer.withDefaults())
                .csrf(csrf -> csrf.disable())
                .sessionManagement(session -> session
                        .sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(authorize -> authorize

                        // Route publique
                        .requestMatchers(HttpMethod.POST, "/user/login")
                        .permitAll()

                        .requestMatchers("/error")
                        .permitAll()

                        // Toute gestion et consultation des utilisateurs : ADMIN
                        .requestMatchers("/user", "/user/**")
                        .hasRole("ADMIN")

                        // Toutes les créations : ADMIN
                        .requestMatchers(HttpMethod.POST, "/**")
                        .hasRole("ADMIN")

                        // Toutes les modifications : ADMIN
                        .requestMatchers(HttpMethod.PUT, "/**")
                        .hasRole("ADMIN")

                        .requestMatchers(HttpMethod.PATCH, "/**")
                        .hasRole("ADMIN")

                        // Toutes les suppressions : ADMIN
                        .requestMatchers(HttpMethod.DELETE, "/**")
                        .hasRole("ADMIN")

                        // Toutes les lectures restantes : utilisateur connecté
                        .requestMatchers(HttpMethod.GET, "/**")
                        .authenticated()

                        // Sécurité par défaut
                        .anyRequest()
                        .denyAll())
                .oauth2ResourceServer(oauth2 -> oauth2
                        .jwt(jwt -> jwt
                                .jwtAuthenticationConverter(jwtAuthenticationConverter())));

        return http.build();
    }

    @Bean
    SecretKey jwtSecretKey(@Value("${JWT_SECRET}") String encodedSecret) {
        byte[] secretBytes;

        try {
            secretBytes = Base64.getDecoder().decode(encodedSecret);
        } catch (IllegalArgumentException exception) {
            throw new IllegalStateException(
                    "JWT_SECRET doit être une chaîne Base64 valide.", exception);
        }

        if (secretBytes.length < 32) {
            throw new IllegalStateException(
                    "JWT_SECRET doit contenir au moins 32 octets après décodage Base64.");
        }

        return new SecretKeySpec(secretBytes, "HmacSHA256");
    }

    @Bean
    JwtEncoder jwtEncoder(SecretKey jwtSecretKey) {
        return NimbusJwtEncoder.withSecretKey(jwtSecretKey)
                .algorithm(JWT_ALGORITHM)
                .build();
    }

    @Bean
    JwtDecoder jwtDecoder(SecretKey jwtSecretKey) {
        return NimbusJwtDecoder.withSecretKey(jwtSecretKey)
                .macAlgorithm(JWT_ALGORITHM)
                .build();
    }

    @Bean
    JwtAuthenticationConverter jwtAuthenticationConverter() {
        JwtAuthenticationConverter converter = new JwtAuthenticationConverter();

        converter.setJwtGrantedAuthoritiesConverter(jwt -> {
            Collection<String> roles = jwt.getClaimAsStringList("roles");

            List<GrantedAuthority> authorities = new ArrayList<>();

            if (roles == null) {
                return authorities;
            }

            for (String role : roles) {
                String authority;

                if (role.startsWith("ROLE_")) {
                    authority = role;
                } else {
                    authority = "ROLE_" + role;
                }

                authorities.add(
                        new SimpleGrantedAuthority(authority));
            }

            return authorities;
        });

        return converter;
    }
}
