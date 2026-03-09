package com.partnr.bank.query.repository;

import java.util.List;

import org.springframework.data.jpa.repository.JpaRepository;

import com.partnr.bank.query.entity.TransactionHistoryEntry;

public interface TransactionHistoryRepository extends JpaRepository<TransactionHistoryEntry, Long> {

    List<TransactionHistoryEntry> findByAccountIdOrderByOccurredAtAsc(String accountId);
}
