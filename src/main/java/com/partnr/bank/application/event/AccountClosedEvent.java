package com.partnr.bank.application.event;

import java.io.Serializable;

public class AccountClosedEvent implements Serializable {

    private String accountId;

    public AccountClosedEvent() {
    }

    public AccountClosedEvent(String accountId) {
        this.accountId = accountId;
    }

    public String getAccountId() {
        return accountId;
    }

    public void setAccountId(String accountId) {
        this.accountId = accountId;
    }
}
