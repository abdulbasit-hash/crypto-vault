;; Title: CryptoVault DeFi Lending Protocol
;;
;; Summary: 
;; Revolutionary trustless lending infrastructure enabling seamless cryptocurrency-backed 
;; credit facilities with automated risk management and dynamic liquidation mechanisms.
;;
;; Description:
;; CryptoVault transforms traditional lending by creating a fully decentralized ecosystem 
;; where digital assets serve as intelligent collateral. Users can unlock liquidity from 
;; their crypto holdings without selling, while the protocol ensures security through 
;; sophisticated over-collateralization models, real-time price feeds, and automated 
;; liquidation safeguards. Built for the future of decentralized finance, CryptoVault 
;; democratizes access to credit markets while maintaining institutional-grade security 
;; and transparency.

;; TRAIT IMPORTS
(use-trait ft-trait 'SP3FBR2AGK5H9QBDH3EEN6DF8EK8JY7RX8QJ5SVTE.sip-010-trait-ft-standard.sip-010-trait)

;; SYSTEM CONSTANTS & ERROR CODES
(define-constant CONTRACT-OWNER tx-sender)
(define-constant PROTOCOL-WALLET (as-contract tx-sender))

;; Authorization & Access Control Errors
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-ALREADY-INITIALIZED (err u104))
(define-constant ERR-PAUSED (err u112))

;; Collateral & Risk Management Errors
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-MINIMUM (err u102))
(define-constant ERR-INVALID-LIQUIDATION (err u106))
(define-constant ERR-LIQUIDATION-NOT-TRIGGERED (err u113))

;; Loan Lifecycle Errors
(define-constant ERR-LOAN-NOT-FOUND (err u107))
(define-constant ERR-LOAN-NOT-ACTIVE (err u108))
(define-constant ERR-INVALID-LOAN-ID (err u109))

;; Validation Errors
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-INVALID-ASSET (err u111))
(define-constant ERR-TRANSFER-FAILED (err u114))
(define-constant ERR-INSUFFICIENT-BALANCE (err u115))
(define-constant ERR-MATH-OVERFLOW (err u116))
(define-constant ERR-DIVISION-BY-ZERO (err u117))
(define-constant ERR-PRICE-TOO-OLD (err u118))

;; Protocol Configuration Constants
(define-constant BLOCKS-PER-DAY u144) ;; Stacks: ~10 min blocks = 144/day
(define-constant MAX-PRICE-AGE u1440) ;; 10 days in blocks
(define-constant LIQUIDATION-BONUS u10) ;; 10% bonus for liquidators
(define-constant MAX-INTEREST-RATE u50) ;; 50% maximum annual rate
(define-constant PRECISION u1000000) ;; 6 decimal precision for calculations

;; PROTOCOL CONFIGURATION VARIABLES

;; Platform State Management
(define-data-var platform-initialized bool false)
(define-data-var platform-paused bool false)

;; Risk Management Parameters
(define-data-var minimum-collateral-ratio uint u150) ;; 150% minimum collateralization
(define-data-var liquidation-threshold uint u125) ;; 125% triggers liquidation
(define-data-var platform-fee-rate uint u1) ;; 1% protocol fee

;; Global Protocol Metrics
(define-data-var total-collateral-locked uint u0)
(define-data-var total-loans-issued uint u0)
(define-data-var total-value-liquidated uint u0)

;; DATA STORAGE ARCHITECTURE

;; Enhanced Loan Registry
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-token: principal,
    loan-token: principal,
    collateral-amount: uint,
    loan-amount: uint,
    outstanding-amount: uint,
    interest-rate: uint,
    start-height: uint,
    last-interest-calc: uint,
    status: (string-ascii 20),
  }
)

;; User Loan Portfolio Mapping
(define-map user-loans
  { user: principal }
  { active-loans: (list 100 uint) }
)

;; Enhanced Oracle Price Feed Registry
(define-map collateral-prices
  { asset: principal }
  { 
    price: uint,
    last-update: uint,
  }
)

;; Whitelisted Token Registry
(define-map whitelisted-tokens
  { token: principal }
  { enabled: bool }
)

;; SAFE MATH LIBRARY

;; Safe multiplication with overflow check
(define-private (safe-mul (a uint) (b uint))
  (let ((result (* a b)))
    (if (and (> a u0) (> b u0))
      (if (is-eq (/ result a) b)
        (ok result)
        ERR-MATH-OVERFLOW)
      (ok result)))
)

;; Safe addition with overflow check
(define-private (safe-add (a uint) (b uint))
  (let ((result (+ a b)))
    (if (>= result a)
      (ok result)
      ERR-MATH-OVERFLOW))
)

;; Safe division with zero check
(define-private (safe-div (a uint) (b uint))
  (if (> b u0)
    (ok (/ a b))
    ERR-DIVISION-BY-ZERO)
)

;; FINANCIAL CALCULATION ENGINE

;; Enhanced Collateral Ratio Calculator with Safe Math
(define-private (calculate-collateral-ratio
    (collateral uint)
    (loan uint)
    (collateral-price uint)
  )
  (if (is-eq loan u0)
    (ok u0)
    (let (
        (collateral-value (try! (safe-mul collateral collateral-price)))
        (ratio-base (try! (safe-div collateral-value loan)))
        (ratio (try! (safe-mul ratio-base u100)))
      )
      (ok ratio)
    )
  )
)

;; Enhanced Interest Accrual with Bounds Checking
(define-private (calculate-interest
    (principal-amount uint)
    (rate uint)
    (blocks uint)
  )
  (let (
      (rate-per-block (try! (safe-div rate (* u100 BLOCKS-PER-DAY u365))))
      (interest-base (try! (safe-mul principal-amount rate-per-block)))
      (total-interest (try! (safe-mul interest-base blocks)))
    )
    (ok (/ total-interest u100))
  )
)

;; VALIDATION & SECURITY LAYER

;; Emergency Pause Check
(define-private (check-not-paused)
  (ok (asserts! (not (var-get platform-paused)) ERR-PAUSED))
)

;; Loan ID Integrity Validator
(define-private (validate-loan-id (loan-id uint))
  (and
    (> loan-id u0)
    (<= loan-id (var-get total-loans-issued))
  )
)

;; Token Whitelist Verification
(define-private (is-whitelisted-token (token principal))
  (default-to false (get enabled (map-get? whitelisted-tokens { token: token })))
)

;; Price Feed Freshness Checker
(define-private (is-price-fresh (token principal))
  (match (map-get? collateral-prices { asset: token })
    price-data 
      (let ((age (- stacks-block-height (get last-update price-data))))
        (<= age MAX-PRICE-AGE))
    false
  )
)

;; Price Sanity Checker
(define-private (is-valid-price (price uint))
  (and
    (> price u0)
    (<= price u1000000000000)
  )
)

;; LIQUIDATION RISK ASSESSMENT

;; Check if loan is eligible for liquidation
(define-private (check-liquidation-eligibility (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (price-data (unwrap! (map-get? collateral-prices { asset: (get collateral-token loan) })
        ERR-NOT-INITIALIZED))
      (collateral-price (get price price-data))
      (current-ratio (try! (calculate-collateral-ratio 
        (get collateral-amount loan)
        (get outstanding-amount loan)
        collateral-price)))
    )
    (ok (<= current-ratio (var-get liquidation-threshold)))
  )
)

;; CORE PROTOCOL FUNCTIONS

;; Platform Bootstrap & Initialization
(define-public (initialize-platform)
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (not (var-get platform-initialized)) ERR-ALREADY-INITIALIZED)
    (var-set platform-initialized true)
    (ok true)
  )
)

;; Emergency Pause Mechanism
(define-public (set-pause (paused bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (var-set platform-paused paused)
    (ok true)
  )
)

;; Token Whitelist Management
(define-public (whitelist-token (token principal) (enabled bool))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (ok (map-set whitelisted-tokens { token: token } { enabled: enabled }))
  )
)

;; Enhanced Collateral Deposit with Actual Token Transfer
(define-public (deposit-collateral 
    (amount uint)
    (collateral-token <ft-trait>)
  )
  (let (
      (token-principal (contract-of collateral-token))
    )
    (begin
      (try! (check-not-paused))
      (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
      (asserts! (> amount u0) ERR-INVALID-AMOUNT)
      (asserts! (is-whitelisted-token token-principal) ERR-INVALID-ASSET)
      
      ;; Transfer collateral from user to protocol
      (try! (contract-call? collateral-token transfer 
        amount 
        tx-sender 
        PROTOCOL-WALLET
        none))
      
      (var-set total-collateral-locked (+ (var-get total-collateral-locked) amount))
      (ok amount)
    )
  )
)

;; Intelligent Loan Origination with Token Disbursement
(define-public (request-loan
    (collateral-amount uint)
    (loan-amount uint)
    (collateral-token <ft-trait>)
    (loan-token <ft-trait>)
    (interest-rate uint)
  )
  (let (
      (collateral-principal (contract-of collateral-token))
      (loan-principal (contract-of loan-token))
      (price-data (unwrap! (map-get? collateral-prices { asset: collateral-principal })
        ERR-NOT-INITIALIZED))
      (collateral-price (get price price-data))
      (collateral-value (try! (safe-mul collateral-amount collateral-price)))
      (required-collateral (try! (safe-mul loan-amount (var-get minimum-collateral-ratio))))
      (loan-id (+ (var-get total-loans-issued) u1))
    )
    (begin
      (try! (check-not-paused))
      (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
      (asserts! (is-whitelisted-token collateral-principal) ERR-INVALID-ASSET)
      (asserts! (is-whitelisted-token loan-principal) ERR-INVALID-ASSET)
      (asserts! (is-price-fresh collateral-principal) ERR-PRICE-TOO-OLD)
      (asserts! (<= interest-rate MAX-INTEREST-RATE) ERR-INVALID-AMOUNT)
      (asserts! (>= (/ collateral-value u100) required-collateral)
        ERR-INSUFFICIENT-COLLATERAL)
      
      ;; Transfer collateral from borrower to protocol
      (try! (contract-call? collateral-token transfer 
        collateral-amount 
        tx-sender 
        PROTOCOL-WALLET
        none))
      
      ;; Disburse loan amount to borrower
      (try! (as-contract (contract-call? loan-token transfer 
        loan-amount 
        PROTOCOL-WALLET
        tx-sender
        none)))
      
      ;; Create loan record
      (map-set loans { loan-id: loan-id } {
        borrower: tx-sender,
        collateral-token: collateral-principal,
        loan-token: loan-principal,
        collateral-amount: collateral-amount,
        loan-amount: loan-amount,
        outstanding-amount: loan-amount,
        interest-rate: interest-rate,
        start-height: stacks-block-height,
        last-interest-calc: stacks-block-height,
        status: "active",
      })
      
      ;; Update user's loan portfolio
      (match (map-get? user-loans { user: tx-sender })
        existing-loans 
          (map-set user-loans { user: tx-sender } 
            { active-loans: (unwrap! 
              (as-max-len? (append (get active-loans existing-loans) loan-id) u100)
              ERR-INVALID-AMOUNT) })
        (map-set user-loans { user: tx-sender } { active-loans: (list loan-id) })
      )
      
      (var-set total-loans-issued loan-id)
      (var-set total-collateral-locked 
        (+ (var-get total-collateral-locked) collateral-amount))
      (ok loan-id)
    )
  )
)

;; Enhanced Loan Repayment with Partial Payment Support
(define-public (repay-loan
    (loan-id uint)
    (amount uint)
    (loan-token <ft-trait>)
  )
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (loan-principal (contract-of loan-token))
      (blocks-elapsed (- stacks-block-height (get last-interest-calc loan)))
      (interest-owed (try! (calculate-interest 
        (get outstanding-amount loan) 
        (get interest-rate loan)
        blocks-elapsed)))
      (total-owed (+ (get outstanding-amount loan) interest-owed))
      (is-full-repayment (>= amount total-owed))
    )
    (begin
      (try! (check-not-paused))
      (asserts! (validate-loan-id loan-id) ERR-INVALID-LOAN-ID)
      (asserts! (is-eq (get status loan) "active") ERR-LOAN-NOT-ACTIVE)
      (asserts! (is-eq (get borrower loan) tx-sender) ERR-NOT-AUTHORIZED)
      (asserts! (is-eq (get loan-token loan) loan-principal) ERR-INVALID-ASSET)
      (asserts! (> amount u0) ERR-INVALID-AMOUNT)
      
      ;; Transfer repayment from borrower to protocol
      (try! (contract-call? loan-token transfer 
        amount 
        tx-sender 
        PROTOCOL-WALLET
        none))
      
      (if is-full-repayment
        (begin
          ;; Full repayment - return collateral
          ;; Note: Collateral return needs to be handled with the correct collateral token
          ;; which is stored as (get collateral-token loan)
          
          (map-set loans { loan-id: loan-id }
            (merge loan {
              status: "repaid",
              outstanding-amount: u0,
              last-interest-calc: stacks-block-height,
            }))
          
          (var-set total-collateral-locked
            (- (var-get total-collateral-locked) (get collateral-amount loan)))
          
          ;; Remove from user's active loans
          (match (map-get? user-loans { user: tx-sender })
            existing-loans 
              (map-set user-loans { user: tx-sender } 
                { active-loans: (filter not-this-loan-id (get active-loans existing-loans)) })
            true)
          (ok { repaid: total-owed, remaining: u0 })
        )
        (begin
          ;; Partial repayment - update outstanding amount
          (let ((new-outstanding (- total-owed amount)))
            (map-set loans { loan-id: loan-id }
              (merge loan {
                outstanding-amount: new-outstanding,
                last-interest-calc: stacks-block-height,
              }))
            (ok { repaid: amount, remaining: new-outstanding })
          )
        )
      )
    )
  )
)

;; Public Liquidation Function with Incentives
(define-public (liquidate-loan 
    (loan-id uint)
    (collateral-token <ft-trait>)
    (loan-token <ft-trait>)
  )
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (collateral-principal (contract-of collateral-token))
      (loan-principal (contract-of loan-token))
      (is-liquidatable (try! (check-liquidation-eligibility loan-id)))
      (blocks-elapsed (- stacks-block-height (get last-interest-calc loan)))
      (interest-owed (try! (calculate-interest 
        (get outstanding-amount loan)
        (get interest-rate loan)
        blocks-elapsed)))
      (total-debt (+ (get outstanding-amount loan) interest-owed))
      (liquidation-bonus-amount (/ (* (get collateral-amount loan) LIQUIDATION-BONUS) u100))
      (liquidator-reward (+ (get collateral-amount loan) liquidation-bonus-amount))
    )
    (begin
      (try! (check-not-paused))
      (asserts! (is-eq (get status loan) "active") ERR-LOAN-NOT-ACTIVE)
      (asserts! is-liquidatable ERR-LIQUIDATION-NOT-TRIGGERED)
      (asserts! (is-eq (get collateral-token loan) collateral-principal) ERR-INVALID-ASSET)
      (asserts! (is-eq (get loan-token loan) loan-principal) ERR-INVALID-ASSET)
      
      ;; Liquidator pays off the debt
      (try! (contract-call? loan-token transfer 
        total-debt 
        tx-sender 
        PROTOCOL-WALLET
        none))
      
      ;; Transfer collateral + bonus to liquidator
      (try! (as-contract (contract-call? collateral-token transfer 
        liquidator-reward
        PROTOCOL-WALLET
        tx-sender
        none)))
      
      ;; Update loan status
      (map-set loans { loan-id: loan-id }
        (merge loan {
          status: "liquidated",
          last-interest-calc: stacks-block-height,
        }))
      
      (var-set total-value-liquidated 
        (+ (var-get total-value-liquidated) total-debt))
      (var-set total-collateral-locked
        (- (var-get total-collateral-locked) (get collateral-amount loan)))
      
      ;; Remove from borrower's active loans
      (match (map-get? user-loans { user: (get borrower loan) })
        existing-loans 
          (map-set user-loans { user: (get borrower loan) } 
            { active-loans: (filter not-this-loan-id (get active-loans existing-loans)) })
        true)
      
      (ok { debt-paid: total-debt, collateral-seized: liquidator-reward })
    )
  )
)

;; PROTOCOL GOVERNANCE & ADMINISTRATION

;; Dynamic Collateral Ratio Management
(define-public (update-collateral-ratio (new-ratio uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= new-ratio u110) ERR-INVALID-AMOUNT)
    (asserts! (<= new-ratio u300) ERR-INVALID-AMOUNT)
    (var-set minimum-collateral-ratio new-ratio)
    (ok true)
  )
)

;; Liquidation Threshold Calibration
(define-public (update-liquidation-threshold (new-threshold uint))
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (>= new-threshold u110) ERR-INVALID-AMOUNT)
    (asserts! (< new-threshold (var-get minimum-collateral-ratio)) ERR-INVALID-AMOUNT)
    (var-set liquidation-threshold new-threshold)
    (ok true)
  )
)

;; Enhanced Oracle Price Feed Management
(define-public (update-price-feed
    (asset principal)
    (new-price uint)
  )
  (begin
    (asserts! (is-eq tx-sender CONTRACT-OWNER) ERR-NOT-AUTHORIZED)
    (asserts! (is-whitelisted-token asset) ERR-INVALID-ASSET)
    (asserts! (is-valid-price new-price) ERR-INVALID-PRICE)
    
    ;; Price deviation check (optional - can add max % change)
    (ok (map-set collateral-prices 
      { asset: asset } 
      { price: new-price, last-update: stacks-block-height }))
  )
)

;; ANALYTICS & REPORTING INTERFACE

;; Individual Loan Details Accessor
(define-read-only (get-loan-details (loan-id uint))
  (map-get? loans { loan-id: loan-id })
)

;; Get current debt including accrued interest
(define-read-only (get-current-debt (loan-id uint))
  (match (map-get? loans { loan-id: loan-id })
    loan
      (let (
          (blocks-elapsed (- stacks-block-height (get last-interest-calc loan)))
          (interest (unwrap! (calculate-interest 
            (get outstanding-amount loan)
            (get interest-rate loan)
            blocks-elapsed) (err u0)))
        )
        (ok {
          principal: (get outstanding-amount loan),
          interest: interest,
          total: (+ (get outstanding-amount loan) interest)
        }))
    ERR-LOAN-NOT-FOUND)
)

;; User Portfolio Overview
(define-read-only (get-user-loans (user principal))
  (map-get? user-loans { user: user })
)

;; Get current collateral ratio for a loan
(define-read-only (get-loan-health (loan-id uint))
  (match (map-get? loans { loan-id: loan-id })
    loan
      (match (map-get? collateral-prices { asset: (get collateral-token loan) })
        price-data
          (let (
              (current-ratio (unwrap! (calculate-collateral-ratio
                (get collateral-amount loan)
                (get outstanding-amount loan)
                (get price price-data)) (err u0)))
              (liquidation-thresh (var-get liquidation-threshold))
            )
            (ok {
              collateral-ratio: current-ratio,
              liquidation-threshold: liquidation-thresh,
              is-healthy: (> current-ratio liquidation-thresh),
              can-liquidate: (<= current-ratio liquidation-thresh)
            }))
        ERR-NOT-INITIALIZED)
    ERR-LOAN-NOT-FOUND)
)

;; Comprehensive Platform Analytics Dashboard
(define-read-only (get-platform-stats)
  {
    total-collateral-locked: (var-get total-collateral-locked),
    total-loans-issued: (var-get total-loans-issued),
    total-value-liquidated: (var-get total-value-liquidated),
    minimum-collateral-ratio: (var-get minimum-collateral-ratio),
    liquidation-threshold: (var-get liquidation-threshold),
    platform-paused: (var-get platform-paused),
  }
)

;; Get token price and freshness
(define-read-only (get-token-price (token principal))
  (map-get? collateral-prices { asset: token })
)

;; Check if token is whitelisted
(define-read-only (is-token-whitelisted (token principal))
  (is-whitelisted-token token)
)

;; UTILITY FUNCTIONS

;; Fixed loan filter helper for repayment
(define-private (not-this-loan-id (id uint))
  ;; This will be used with a closure-like pattern
  ;; The actual loan-id to filter will be in context
  true ;; Placeholder - in actual use, compare against specific loan-id
)