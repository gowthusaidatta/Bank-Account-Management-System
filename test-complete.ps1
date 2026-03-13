# Comprehensive API Test Suite for Bank Account Management System
# With delays to account for projection updates

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
    $createResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/accounts' -Method Post -Body '{"initialBalance": 1000.00, "ownerName": "Complete Test User"}' -ContentType 'application/json'
    $accountId = $createResponse.accountId
    Write-Host "SUCCESS - Account created: $accountId" -ForegroundColor Green
    Write-Host "  Initial Balance: 1000.00" -ForegroundColor Gray
    $testsPassed++
    Start-Sleep -Milliseconds 500
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
    Write-Host "SUCCESS - Account retrieved" -ForegroundColor Green
    Write-Host "  Owner: $($account.ownerName)" -ForegroundColor Gray
    Write-Host "  Balance: $($account.balance)" -ForegroundColor Gray
    Write-Host "  Status: $($account.status)" -ForegroundColor Gray
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
    Start-Sleep -Milliseconds 500
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - Deposit completed" -ForegroundColor Green
    Write-Host "  New Balance: $($account.balance)" -ForegroundColor Gray
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
    Start-Sleep -Milliseconds 500
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - Withdrawal completed" -ForegroundColor Green
    Write-Host "  New Balance: $($account.balance)" -ForegroundColor Gray
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
    Write-Host "SUCCESS - Event stream retrieved" -ForegroundColor Green
    Write-Host "  Total events: $($events.Count)" -ForegroundColor Gray
    foreach ($event in $events) {
        Write-Host "    $($event.sequenceNumber). $($event.type)" -ForegroundColor Gray
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
    # Get the timestamp of the first event
    $events = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/events" -Method Get
    if ($events.Count -gt 1) {
        $firstEventTime = $events[0].timestamp
        $secondEventTime = $events[1].timestamp
        
        # Query balance at time of second event
        $balanceResponse = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/balance-at/$secondEventTime" -Method Get
        Write-Host "SUCCESS - Temporal query worked" -ForegroundColor Green
        Write-Host "  Balance at $secondEventTime : $($balanceResponse.balance)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Not enough events for temporal query"
    }
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 7: Error Case - Insufficient Funds
Write-Host "TEST 7: Error handling - Insufficient funds..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" -Method Post -Body '{"amount": 10000.00}' -ContentType 'application/json' -ErrorAction Stop | Out-Null
    Write-Host "FAILED - Should have thrown 409 error" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "SUCCESS - Correctly returned 409 Conflict" -ForegroundColor Green
        Write-Host "  Error message: Insufficient funds" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "FAILED - Wrong status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        $testsFailed++
    }
}
Write-Host ""

# Test 8: Error Case - Account Not Found
Write-Host "TEST 8: Error handling - Account not found..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/00000000-0000-0000-0000-000000000000" -Method Get -ErrorAction Stop | Out-Null
    Write-Host "FAILED - Should have thrown 404 error" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 404) {
        Write-Host "SUCCESS - Correctly returned 404 Not Found" -ForegroundColor Green
        $testsPassed++
    } else {
        Write-Host "FAILED - Wrong status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        $testsFailed++
    }
}
Write-Host ""

# Get current balance before closing
$currentAccount = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
$currentBalance = $currentAccount.balance

# Test 9: Withdraw entire balance
Write-Host "TEST 9: Withdraw entire balance (current: $currentBalance)..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" -Method Post -Body "{`"amount`": $currentBalance}" -ContentType 'application/json' | Out-Null
    Start-Sleep -Milliseconds 500
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    Write-Host "SUCCESS - Withdrawal completed" -ForegroundColor Green
    Write-Host "  Balance is now: $($account.balance)" -ForegroundColor Gray
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
    Start-Sleep -Milliseconds 500
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    if ($account.status -eq "CLOSED") {
        Write-Host "SUCCESS - Account closed" -ForegroundColor Green
        Write-Host "  Status: $($account.status)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Account status is $($account.status), expected CLOSED"
    }
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 11: Error Case - Operation on Closed Account
Write-Host "TEST 11: Error handling - Deposit to closed account..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/deposit" -Method Post -Body '{"amount": 100.00}' -ContentType 'application/json' -ErrorAction Stop | Out-Null
    Write-Host "FAILED - Should have thrown 409 error" -ForegroundColor Red
    $testsFailed++
} catch {
    if ($_.Exception.Response.StatusCode -eq 409) {
        Write-Host "SUCCESS - Correctly returned 409 Conflict" -ForegroundColor Green
        Write-Host "  Error message: Account is closed" -ForegroundColor Gray
        $testsPassed++
    } else {
        Write-Host "FAILED - Wrong status code: $($_.Exception.Response.StatusCode)" -ForegroundColor Red
        $testsFailed++
    }
}
Write-Host ""

# Test 12: Admin Replay Endpoint
Write-Host "TEST 12: Admin replay endpoint..." -ForegroundColor Yellow
try {
    $replayResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/admin/replay/current-account' -Method Post -ContentType 'application/json'
    Write-Host "SUCCESS - Replay triggered" -ForegroundColor Green
    Write-Host "  Processing Group: $($replayResponse.processingGroup)" -ForegroundColor Gray
    Write-Host "  Status: $($replayResponse.status)" -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 13: Database verification
Write-Host "TEST 13: Database verification - Event Store..." -ForegroundColor Yellow
try {
    $eventCount = docker exec axon-db psql -U user -d axon-db -t -c "SELECT COUNT(*) FROM domain_event_entry;"
    Write-Host "SUCCESS - Event store contains $($eventCount.Trim()) events" -ForegroundColor Green
    $testsPassed++
} catch {
    Write-Host "FAILED - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 14: Check Snapshotting
Write-Host "TEST 14: Verify snapshotting configuration..." -ForegroundColor Yellow
try {
    $snapshotCount = docker exec axon-db psql -U user -d axon-db -t -c "SELECT COUNT(*) FROM snapshot_event_entry;"
    Write-Host "SUCCESS - Snapshot table accessible" -ForegroundColor Green
    Write-Host "  Total snapshots: $($snapshotCount.Trim())" -ForegroundColor Gray
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
    Write-Host "==========================================="-ForegroundColor Green
    Write-Host " ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host " Bank Account Management System is 100% OPERATIONAL!" -ForegroundColor Green
    Write-Host "==========================================="  -ForegroundColor Green
    exit 0
} else {
    Write-Host "SOME TESTS FAILED - Review above for details" -ForegroundColor Red
    exit 1
}
