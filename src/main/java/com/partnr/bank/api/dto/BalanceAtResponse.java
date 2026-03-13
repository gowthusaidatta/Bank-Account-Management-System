package com.partnr.bank.api.dto;

import java.math.BigDecimal;
import java.time.Instant;

public record BalanceAtResponse(String accountId, Instant balanceAsOf, BigDecimal balance) {
}
