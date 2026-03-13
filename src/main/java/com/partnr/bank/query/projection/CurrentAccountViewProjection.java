package com.partnr.bank.query.projection;

import java.time.Instant;

import org.axonframework.config.ProcessingGroup;
import org.axonframework.eventhandling.EventHandler;
import org.axonframework.eventhandling.ResetHandler;
import org.axonframework.eventhandling.Timestamp;
import org.springframework.stereotype.Component;

import com.partnr.bank.application.event.AccountClosedEvent;
import com.partnr.bank.application.event.AccountCreatedEvent;
import com.partnr.bank.application.event.MoneyDepositedEvent;
import com.partnr.bank.application.event.MoneyWithdrawnEvent;
import com.partnr.bank.domain.AccountStatus;
import com.partnr.bank.query.entity.CurrentAccountView;
import com.partnr.bank.query.repository.CurrentAccountViewRepository;

@Component
@ProcessingGroup("current-account")
public class CurrentAccountViewProjection {

    private final CurrentAccountViewRepository repository;

    public CurrentAccountViewProjection(CurrentAccountViewRepository repository) {
        this.repository = repository;
    }

    @EventHandler
    public void on(AccountCreatedEvent event, @Timestamp Instant timestamp) {
        CurrentAccountView view = new CurrentAccountView(
                event.getAccountId(),
                event.getOwnerName(),
                event.getInitialBalance(),
                AccountStatus.ACTIVE,
                timestamp);
        repository.save(view);
    }

    @EventHandler
    public void on(MoneyDepositedEvent event, @Timestamp Instant timestamp) {
        repository.findById(event.getAccountId()).ifPresent(view -> {
            view.setBalance(view.getBalance().add(event.getAmount()));
            view.setUpdatedAt(timestamp);
            repository.save(view);
        });
    }

    @EventHandler
    public void on(MoneyWithdrawnEvent event, @Timestamp Instant timestamp) {
        repository.findById(event.getAccountId()).ifPresent(view -> {
            view.setBalance(view.getBalance().subtract(event.getAmount()));
            view.setUpdatedAt(timestamp);
            repository.save(view);
        });
    }

    @EventHandler
    public void on(AccountClosedEvent event, @Timestamp Instant timestamp) {
        repository.findById(event.getAccountId()).ifPresent(view -> {
            view.setStatus(AccountStatus.CLOSED);
            view.setUpdatedAt(timestamp);
            repository.save(view);
        });
    }

    @ResetHandler
    public void onReset() {
        repository.deleteAllInBatch();
    }
}
