package com.partnr.bank.query.projection;

import java.time.Instant;

import org.axonframework.eventhandling.EventHandler;
import org.axonframework.eventhandling.ResetHandler;
import org.axonframework.eventhandling.Timestamp;
import org.springframework.stereotype.Component;

import com.partnr.bank.application.event.MoneyDepositedEvent;
import com.partnr.bank.application.event.MoneyWithdrawnEvent;
import com.partnr.bank.query.entity.TransactionHistoryEntry;
import com.partnr.bank.query.repository.TransactionHistoryRepository;

@Component
public class TransactionHistoryProjection {

    private final TransactionHistoryRepository repository;

    public TransactionHistoryProjection(TransactionHistoryRepository repository) {
        this.repository = repository;
    }

    @EventHandler
    public void on(MoneyDepositedEvent event, @Timestamp Instant timestamp) {
        repository.save(new TransactionHistoryEntry(
                event.getAccountId(),
                "DEPOSIT",
                event.getAmount(),
                timestamp));
    }

    @EventHandler
    public void on(MoneyWithdrawnEvent event, @Timestamp Instant timestamp) {
        repository.save(new TransactionHistoryEntry(
                event.getAccountId(),
                "WITHDRAWAL",
                event.getAmount(),
                timestamp));
    }

    @ResetHandler
    public void onReset() {
        repository.deleteAllInBatch();
    }
}
