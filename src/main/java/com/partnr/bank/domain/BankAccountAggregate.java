package com.partnr.bank.domain;

import static org.axonframework.modelling.command.AggregateLifecycle.apply;

import java.math.BigDecimal;

import org.axonframework.commandhandling.CommandHandler;
import org.axonframework.eventsourcing.EventSourcingHandler;
import org.axonframework.modelling.command.AggregateIdentifier;
import org.axonframework.spring.stereotype.Aggregate;

import com.partnr.bank.application.command.CloseAccountCommand;
import com.partnr.bank.application.command.CreateAccountCommand;
import com.partnr.bank.application.command.DepositMoneyCommand;
import com.partnr.bank.application.command.WithdrawMoneyCommand;
import com.partnr.bank.application.event.AccountClosedEvent;
import com.partnr.bank.application.event.AccountCreatedEvent;
import com.partnr.bank.application.event.MoneyDepositedEvent;
import com.partnr.bank.application.event.MoneyWithdrawnEvent;

@Aggregate(snapshotTriggerDefinition = "bankAccountSnapshotTriggerDefinition")
public class BankAccountAggregate {

    @AggregateIdentifier
    private String accountId;

    private String ownerName;
    private BigDecimal balance;
    private AccountStatus status;

    protected BankAccountAggregate() {
        // Required by Axon.
    }

    @CommandHandler
    public BankAccountAggregate(CreateAccountCommand command) {
        if (command.getOwnerName() == null || command.getOwnerName().isBlank()) {
            throw new IllegalArgumentException("Owner name must be provided");
        }
        if (command.getInitialBalance() == null || command.getInitialBalance().compareTo(BigDecimal.ZERO) < 0) {
            throw new IllegalArgumentException("Initial balance must be zero or positive");
        }

        apply(new AccountCreatedEvent(command.getAccountId(), command.getInitialBalance(), command.getOwnerName()));
    }

    @CommandHandler
    public void handle(DepositMoneyCommand command) {
        assertActiveAccount();
        validateAmount(command.getAmount());

        apply(new MoneyDepositedEvent(command.getAccountId(), command.getAmount()));
    }

    @CommandHandler
    public void handle(WithdrawMoneyCommand command) {
        assertActiveAccount();
        validateAmount(command.getAmount());

        if (balance.compareTo(command.getAmount()) < 0) {
            throw new IllegalStateException("Insufficient funds");
        }

        apply(new MoneyWithdrawnEvent(command.getAccountId(), command.getAmount()));
    }

    @CommandHandler
    public void handle(CloseAccountCommand command) {
        assertActiveAccount();

        if (balance.compareTo(BigDecimal.ZERO) != 0) {
            throw new IllegalStateException("Account cannot be closed unless balance is zero");
        }

        apply(new AccountClosedEvent(command.getAccountId()));
    }

    @EventSourcingHandler
    public void on(AccountCreatedEvent event) {
        this.accountId = event.getAccountId();
        this.ownerName = event.getOwnerName();
        this.balance = event.getInitialBalance();
        this.status = AccountStatus.ACTIVE;
    }

    @EventSourcingHandler
    public void on(MoneyDepositedEvent event) {
        this.balance = balance.add(event.getAmount());
    }

    @EventSourcingHandler
    public void on(MoneyWithdrawnEvent event) {
        this.balance = balance.subtract(event.getAmount());
    }

    @EventSourcingHandler
    public void on(AccountClosedEvent event) {
        this.status = AccountStatus.CLOSED;
    }

    private void assertActiveAccount() {
        if (status == AccountStatus.CLOSED) {
            throw new IllegalStateException("Account is closed");
        }
    }

    private void validateAmount(BigDecimal amount) {
        if (amount == null || amount.compareTo(BigDecimal.ZERO) <= 0) {
            throw new IllegalArgumentException("Amount must be greater than zero");
        }
    }
}
