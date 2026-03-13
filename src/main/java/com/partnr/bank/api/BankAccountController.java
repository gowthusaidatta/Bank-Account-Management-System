package com.partnr.bank.api;

import java.math.BigDecimal;
import java.net.URI;
import java.time.Instant;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import org.axonframework.commandhandling.gateway.CommandGateway;
import org.axonframework.eventhandling.DomainEventMessage;
import org.axonframework.eventsourcing.eventstore.DomainEventStream;
import org.axonframework.eventsourcing.eventstore.EventStore;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.partnr.bank.api.dto.AccountResponse;
import com.partnr.bank.api.dto.BalanceAtResponse;
import com.partnr.bank.api.dto.CreateAccountRequest;
import com.partnr.bank.api.dto.CreateAccountResponse;
import com.partnr.bank.api.dto.EventStreamItemResponse;
import com.partnr.bank.api.dto.MoneyOperationRequest;
import com.partnr.bank.api.exception.AccountNotFoundException;
import com.partnr.bank.application.command.CloseAccountCommand;
import com.partnr.bank.application.command.CreateAccountCommand;
import com.partnr.bank.application.command.DepositMoneyCommand;
import com.partnr.bank.application.command.WithdrawMoneyCommand;
import com.partnr.bank.application.event.AccountCreatedEvent;
import com.partnr.bank.application.event.MoneyDepositedEvent;
import com.partnr.bank.application.event.MoneyWithdrawnEvent;
import com.partnr.bank.query.entity.CurrentAccountView;
import com.partnr.bank.query.repository.CurrentAccountViewRepository;

import jakarta.validation.Valid;

@RestController
@RequestMapping("/api/accounts")
public class BankAccountController {

    private final CommandGateway commandGateway;
    private final EventStore eventStore;
    private final CurrentAccountViewRepository currentAccountViewRepository;
    private final ObjectMapper objectMapper;

    public BankAccountController(
            CommandGateway commandGateway,
            EventStore eventStore,
            CurrentAccountViewRepository currentAccountViewRepository,
            ObjectMapper objectMapper) {
        this.commandGateway = commandGateway;
        this.eventStore = eventStore;
        this.currentAccountViewRepository = currentAccountViewRepository;
        this.objectMapper = objectMapper;
    }

    @PostMapping
    public ResponseEntity<CreateAccountResponse> createAccount(@Valid @RequestBody CreateAccountRequest request) {
        String accountId = UUID.randomUUID().toString();

        commandGateway.sendAndWait(new CreateAccountCommand(accountId, request.initialBalance(), request.ownerName()));

        URI location = URI.create("/api/accounts/" + accountId);
        return ResponseEntity.created(location).body(new CreateAccountResponse(accountId));
    }

    @PostMapping("/{accountId}/deposit")
    public ResponseEntity<Void> deposit(@PathVariable String accountId, @Valid @RequestBody MoneyOperationRequest request) {
        commandGateway.sendAndWait(new DepositMoneyCommand(accountId, request.amount()));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{accountId}/withdraw")
    public ResponseEntity<Void> withdraw(@PathVariable String accountId, @Valid @RequestBody MoneyOperationRequest request) {
        commandGateway.sendAndWait(new WithdrawMoneyCommand(accountId, request.amount()));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/{accountId}/close")
    public ResponseEntity<Void> close(@PathVariable String accountId) {
        commandGateway.sendAndWait(new CloseAccountCommand(accountId));
        return ResponseEntity.ok().build();
    }

    @GetMapping("/{accountId}")
    public ResponseEntity<AccountResponse> getAccount(@PathVariable String accountId) {
        CurrentAccountView account = currentAccountViewRepository.findById(accountId)
                .orElseThrow(() -> new AccountNotFoundException("Account not found: " + accountId));

        return ResponseEntity.ok(new AccountResponse(
                account.getAccountId(),
                account.getOwnerName(),
                account.getBalance(),
                account.getStatus()));
    }

    @GetMapping("/{accountId}/events")
    public ResponseEntity<List<EventStreamItemResponse>> getEvents(@PathVariable String accountId) {
        DomainEventStream eventStream = eventStore.readEvents(accountId, 0L);
        List<EventStreamItemResponse> response = new ArrayList<>();

        while (eventStream.hasNext()) {
            DomainEventMessage<?> eventMessage = eventStream.next();
            Map<String, Object> payload = objectMapper.convertValue(
                    eventMessage.getPayload(),
                    new TypeReference<Map<String, Object>>() {
                    });

            response.add(new EventStreamItemResponse(
                    eventMessage.getPayloadType().getSimpleName(),
                    payload,
                    eventMessage.getTimestamp(),
                    eventMessage.getSequenceNumber()));
        }

        if (response.isEmpty()) {
            throw new AccountNotFoundException("Account not found: " + accountId);
        }

        return ResponseEntity.ok(response);
    }

    @GetMapping("/{accountId}/balance-at/{timestamp}")
    public ResponseEntity<BalanceAtResponse> getBalanceAt(
            @PathVariable String accountId,
            @PathVariable String timestamp) {
        Instant asOf;
        try {
            asOf = Instant.parse(timestamp);
        } catch (DateTimeParseException ex) {
            throw new IllegalArgumentException("Timestamp must be a valid ISO-8601 instant");
        }

        DomainEventStream eventStream = eventStore.readEvents(accountId, 0L);
        if (!eventStream.hasNext()) {
            throw new AccountNotFoundException("Account not found: " + accountId);
        }

        BigDecimal balance = BigDecimal.ZERO;
        boolean createdByTimestamp = false;

        while (eventStream.hasNext()) {
            DomainEventMessage<?> eventMessage = eventStream.next();

            if (eventMessage.getTimestamp().isAfter(asOf)) {
                break;
            }

            Object payload = eventMessage.getPayload();
            if (payload instanceof AccountCreatedEvent accountCreatedEvent) {
                balance = accountCreatedEvent.getInitialBalance();
                createdByTimestamp = true;
            } else if (payload instanceof MoneyDepositedEvent moneyDepositedEvent) {
                balance = balance.add(moneyDepositedEvent.getAmount());
            } else if (payload instanceof MoneyWithdrawnEvent moneyWithdrawnEvent) {
                balance = balance.subtract(moneyWithdrawnEvent.getAmount());
            }
        }

        if (!createdByTimestamp) {
            throw new IllegalArgumentException("Account was not yet created at the provided timestamp");
        }

        return ResponseEntity.ok(new BalanceAtResponse(accountId, asOf, balance));
    }
}
