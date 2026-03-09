package com.partnr.bank.api.dto;

import java.math.BigDecimal;

import com.partnr.bank.domain.AccountStatus;

public record AccountResponse(String accountId, String ownerName, BigDecimal balance, AccountStatus status) {
}
