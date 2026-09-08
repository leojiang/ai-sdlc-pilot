package com.example.aisdlc;

import java.util.Map;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Guards the health-endpoint contract (story #1 AC3): the Flutter smoke screen
 * depends on GET /actuator/health returning 200 with status UP. Asserts the body,
 * not just the status code, so actuator exposure regressions are caught here
 * rather than on the frontend.
 */
@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
class HealthEndpointIntegrationTest {

    @Autowired
    private TestRestTemplate rest;

    @Test
    void healthEndpointReturns200WithStatusUp() {
        ResponseEntity<Map> response = rest.getForEntity("/actuator/health", Map.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getBody()).isNotNull();
        assertThat(response.getBody().get("status")).isEqualTo("UP");
    }

    /**
     * The Flutter web app calls this endpoint cross-origin (flutter run serves
     * on a random localhost port), so the CORS header is part of the wiring
     * contract (story #1 AC5 on the web platform).
     */
    @Test
    void healthEndpointAllowsCrossOriginCallsFromLocalhost() {
        var headers = new org.springframework.http.HttpHeaders();
        headers.set("Origin", "http://localhost:8899");

        ResponseEntity<Map> response =
                rest.exchange("/actuator/health", org.springframework.http.HttpMethod.GET,
                        new org.springframework.http.HttpEntity<>(headers), Map.class);

        assertThat(response.getStatusCode()).isEqualTo(HttpStatus.OK);
        assertThat(response.getHeaders().getAccessControlAllowOrigin())
                .isEqualTo("http://localhost:8899");
    }
}
