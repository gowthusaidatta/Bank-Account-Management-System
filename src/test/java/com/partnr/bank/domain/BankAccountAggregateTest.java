package com.partnr.bank.domain;

import java.math.BigDecimal;

import org.axonframework.test.aggregate.AggregateTestFixture;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;

import com.partnr.bank.application.command.CloseAccountCommand;
import com.partnr.bank.application.command.CreateAccountCommand;
import com.partnr.bank.application.command.DepositMoneyCommand;
import com.partnr.bank.application.command.WithdrawMoneyCommand;
import com.partnr.bank.application.event.AccountClosedEvent;
import com.partnr.bank.application.event.AccountCreatedEvent;
import com.partnr.bank.application.event.MoneyDepositedEvent;
import com.partnr.bank.application.event.MoneyWithdrawnEvent;

class BankAccountAggregateTest {

    private static final String ACCOUNT_ID = "acc-123";

    private AggregateTestFixture<BankAccountAggregate> fixture;

    @BeforeEach
    void setUp() {
        fixture = new AggregateTestFixture<>(BankAccountAggregate.class);
    }

    @Test
    void createAccountPublishesAccountCreatedEvent() {
        fixture.givenNoPriorActivity()
                .when(new CreateAccountCommand(ACCOUNT_ID, amount("100.00"), "Alice"))
                .expectSuccessfulHandlerExecution()
                .expectEvents(new AccountCreatedEvent(ACCOUNT_ID, amount("100.00"), "Alice"));
    }

    @Test
    void depositPublishesMoneyDepositedEvent() {
        fixture.given(new AccountCreatedEvent(ACCOUNT_ID, amount("100.00"), "Alice"))
                .when(new DepositMoneyCommand(ACCOUNT_ID, amount("25.00")))
                .expectSuccessfulHandlerExecution()
                .expectEvents(new MoneyDepositedEvent(ACCOUNT_ID, amount("25.00")));
    }

    @Test
    void withdrawPublishesMoneyWithdrawnEventWhenFundsAreSufficient() {
        fixture.given(new AccountCreatedEvent(ACCOUNT_ID, amount("100.00"), "Alice"))
                .when(new WithdrawMoneyCommand(ACCOUNT_ID, amount("40.00")))
                .expectSuccessfulHandlerExecution()
                .expectEvents(new MoneyWithdrawnEvent(ACCOUNT_ID, amount("40.00")));
    }

    @Test
    void withdrawFailsWhenFundsAreInsufficient() {
        fixture.given(new AccountCreatedEvent(ACCOUNT_ID, amount("100.00"), "Alice"))
                .when(new WithdrawMoneyCommand(ACCOUNT_ID, amount("1000.00")))
                .expectException(IllegalStateException.class)
                .expectExceptionMessage("Insufficient funds");
    }

    @Test
    void closeFailsWhenBalanceIsNotZero() {
        fixture.given(new AccountCreatedEvent(ACCOUNT_ID, amount("100.00"), "Alice"))
                .when(new CloseAccountCommand(ACCOUNT_ID))
                .expectException(IllegalStateException.class)
                .expectExceptionMessage("Account cannot be closed unless balance is zero");
    }

    @Test
    void closePublishesAccountClosedEventWhenBalanceIsZero() {
        fixture.given(
                        new AccountCreatedEvent(ACCOUNT_ID, amount("100.00"), "Alice"),
                        new MoneyWithdrawnEvent(ACCOUNT_ID, amount("100.00")))
                .when(new CloseAccountCommand(ACCOUNT_ID))
                .expectSuccessfulHandlerExecution()
                .expectEvents(new AccountClosedEvent(ACCOUNT_ID));
    }

    @Test
    void depositFailsWhenAccountIsClosed() {
        fixture.given(
                        new AccountCreatedEvent(ACCOUNT_ID, amount("0.00"), "Alice"),
                        new AccountClosedEvent(ACCOUNT_ID))
                .when(new DepositMoneyCommand(ACCOUNT_ID, amount("10.00")))
                .expectException(IllegalStateException.class)
            .expectExceptionMessage("Account is closed");
    }

    private BigDecimal amount(String value) {
        return new BigDecimal(value);
    }
}
