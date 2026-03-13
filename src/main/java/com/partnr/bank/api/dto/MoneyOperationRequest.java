package com.partnr.bank.api.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;

public record MoneyOperationRequest(
        @NotNull @DecimalMin(value = "0.01", inclusive = true) BigDecimal amount) {
}
