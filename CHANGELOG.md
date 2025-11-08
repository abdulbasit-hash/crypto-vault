# Changelog

All notable changes to the CryptoVault DeFi Lending Protocol will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added - Enhanced DeFi Lending V2

#### Configuration
- SIP-010 fungible token standard integration via Clarinet configuration
- Multi-token collateral and loan asset support
- Token whitelist management system

#### Security & Safety
- Safe math library with overflow/underflow protection
  - `safe-mul`: Multiplication with overflow detection
  - `safe-add`: Addition with overflow detection  
  - `safe-div`: Division with zero-check protection
- Emergency pause mechanism for protocol-wide operations
- Price staleness validation (10-day maximum age)
- Enhanced validation for liquidation triggers

#### Core Features
- **Multi-Token Support**: Accept any whitelisted SIP-010 token as collateral or loan asset
- **Partial Repayments**: Support gradual loan repayment with outstanding amount tracking
- **Public Liquidations**: Permissionless liquidation with 10% bonus incentive
- **Dynamic Interest Rates**: Configurable rates up to 50% maximum
- **Enhanced Loan Capacity**: Increased from 10 to 100 active loans per user

#### Data & Analytics
- Real-time loan health monitoring via `get-loan-health`
- Current debt calculation including accrued interest via `get-current-debt`
- Total liquidation value tracking
- Price feed freshness indicators
- Token whitelist status queries

#### Technical Improvements
- Refactored financial calculations to use safe math operations
- Actual token transfers via SIP-010 trait contract calls
- Enhanced error codes for better debugging (18 total error codes)
- Protocol configuration constants for maintainability
- Improved collateral ratio calculation with zero-division protection

### Changed
- Loan data structure now includes `collateral-token`, `loan-token`, and `outstanding-amount`
- Price feed now includes `last-update` timestamp
- Interest calculation uses annualized rates with block-based accrual
- Liquidation threshold updated from 120% to 125%
- Platform metrics renamed for clarity (`total-btc-locked` → `total-collateral-locked`)

### Fixed
- Division by zero vulnerability in collateral ratio calculations
- Arithmetic overflow risks in financial calculations
- Loan filter helper function (`not-this-loan-id`) for proper loan list management

### Security Considerations
- All public functions now check platform pause status
- Token transfers validated against whitelist
- Price feeds validated for freshness before use
- Collateral ratios validated against minimum thresholds
- Liquidation eligibility verified before execution

## Protocol Parameters

| Parameter | Value | Description |
|-----------|-------|-------------|
| Minimum Collateral Ratio | 150% | Required over-collateralization |
| Liquidation Threshold | 125% | Triggers liquidation eligibility |
| Liquidation Bonus | 10% | Incentive for liquidators |
| Max Interest Rate | 50% | Maximum allowed annual rate |
| Max Price Age | 10 days | Price feed staleness limit |
| Platform Fee | 1% | Protocol fee rate |
