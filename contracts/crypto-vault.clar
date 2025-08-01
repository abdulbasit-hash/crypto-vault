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

;; SYSTEM CONSTANTS & ERROR CODES

(define-constant CONTRACT-OWNER tx-sender)

;; Authorization & Access Control Errors
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-NOT-INITIALIZED (err u105))
(define-constant ERR-ALREADY-INITIALIZED (err u104))

;; Collateral & Risk Management Errors
(define-constant ERR-INSUFFICIENT-COLLATERAL (err u101))
(define-constant ERR-BELOW-MINIMUM (err u102))
(define-constant ERR-INVALID-LIQUIDATION (err u106))

;; Loan Lifecycle Errors
(define-constant ERR-LOAN-NOT-FOUND (err u107))
(define-constant ERR-LOAN-NOT-ACTIVE (err u108))
(define-constant ERR-INVALID-LOAN-ID (err u109))

;; Validation Errors
(define-constant ERR-INVALID-AMOUNT (err u103))
(define-constant ERR-INVALID-PRICE (err u110))
(define-constant ERR-INVALID-ASSET (err u111))

;; Supported Asset Registry
(define-constant VALID-ASSETS (list "BTC" "STX"))

;; PROTOCOL CONFIGURATION VARIABLES

;; Platform Initialization State
(define-data-var platform-initialized bool false)

;; Risk Management Parameters
(define-data-var minimum-collateral-ratio uint u150) ;; 150% minimum collateralization
(define-data-var liquidation-threshold uint u120) ;; 120% triggers liquidation engine
(define-data-var platform-fee-rate uint u1) ;; 1% protocol fee structure

;; Global Protocol Metrics
(define-data-var total-btc-locked uint u0)
(define-data-var total-loans-issued uint u0)

;; DATA STORAGE ARCHITECTURE

;; Primary Loan Registry
(define-map loans
  { loan-id: uint }
  {
    borrower: principal,
    collateral-amount: uint,
    loan-amount: uint,
    interest-rate: uint,
    start-height: uint,
    last-interest-calc: uint,
    status: (string-ascii 20),
  }
)

;; User Loan Portfolio Mapping
(define-map user-loans
  { user: principal }
  { active-loans: (list 10 uint) }
)

;; Oracle Price Feed Registry
(define-map collateral-prices
  { asset: (string-ascii 3) }
  { price: uint }
)

;; FINANCIAL CALCULATION ENGINE

;; Advanced Collateral Ratio Calculator
(define-private (calculate-collateral-ratio
    (collateral uint)
    (loan uint)
    (btc-price uint)
  )
  (let (
      (collateral-value (* collateral btc-price))
      (ratio (* (/ collateral-value loan) u100))
    )
    ratio
  )
)

;; Dynamic Interest Accrual System
(define-private (calculate-interest
    (principal uint)
    (rate uint)
    (blocks uint)
  )
  (let (
      (interest-per-block (/ (* principal rate) (* u100 u144))) ;; Daily interest normalized to block time
      (total-interest (* interest-per-block blocks))
    )
    total-interest
  )
)

;; Automated Liquidation Risk Assessment
(define-private (check-liquidation (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (btc-price (unwrap! (get price (map-get? collateral-prices { asset: "BTC" }))
        ERR-NOT-INITIALIZED
      ))
      (current-ratio (calculate-collateral-ratio (get collateral-amount loan)
        (get loan-amount loan) btc-price
      ))
    )
    (if (<= current-ratio (var-get liquidation-threshold))
      (liquidate-position loan-id)
      (ok true)
    )
  )
)

;; Liquidation Execution Engine
(define-private (liquidate-position (loan-id uint))
  (let (
      (loan (unwrap! (map-get? loans { loan-id: loan-id }) ERR-LOAN-NOT-FOUND))
      (borrower (get borrower loan))
    )
    (begin
      (map-set loans { loan-id: loan-id } (merge loan { status: "liquidated" }))
      (map-delete user-loans { user: borrower })
      (ok true)
    )
  )
)

;; VALIDATION & SECURITY LAYER

;; Loan ID Integrity Validator
(define-private (validate-loan-id (loan-id uint))
  (and
    (> loan-id u0)
    (<= loan-id (var-get total-loans-issued))
  )
)

;; Asset Whitelist Verification
(define-private (is-valid-asset (asset (string-ascii 3)))
  (is-some (index-of VALID-ASSETS asset))
)

;; Price Feed Sanity Checker
(define-private (is-valid-price (price uint))
  (and
    (> price u0)
    (<= price u1000000000000) ;; Reasonable upper bound for price validation
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

;; Collateral Deposit Gateway
(define-public (deposit-collateral (amount uint))
  (begin
    (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
    (asserts! (> amount u0) ERR-INVALID-AMOUNT)
    (var-set total-btc-locked (+ (var-get total-btc-locked) amount))
    (ok true)
  )
)

;; Intelligent Loan Origination System
(define-public (request-loan
    (collateral uint)
    (loan-amount uint)
  )
  (let (
      (btc-price (unwrap! (get price (map-get? collateral-prices { asset: "BTC" }))
        ERR-NOT-INITIALIZED
      ))
      (collateral-value (* collateral btc-price))
      (required-collateral (* loan-amount (var-get minimum-collateral-ratio)))
      (loan-id (+ (var-get total-loans-issued) u1))
    )
    (begin
      (asserts! (var-get platform-initialized) ERR-NOT-INITIALIZED)
      (asserts! (>= collateral-value required-collateral)
        ERR-INSUFFICIENT-COLLATERAL
      )
      ;; Create new loan record
      (map-set loans { loan-id: loan-id } {
        borrower: tx-sender,
        collateral-amount: collateral,
        loan-amount: loan-amount,
        interest-rate: u5, ;; 5% annual interest rate
        start-height: block-height,
        last-interest-calc: block-height,
        status: "active",
      })
      ;; Update user's loan portfolio
      (match (map-get? user-loans { user: tx-sender })
        existing-loans (map-set user-loans { user: tx-sender } { active-loans: (unwrap!
          (as-max-len? (append (get active-loans existing-loans) loan-id) u10)
          ERR-INVALID-AMOUNT
        ) }
        )
        (map-set user-loans { user: tx-sender } { active-loans: (list loan-id) })
      )
      (var-set total-loans-issued (+ (var-get total-loans-issued) u1))
      (ok loan-id)
    )
  )
)