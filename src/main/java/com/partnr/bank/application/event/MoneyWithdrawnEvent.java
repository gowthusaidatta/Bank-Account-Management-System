package com.partnr.bank.application.event;

import java.io.Serializable;
import java.math.BigDecimal;

public class MoneyWithdrawnEvent implements Serializable {

    private String accountId;
    private BigDecimal amount;

    public MoneyWithdrawnEvent() {
    }

    public MoneyWithdrawnEvent(String accountId, BigDecimal amount) {
        this.accountId = accountId;
        this.amount = amount;
    }

    public String getAccountId() {
        return accountId;
    }

    public BigDecimal getAmount() {
        return amount;
    }

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }

    public void setAmount(BigDecimal amount) {
        this.amount = amount;
    }
}
