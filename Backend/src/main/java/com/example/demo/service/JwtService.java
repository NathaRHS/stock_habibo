package com.example.demo.service;

import java.time.Duration;
import java.time.Instant;
import java.util.List;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.stereotype.Service;

import com.example.demo.entity.User;

@Service
public class JwtService {

    private final JwtEncoder jwtEncoder;
    private final Duration tokenDuration;

    public JwtService(
            JwtEncoder jwtEncoder,
            @Value("${jwt.expiration:3600}") long expirationSeconds) {
        this.jwtEncoder = jwtEncoder;
        this.tokenDuration = Duration.ofSeconds(expirationSeconds);
    }

    public String generateToken(User user) {
        Instant now = Instant.now();
        JwtClaimsSet claims = JwtClaimsSet.builder()
                .issuer("stock-api")
                .issuedAt(now)
                .expiresAt(now.plus(tokenDuration))
                .subject(user.getMatricule())
                .claim("username", user.getUsername())
                .claim("roles", List.of(user.getRole().getName()))
                .build();

        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();

        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims))
                .getTokenValue();
    }

    public long getExpirationSeconds() {
        return tokenDuration.toSeconds();
    }
}
