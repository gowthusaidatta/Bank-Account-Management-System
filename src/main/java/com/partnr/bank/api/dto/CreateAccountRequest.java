package com.partnr.bank.api.dto;

import java.math.BigDecimal;

import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public record CreateAccountRequest(
        @NotNull @DecimalMin(value = "0.00", inclusive = true) BigDecimal initialBalance,
        @NotBlank String ownerName) {
}
