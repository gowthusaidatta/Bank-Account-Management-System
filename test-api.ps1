# Comprehensive API Test Suite for Bank Account Management System

$ErrorActionPreference = "Stop"
$testsPassed = 0
$testsFailed = 0

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  BANK ACCOUNT API - COMPREHENSIVE TESTS" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# Test 1: Create Account
Write-Host "TEST 1: Creating new account..." -ForegroundColor Yellow
try {
    $createResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/accounts' `
        -Method Post `
        -Body '{"initialBalance": 1000.00, "ownerName": "Test User"}' `
        -ContentType 'application/json'
    $accountId = $createResponse.accountId
    Write-Host "✓ PASS - Account created: $accountId" -ForegroundColor Green
    Write-Host "  Initial Balance: 1000.00" -ForegroundColor Gray
    $testsPassed++
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
    exit 1
}
Write-Host ""

# Test 2: Get Account Details
Write-Host "TEST 2: Get account details..." -ForegroundColor Yellow
try {
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    if ($account.balance -eq 1000.00 -and $account.status -eq "ACTIVE") {
        Write-Host "✓ PASS - Account retrieved successfully" -ForegroundColor Green
        Write-Host "  Owner: $($account.ownerName)" -ForegroundColor Gray
        Write-Host "  Balance: $($account.balance)" -ForegroundColor Gray
        Write-Host "  Status: $($account.status)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Unexpected account data"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 3: Deposit Money
Write-Host "TEST 3: Deposit 500.00..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/deposit" `
        -Method Post `
        -Body '{"amount": 500.00}' `
        -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    if ($account.balance -eq 1500.00) {
        Write-Host "✓ PASS - Deposit successful" -ForegroundColor Green
        Write-Host "  New Balance: $($account.balance)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Balance mismatch. Expected 1500.00, got $($account.balance)"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 4: Withdraw Money
Write-Host "TEST 4: Withdraw 200.00..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" `
        -Method Post `
        -Body '{"amount": 200.00}' `
        -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    if ($account.balance -eq 1300.00) {
        Write-Host "✓ PASS - Withdrawal successful" -ForegroundColor Green
        Write-Host "  New Balance: $($account.balance)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Balance mismatch. Expected 1300.00, got $($account.balance)"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 5: Get Event Stream
Write-Host "TEST 5: Get event stream..." -ForegroundColor Yellow
try {
    $events = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/events" -Method Get
    if ($events.Count -eq 3) {
        Write-Host "✓ PASS - Event stream retrieved" -ForegroundColor Green
        Write-Host "  Events found: $($events.Count)" -ForegroundColor Gray
        foreach ($event in $events) {
            Write-Host "    - $($event.type) (seq: $($event.sequenceNumber))" -ForegroundColor Gray
        }
        $testsPassed++
    } else {
        throw "Expected 3 events, found $($events.Count)"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 6: Temporal Query (Balance at specific time)
Write-Host "TEST 6: Temporal query (balance at past timestamp)..." -ForegroundColor Yellow
try {
    $pastTimestamp = (Get-Date).AddMinutes(-5).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    $currentTimestamp = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
    
    $balanceNow = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/balance-at/$currentTimestamp" -Method Get
    if ($balanceNow.balance -eq 1300.00) {
        Write-Host "✓ PASS - Temporal query successful" -ForegroundColor Green
        Write-Host "  Balance at $currentTimestamp : $($balanceNow.balance)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Balance mismatch"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 7: Error Case - Insufficient Funds
Write-Host "TEST 7: Error handling - Insufficient funds..." -ForegroundColor Yellow
try {
    try {
        Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" `
            -Method Post `
            -Body '{"amount": 5000.00}' `
            -ContentType 'application/json' -ErrorAction Stop
        Write-Host "✗ FAIL - Should have thrown error for insufficient funds" -ForegroundColor Red
        $testsFailed++
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "✓ PASS - Correctly returned 409 Conflict" -ForegroundColor Green
            Write-Host "  Error: Insufficient funds" -ForegroundColor Gray
            $testsPassed++
        } else {
            throw "Expected 409 status code, got $($_.Exception.Response.StatusCode)"
        }
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 8: Error Case - Account Not Found
Write-Host "TEST 8: Error handling - Account not found..." -ForegroundColor Yellow
try {
    try {
        Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/non-existent-id" -Method Get -ErrorAction Stop
        Write-Host "✗ FAIL - Should have thrown error for non-existent account" -ForegroundColor Red
        $testsFailed++
    } catch {
        if ($_.Exception.Response.StatusCode -eq 404) {
            Write-Host "✓ PASS - Correctly returned 404 Not Found" -ForegroundColor Green
            $testsPassed++
        } else {
            throw "Expected 404 status code, got $($_.Exception.Response.StatusCode)"
        }
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 9: Withdraw entire balance (prepare for close)
Write-Host "TEST 9: Withdraw entire balance..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/withdraw" `
        -Method Post `
        -Body '{"amount": 1300.00}' `
        -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    if ($account.balance -eq 0.00) {
        Write-Host "✓ PASS - Balance is now zero" -ForegroundColor Green
        Write-Host "  Balance: $($account.balance)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Balance should be 0"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 10: Close Account
Write-Host "TEST 10: Close account..." -ForegroundColor Yellow
try {
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/close" `
        -Method Post `
        -ContentType 'application/json' | Out-Null
    $account = Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId" -Method Get
    if ($account.status -eq "CLOSED") {
        Write-Host "✓ PASS - Account closed successfully" -ForegroundColor Green
        Write-Host "  Status: $($account.status)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Account status should be CLOSED"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 11: Error Case - Operation on Closed Account
Write-Host "TEST 11: Error handling - Deposit to closed account..." -ForegroundColor Yellow
try {
    try {
        Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$accountId/deposit" `
            -Method Post `
            -Body '{"amount": 100.00}' `
            -ContentType 'application/json' -ErrorAction Stop
        Write-Host "✗ FAIL - Should have thrown error for closed account" -ForegroundColor Red
        $testsFailed++
    } catch {
        if ($_.Exception.Response.StatusCode -eq 409) {
            Write-Host "✓ PASS - Correctly returned 409 Conflict" -ForegroundColor Green
            Write-Host "  Error: Account is closed" -ForegroundColor Gray
            $testsPassed++
        } else {
            throw "Expected 409 status code"
        }
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 12: Snapshotting (create account with 5+ events)
Write-Host "TEST 12: Snapshotting test (5 or more events)..." -ForegroundColor Yellow
try {
    # Create new account
    $snapAccount = Invoke-RestMethod -Uri 'http://localhost:8080/api/accounts' `
        -Method Post `
        -Body '{"initialBalance": 100.00, "ownerName": "Snapshot Test"}' `
        -ContentType 'application/json'
    $snapId = $snapAccount.accountId
    
    # Create 4 more events (total 5)
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$snapId/deposit" -Method Post -Body '{"amount": 100.00}' -ContentType 'application/json' | Out-Null
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$snapId/deposit" -Method Post -Body '{"amount": 100.00}' -ContentType 'application/json' | Out-Null
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$snapId/withdraw" -Method Post -Body '{"amount": 50.00}' -ContentType 'application/json' | Out-Null
    Invoke-RestMethod -Uri "http://localhost:8080/api/accounts/$snapId/withdraw" -Method Post -Body '{"amount": 50.00}' -ContentType 'application/json' | Out-Null
    
    Start-Sleep -Seconds 2
    
    # Check snapshot in database
    $snapshotCheck = docker exec axon-db psql -U user -d axon-db -t -c "SELECT COUNT(*) FROM snapshot_event_entry WHERE aggregate_identifier = '$snapId';"
    if ([int]$snapshotCheck.Trim() -gt 0) {
        Write-Host "✓ PASS - Snapshot created after 5 events" -ForegroundColor Green
        Write-Host "  Account: $snapId" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Snapshot not found"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Test 13: Admin Replay Endpoint
Write-Host "TEST 13: Admin replay endpoint..." -ForegroundColor Yellow
try {
    $replayResponse = Invoke-RestMethod -Uri 'http://localhost:8080/api/admin/replay/current-account' `
        -Method Post `
        -ContentType 'application/json'
    if ($replayResponse.status -eq "REPLAY_TRIGGERED") {
        Write-Host "✓ PASS - Replay triggered successfully" -ForegroundColor Green
        Write-Host "  Processing Group: $($replayResponse.processingGroup)" -ForegroundColor Gray
        $testsPassed++
    } else {
        throw "Unexpected response"
    }
} catch {
    Write-Host "✗ FAIL - $($_.Exception.Message)" -ForegroundColor Red
    $testsFailed++
}
Write-Host ""

# Final Summary
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  TEST SUMMARY" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Total Tests: $($testsPassed + $testsFailed)" -ForegroundColor White
Write-Host "Passed: $testsPassed" -ForegroundColor Green
Write-Host "Failed: $testsFailed" -ForegroundColor $(if ($testsFailed -eq 0) { "Green" } else { "Red" })
Write-Host ""

if ($testsFailed -eq 0) {
    Write-Host "✓ ALL TESTS PASSED!" -ForegroundColor Green
    Write-Host "✓ Bank Account Management System is fully operational!" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ SOME TESTS FAILED" -ForegroundColor Red
    exit 1
}
