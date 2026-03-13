# Comprehensive API Test Suite for Bank Account Management System

$ErrorActionPreference = "Continue"
$testsPassed = 0
$testsFailed = 0

Write-Host "=========================================="
Write-Host "  BANK ACCOUNT API - COMPREHENSIVE TESTS"
Write-Host "=========================================="
Write-Host ""

# Test 1: Create Account
Write-Host "TEST 1: Creating new account..." -ForegroundColor Yellow
try {
    $createResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/accounts' -Method Post -Body '{"initialBalance": 1000.00, "ownerName": "ApiTest User"}' -ContentType 'application/json'
    $accountId = $createResponse.accountId
    Write-Host "SUCCESS - Account created: $accountId" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
    exit 1
}
Write-Host ""

# Test 2: Get Account Details
Write-Host "TEST 2: Get account details..." -ForegroundColor Yellow
try {
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - Owner: $($account.ownerName), Balance: $($account.balance), Status: $($account.status)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 3: Deposit Money
Write-Host "TEST 3: Deposit 500.00..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/deposit" -Method Post -Body '{"amount": 500.00}' -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - New Balance: $($account.balance)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 4: Withdraw Money
Write-Host "TEST 4: Withdraw 200.00..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" -Method Post -Body '{"amount": 200.00}' -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - New Balance: $($account.balance)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 5: Get Event Stream
Write-Host "TEST 5: Get event stream..." -ForegroundColor Yellow
try {
    $events = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/events" -Method Get
    Write-Host "SUCCESS - Found $($events.Count) events" -ForegroundColor Green
    foreach ($event in $events) {
        Write-Host "  - $($event.type) (seq: $($event.sequenceNumber))" -ForegroundColor Gray
    }
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 6: Temporal Query
Write-Host "TEST 6: Temporal query..." -ForegroundColor Yellow
try {
    $timestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $balanceResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/balance-at/$timestamp" -Method Get
    Write-Host "SUCCESS - Balance at $timestamp : $($balanceResponse.balance)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 7: Error Case - Insufficient Funds
Write-Host "TEST 7: Error handling - Insufficient funds..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" -Method Post -Body '{"amount": 5000.00}' -ContentType 'application/json' -ErrorAction Stop | Out-Null
    Write-Host "FAILED - Should have thrown error" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "SUCCESS - Correctly returned 409 Conflict for insufficient funds" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "FAILED - Wrong status code" -ForegroundColor Red
        $testsFailed++
    }
}
Write-Host ""

# Test 8: Error Case - Account Not Found
Write-Host "TEST 8: Error handling - Account not found..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/non-existent-id" -Method Get -ErrorAction Stop | Out-Null
    Write-Host "FAILED - Should have thrown error" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "SUCCESS - Correctly returned 404 Not Found" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "FAILED - Wrong status code" -ForegroundColor Red
        $testsFailed++
    }
}
Write-Host ""

# Test 9: Withdraw entire balance
Write-Host "TEST 9: Withdraw entire balance..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" -Method Post -Body '{"amount": 1300.00}' -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - Balance is now: $($account.balance)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 10: Close Account
Write-Host "TEST 10: Close account..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/close" -Method Post -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - Account status: $($account.status)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 11: Error Case - Operation on Closed Account
Write-Host "TEST 11: Error handling - Deposit to closed account..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/deposit" -Method Post -Body '{"amount": 100.00}' -ContentType 'application/json' -ErrorAction Stop | Out-Null
    Write-Host "FAILED - Should have thrown error" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "SUCCESS - Correctly returned 409 Conflict for closed account" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "FAILED - Wrong status code" -ForegroundColor Red
        $testsFailed++
    }
}
Write-Host ""

# Test 12: Admin Replay Endpoint
Write-Host "TEST 12: Admin replay endpoint..." -ForegroundColor Yellow
try {
    $replayResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/admin/replay/current-account' -Method Post -ContentType 'application/json'
    Write-Host "SUCCESS - Replay triggered for: $($replayResponse.processingGroup)" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Final Summary
Write-Host "=========================================="
Write-Host "  TEST SUMMARY"
Write-Host "=========================================="
Write-Host ""
Write-Host "Total Tests: $($testsPassed + $testsFailed)"
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "Bank Account Management System is fully operational!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
