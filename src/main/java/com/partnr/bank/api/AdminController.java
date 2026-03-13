package com.partnr.bank.api;

import java.util.Map;
import java.util.Optional;

import org.axonframework.config.EventProcessingConfiguration;
import org.axonframework.eventhandling.EventProcessor;
import org.axonframework.eventhandling.TrackingEventProcessor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final EventProcessingConfiguration eventProcessingConfiguration;

    public AdminController(EventProcessingConfiguration eventProcessingConfiguration) {
        this.eventProcessingConfiguration = eventProcessingConfiguration;
    }

    @PostMapping("/replay/{processingGroup}")
    public ResponseEntity<Map<String, String>> replayProjection(@PathVariable String processingGroup) {
        Optional<EventProcessor> processor = eventProcessingConfiguration.eventProcessor(processingGroup);

        if (processor.isEmpty()) {
            throw new IllegalArgumentException("Processing group not found: " + processingGroup);
        }
        if (!(processor.get() instanceof TrackingEventProcessor trackingEventProcessor)) {
            throw new IllegalStateException("Processing group is not configured as a tracking processor: " + processingGroup);
        }

        trackingEventProcessor.shutDown();
        trackingEventProcessor.resetTokens();
        trackingEventProcessor.start();

        return ResponseEntity.accepted().body(Map.of(
                "processingGroup", processingGroup,
                "status", "REPLAY_TRIGGERED"));
    }
}
