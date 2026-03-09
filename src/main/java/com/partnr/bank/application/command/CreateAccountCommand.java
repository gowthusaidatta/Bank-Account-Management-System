package com.partnr.bank.application.command;

import java.io.Serializable;
import java.math.BigDecimal;

import org.axonframework.modelling.command.TargetAggregateIdentifier;

public class CreateAccountCommand implements Serializable {

    @TargetAggregateIdentifier
    private final String accountId;
    private final BigDecimal initialBalance;
    private final String ownerName;

    public CreateAccountCommand(String accountId, BigDecimal initialBalance, String ownerName) {
        this.accountId = accountId;
        this.initialBalance = initialBalance;
        this.ownerName = ownerName;
    }

    public String getAccountId() {
        return accountId;
    }

    public BigDecimal getInitialBalance() {
        return initialBalance;
    }

    public String getOwnerName() {
        return ownerName;
    }
}
