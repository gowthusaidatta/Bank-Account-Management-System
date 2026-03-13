package com.partnr.bank.application.command;

import java.io.Serializable;

import org.axonframework.modelling.command.TargetAggregateIdentifier;

public class CloseAccountCommand implements Serializable {

    @TargetAggregateIdentifier
    private final String accountId;

    public CloseAccountCommand(String accountId) {
        this.accountId = accountId;
    }

    public String getAccountId() {
        return accountId;
    }
}
