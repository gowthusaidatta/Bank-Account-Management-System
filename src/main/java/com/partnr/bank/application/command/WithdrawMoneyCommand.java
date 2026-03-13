package com.partnr.bank.application.command;

import java.io.Serializable;
import java.math.BigDecimal;

import org.axonframework.modelling.command.TargetAggregateIdentifier;

public class WithdrawMoneyCommand implements Serializable {

    @TargetAggregateIdentifier
    private final String accountId;
    private final BigDecimal amount;

    public WithdrawMoneyCommand(String accountId, BigDecimal amount) {
        this.accountId = accountId;
        this.amount = amount;
    }

    public String getAccountId() {
        return accountId;
    }

    public BigDecimal getAmount() {
        return amount;
    }
}
