package com.partnr.bank.application.event;

import java.io.Serializable;
import java.math.BigDecimal;

public class AccountCreatedEvent implements Serializable {

    private String accountId;
    private BigDecimal initialBalance;
    private String ownerName;

    public AccountCreatedEvent() {
    }

    public AccountCreatedEvent(String accountId, BigDecimal initialBalance, String ownerName) {
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

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public void setInitialBalance(BigDecimal initialBalance) {
        this.initialBalance = initialBalance;
    }

    public void setOwnerName(String ownerName) {
        this.ownerName = ownerName;
    }
}
