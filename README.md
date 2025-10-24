# 🌐 Smart Bandwidth Sharing Pool

> **Decentralized Internet Infrastructure on Stacks** 📡

A revolutionary smart contract that enables users to share unused bandwidth and earn rewards while contributing to decentralized internet infrastructure. Perfect for creating mesh networks and providing affordable connectivity in underserved areas.

## 🎯 Overview

The Smart Bandwidth Sharing Pool addresses the uneven distribution of internet bandwidth by creating a decentralized marketplace where users can:

- 📤 **Share unused Wi-Fi or mobile data** to pooled networks
- 💰 **Earn proportional rewards** through smart contract automation  
- 🏆 **Build reputation** based on contribution history
- 🤝 **Join community pools** for collaborative bandwidth sharing
- 🌍 **Support offline-first areas** through mesh network integration

## ✨ Key Features

### 🔧 Core Functionality
- **User Registration**: Create profiles with reputation tracking
- **Pool Creation**: Establish bandwidth sharing pools with custom reward rates
- **Bandwidth Contribution**: Share unused data and earn tokens automatically
- **Bandwidth Consumption**: Access shared bandwidth using earned tokens
- **Reward System**: Automated token distribution based on contributions
- **Reputation Tracking**: Build trust through consistent participation

### 🛡️ Security & Management
- **Owner Controls**: Administrative functions for pool management
- **Input Validation**: Comprehensive error handling and data validation
- **Activity Monitoring**: Track all user interactions and pool statistics

## 🚀 Getting Started

### Prerequisites
- [Clarinet](https://github.com/hirosystems/clarinet) installed
- [Node.js](https://nodejs.org/) for testing
- Stacks wallet for deployment

### Installation

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd Smart-Bandwidth-Sharing-Pool
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

## 📖 Usage Guide

### 1. User Registration 👤

```clarity
;; Register as a new user
(contract-call? .smart-bandwidth-sharing-pool register-user)
```

### 2. Create a Bandwidth Pool 🏊‍♂️

```clarity
;; Create a pool with name and reward rate per MB
(contract-call? .smart-bandwidth-sharing-pool create-bandwidth-pool "Rural-Mesh-Network" u5)
```

### 3. Contribute Bandwidth 📡

```clarity
;; Share 1000 MB to pool #1
(contract-call? .smart-bandwidth-sharing-pool contribute-bandwidth u1 u1000)
```

### 4. Consume Bandwidth 📥

```clarity
;; Use 500 MB from pool #1
(contract-call? .smart-bandwidth-sharing-pool consume-bandwidth u1 u500)
```

### 5. Claim Rewards 💎

```clarity
;; Claim pending rewards from pool #1
(contract-call? .smart-bandwidth-sharing-pool claim-rewards u1)
```

## 🔍 Read-Only Functions

### User Information
```clarity
;; Get complete user profile
(contract-call? .smart-bandwidth-sharing-pool get-user-profile 'SP1234...)

;; Calculate user efficiency score
(contract-call? .smart-bandwidth-sharing-pool calculate-user-efficiency 'SP1234...)
```

### Pool Information
```clarity
;; Get pool details
(contract-call? .smart-bandwidth-sharing-pool get-pool-info u1)

;; Check user contributions to specific pool
(contract-call? .smart-bandwidth-sharing-pool get-user-contribution 'SP1234... u1)

;; Verify pool membership
(contract-call? .smart-bandwidth-sharing-pool is-pool-member u1 'SP1234...)
```

### Network Statistics
```clarity
;; Get total bandwidth shared across all pools
(contract-call? .smart-bandwidth-sharing-pool get-total-bandwidth-shared)

;; Get total number of pools
(contract-call? .smart-bandwidth-sharing-pool get-total-pools)

;; Get current reward rate
(contract-call? .smart-bandwidth-sharing-pool get-reward-rate)
```

## 🏗️ Contract Architecture

### Data Structures

#### User Profiles
- **bandwidth-contributed**: Total MB shared
- **bandwidth-consumed**: Total MB used
- **rewards-earned**: Lifetime token earnings
- **registration-height**: Block height when registered
- **is-active**: Account status
- **reputation-score**: Trust metric (0-1000)

#### Bandwidth Pools
- **pool-name**: Human-readable identifier
- **total-bandwidth**: Available MB in pool
- **active-contributors**: Number of sharing users
- **reward-per-mb**: Token rate per MB shared
- **created-height**: Pool creation block
- **is-active**: Pool operational status

#### Contributions
- **bandwidth-shared**: User's total contribution to pool
- **rewards-pending**: Unclaimed tokens
- **last-contribution-height**: Most recent activity

## ⚙️ Configuration

### Contract Constants
- **minimum-contribution**: 100 MB minimum sharing amount
- **reward-rate**: Base reward multiplier (10)
- **max-reputation**: Maximum reputation score (1000)

### Error Codes
- `u100`: Owner-only function access
- `u101`: Insufficient bandwidth available
- `u102`: User not found or inactive
- `u103`: Invalid amount parameter
- `u104`: Pool not found or inactive
- `u105`: User already registered
- `u106`: Insufficient token balance
- `u107`: Invalid sharing rate
- `u108`: Reward calculation failed

## 🌟 Real-World Impact

### 🌾 Rural Connectivity
- Enable affordable internet access in remote areas
- Support community-owned network infrastructure
- Reduce dependency on traditional ISPs

### 💡 Smart Resource Management
- Optimize bandwidth utilization efficiency
- Incentivize network participation
- Create sustainable sharing economies

### 🚀 Decentralized Infrastructure
- Build resilient mesh networks
- Enable offline-first connectivity solutions
- Foster community-driven internet governance

## 🧪 Testing

Run the comprehensive test suite:

```bash
npm test
```

Tests cover:
- User registration and profile management
- Pool creation and bandwidth operations
- Reward calculations and token mechanics
- Error handling and edge cases
- Administrative functions

## 🔮 Future Enhancements

- **Mobile App Integration**: Native iOS/Android applications
- **Mesh Network Protocol**: Direct device-to-device communication
- **Geographic Pooling**: Location-based bandwidth sharing
- **Quality Monitoring**: Connection speed and reliability metrics
- **Governance Token**: Community voting on protocol upgrades

## 📄 License

MIT License - see LICENSE file for details

## 🤝 Contributing

We welcome contributions! Please read our contributing guidelines and submit pull requests for any improvements.

---

**Built with ❤️ for the decentralized internet revolution** 🌐✨

