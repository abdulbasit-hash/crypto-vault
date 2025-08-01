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