package com.partnr.bank.query.repository;

import org.springframework.data.jpa.repository.JpaRepository;

import com.partnr.bank.query.entity.CurrentAccountView;

public interface CurrentAccountViewRepository extends JpaRepository<CurrentAccountView, String> {
}
