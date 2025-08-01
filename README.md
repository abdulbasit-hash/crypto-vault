# CryptoVault DeFi Lending Protocol

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Clarity](https://img.shields.io/badge/Clarity-Smart%20Contract-purple)](https://clarity-lang.org/)
[![Stacks](https://img.shields.io/badge/Stacks-Blockchain-orange)](https://www.stacks.co/)

> Revolutionary trustless lending infrastructure enabling seamless cryptocurrency-backed credit facilities with automated risk management and dynamic liquidation mechanisms.

## 🌟 Overview

CryptoVault transforms traditional lending by creating a fully decentralized ecosystem where digital assets serve as intelligent collateral. Users can unlock liquidity from their crypto holdings without selling, while the protocol ensures security through sophisticated over-collateralization models, real-time price feeds, and automated liquidation safeguards.

Built for the future of decentralized finance, CryptoVault democratizes access to credit markets while maintaining institutional-grade security and transparency on the Stacks blockchain.

## 🏗️ Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                    CryptoVault Protocol                    │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌─────────────────┐  ┌─────────────────┐  ┌──────────────┐ │
│  │   Governance    │  │   Risk Engine   │  │   Oracle     │ │
│  │   & Admin       │  │   & Analytics   │  │   System     │ │
│  └─────────────────┘  └─────────────────┘  └──────────────┘ │
│           │                     │                   │       │
│           └─────────────────────┼───────────────────┘       │
│                                 │                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                Core Protocol Layer                     │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │ │
│  │  │   Lending   │  │ Collateral  │  │   Liquidation   │ │ │
│  │  │   Engine    │  │ Management  │  │     Engine      │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
│           │                     │                   │       │
│           └─────────────────────┼───────────────────┘       │
│                                 │                           │
│  ┌─────────────────────────────────────────────────────────┐ │
│  │                 Data Storage Layer                     │ │
│  │                                                         │ │
│  │  ┌─────────────┐  ┌─────────────┐  ┌─────────────────┐ │ │
│  │  │    Loans    │  │ User Loans  │  │ Price Feeds &   │ │ │
│  │  │   Registry  │  │  Portfolio  │  │  Asset Registry │ │ │
│  │  └─────────────┘  └─────────────┘  └─────────────────┘ │ │
│  └─────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────┘
```

### Core Components

#### 1. **Lending Engine**

- **Loan Origination**: Automated loan processing with collateral validation
- **Interest Calculation**: Dynamic interest accrual based on block time
- **Repayment Handler**: Comprehensive loan repayment with collateral release

#### 2. **Risk Management System**

- **Collateral Ratio Calculator**: Real-time over-collateralization monitoring
- **Liquidation Engine**: Automated position liquidation when ratios fall below threshold
- **Risk Assessment**: Continuous monitoring of loan health

#### 3. **Oracle & Price Feeds**

- **Multi-Asset Support**: BTC and STX price feeds
- **Price Validation**: Sanity checks for price feed updates
- **Admin Controls**: Secure price feed management

#### 4. **Data Architecture**

- **Loan Registry**: Primary storage for all loan data
- **User Portfolio**: Mapping of users to their active loans
- **Price Storage**: Decentralized price feed registry

## 🚀 Features

### For Borrowers

- **Instant Liquidity**: Access funds without selling your crypto
- **Competitive Rates**: Dynamic interest rates starting at 5% annually
- **Multi-Asset Collateral**: Support for BTC and STX
- **Flexible Repayment**: Pay back loans at any time

### For the Protocol

- **Over-Collateralization**: Minimum 150% collateral ratio ensures security
- **Automated Liquidation**: Positions automatically liquidated at 120% ratio
- **Real-Time Monitoring**: Continuous risk assessment and management
- **Governance Controls**: Admin functions for protocol parameter updates

### Security Features

- **Input Validation**: Comprehensive validation for all user inputs
- **Access Controls**: Role-based permissions for critical functions
- **Price Feed Security**: Multiple validation layers for oracle data
- **Emergency Controls**: Admin override capabilities for risk management

## 📊 Protocol Parameters

| Parameter | Value | Description |
|-----------|--------|-------------|
| Minimum Collateral Ratio | 150% | Required over-collateralization for new loans |
| Liquidation Threshold | 120% | Ratio at which positions are automatically liquidated |
| Base Interest Rate | 5% | Annual interest rate for loans |
| Platform Fee | 1% | Protocol fee structure |
| Max Active Loans per User | 10 | Maximum number of concurrent loans |

## 🛠️ Installation & Setup

### Prerequisites

- [Clarinet](https://github.com/hirosystems/clarinet) - Clarity development environment
- [Node.js](https://nodejs.org/) - For testing framework
- [TypeScript](https://www.typescriptlang.org/) - For test development

### Quick Start

1. **Clone the repository**

   ```bash
   git clone https://github.com/abdulbasit-hash/crypto-vault.git
   cd crypto-vault
   ```

2. **Install dependencies**

   ```bash
   npm install
   ```

3. **Check contract syntax**

   ```bash
   clarinet check
   ```

4. **Run tests**

   ```bash
   npm test
   ```

## 🧪 Testing

The protocol includes comprehensive test coverage using Vitest and Clarinet:

```bash
# Run all tests
npm test

# Check contract syntax
clarinet check

# Interactive testing console
clarinet console
```

### Test Coverage Areas

- Loan origination and validation
- Collateral management and calculations
- Interest accrual and repayment
- Liquidation scenarios
- Access control and permissions
- Edge cases and error handling

## 📡 API Reference

### Public Functions

#### Core Operations

```clarity
;; Initialize the platform (Owner only)
(initialize-platform) -> (response bool uint)

;; Deposit collateral
(deposit-collateral (amount uint)) -> (response bool uint)

;; Request a new loan
(request-loan (collateral uint) (loan-amount uint)) -> (response uint uint)

;; Repay an existing loan
(repay-loan (loan-id uint) (amount uint)) -> (response bool uint)
```

#### Governance Functions

```clarity
;; Update collateral ratio (Owner only)
(update-collateral-ratio (new-ratio uint)) -> (response bool uint)

;; Update liquidation threshold (Owner only)
(update-liquidation-threshold (new-threshold uint)) -> (response bool uint)

;; Update price feeds (Owner only)
(update-price-feed (asset (string-ascii 3)) (new-price uint)) -> (response bool uint)
```

### Read-Only Functions

```clarity
;; Get loan details
(get-loan-details (loan-id uint)) -> (optional loan-data)

;; Get user's active loans
(get-user-loans (user principal)) -> (optional user-loan-data)

;; Get platform statistics
(get-platform-stats) -> platform-stats

;; Get supported assets
(get-valid-assets) -> (list string-ascii)
```

### Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| u100 | ERR-NOT-AUTHORIZED | Caller not authorized for this operation |
| u101 | ERR-INSUFFICIENT-COLLATERAL | Collateral insufficient for loan amount |
| u102 | ERR-BELOW-MINIMUM | Amount below minimum threshold |
| u103 | ERR-INVALID-AMOUNT | Invalid amount specified |
| u104 | ERR-ALREADY-INITIALIZED | Platform already initialized |
| u105 | ERR-NOT-INITIALIZED | Platform not yet initialized |
| u106 | ERR-INVALID-LIQUIDATION | Invalid liquidation attempt |
| u107 | ERR-LOAN-NOT-FOUND | Loan ID not found |
| u108 | ERR-LOAN-NOT-ACTIVE | Loan is not in active state |
| u109 | ERR-INVALID-LOAN-ID | Invalid loan identifier |
| u110 | ERR-INVALID-PRICE | Invalid price value |
| u111 | ERR-INVALID-ASSET | Asset not supported |

## 🔒 Security Considerations

### Smart Contract Security

- **Input Validation**: All parameters validated before processing
- **Overflow Protection**: Safe arithmetic operations throughout
- **Access Control**: Strict role-based permissions
- **State Consistency**: Atomic operations ensure data integrity

### Economic Security

- **Over-Collateralization**: 150% minimum ratio protects against volatility
- **Liquidation Mechanism**: Automated liquidation prevents bad debt
- **Price Feed Validation**: Multiple checks prevent oracle manipulation
- **Interest Accrual**: Fair and transparent interest calculation

### Best Practices

- Regular security audits recommended
- Monitor liquidation ratios closely
- Keep price feeds updated
- Implement circuit breakers for extreme market conditions

## 📈 Roadmap

### Phase 1: Core Protocol ✅

- [x] Basic lending and borrowing functionality
- [x] Collateral management system
- [x] Automated liquidation engine
- [x] Admin governance controls

### Phase 2: Enhanced Features 🚧

- [ ] Multi-asset collateral pools
- [ ] Variable interest rates
- [ ] Flash loan functionality
- [ ] Advanced analytics dashboard

### Phase 3: Ecosystem Integration 📋

- [ ] DEX integration for liquidations
- [ ] Cross-chain bridge support
- [ ] Mobile application interface
- [ ] Institutional features

## 🤝 Contributing

We welcome contributions to CryptoVault! Please see our [Contributing Guidelines](CONTRIBUTING.md) for details.

### Development Process

1. Fork the repository
2. Create a feature branch
3. Write comprehensive tests
4. Submit a pull request
5. Code review and merge

### Areas for Contribution

- Security audits and improvements
- Gas optimization
- New feature development
- Documentation improvements
- Test coverage expansion

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
