package com.partnr.bank.api.dto;

import java.time.Instant;
import java.util.Map;

public record EventStreamItemResponse(String type, Map<String, Object> payload, Instant timestamp, long sequenceNumber) {
}
