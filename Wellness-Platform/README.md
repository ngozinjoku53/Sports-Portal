# Athlete Wellness Tracking Smart Contract

A comprehensive Clarity smart contract for tracking athlete wellness data, training sessions, and managing access permissions on the Stacks blockchain.

## Overview

This smart contract enables athletes, coaches, and authorized personnel to record, track, and analyze athlete wellness metrics and training data in a secure, decentralized manner. The contract implements role-based access control to ensure data privacy while allowing necessary stakeholders to access relevant information.

## Features

- **Athlete Registration**: Athletes can register themselves with personal and sport-specific information
- **Coach Management**: Coach registration with certification and specialization tracking
- **Wellness Metrics Tracking**: Daily wellness data including heart rate, sleep, stress levels, and more
- **Training Session Logging**: Comprehensive training session records with intensity and performance data
- **Permission System**: Granular access control for data reading and writing
- **Data Privacy**: Athletes control who can access their data
- **Wellness Scoring**: Built-in algorithm to calculate overall wellness scores

## Data Structures

### Athletes
- Name, sport, team affiliation
- Assigned coach
- Registration status and creation timestamp

### Wellness Metrics
- Resting heart rate
- Sleep hours
- Stress level (1-10 scale)
- Energy level (1-10 scale)
- Hydration level (1-10 scale)
- Muscle soreness (1-10 scale)
- Weight (in kg × 100 for decimal precision)
- Notes and timestamp

### Training Sessions
- Session date and duration
- Intensity level (1-10 scale)
- Session type and calories burned
- Training notes
- Unique session ID tracking

### Coaches
- Name and certification details
- Specialization area
- Active status

## Access Control

The contract implements a three-tier permission system:

1. **Athlete**: Full control over their own data
2. **Coach**: Access to their assigned athletes' data
3. **Authorized Users**: Custom read/write permissions granted by athletes

## Public Functions

### Registration Functions

#### `register-athlete`
```clarity
(register-athlete (athlete-id principal) (name string) (sport string) (team string) (coach principal))
```
Registers a new athlete. Only the athlete themselves can call this function.

#### `register-coach`
```clarity
(register-coach (coach-id principal) (name string) (certification string) (specialization string))
```
Registers a new coach with their credentials.

### Data Recording Functions

#### `record-wellness-metrics`
```clarity
(record-wellness-metrics (athlete-id principal) (date uint) (heart-rate-resting uint) (sleep-hours uint) (stress-level uint) (energy-level uint) (hydration-level uint) (muscle-soreness uint) (weight uint) (notes string))
```
Records daily wellness metrics. Can be called by the athlete, their coach, or authorized users.

**Validation Rules:**
- Stress, energy, hydration, and soreness levels: 1-10 scale
- Heart rate: 30-200 BPM range
- Sleep hours: 0-24 hours

#### `record-training-session`
```clarity
(record-training-session (athlete-id principal) (date uint) (duration uint) (intensity uint) (session-type string) (calories-burned uint) (notes string))
```
Logs a training session with performance metrics.

**Validation Rules:**
- Intensity: 1-10 scale
- Duration: Must be greater than 0
- Session type: Required field

### Permission Management

#### `grant-permission`
```clarity
(grant-permission (athlete-id principal) (accessor principal) (can-read bool) (can-write bool))
```
Grants read/write permissions to specified users. Only athletes can grant permissions for their own data.

#### `revoke-permission`
```clarity
(revoke-permission (athlete-id principal) (accessor principal))
```
Revokes previously granted permissions.

#### `update-athlete-status`
```clarity
(update-athlete-status (athlete-id principal) (is-active bool))
```
Updates athlete's active status. Can be called by the athlete or contract owner.

## Read-Only Functions

### Data Retrieval

#### `get-athlete`
Returns athlete information for a given principal.

#### `get-coach`
Returns coach information for a given principal.

#### `get-wellness-metrics`
Retrieves wellness data for a specific athlete and date (permission-based access).

#### `get-training-session`
Fetches training session data by athlete ID and session ID.

### Utility Functions

#### `can-access-athlete-data`
Checks if the caller has permission to access an athlete's data.

#### `get-permissions`
Returns permission settings for a specific accessor (only viewable by the athlete).

#### `calculate-wellness-score`
Calculates an overall wellness score (1-100) based on key metrics:
- Inverts stress and soreness scores (lower is better)
- Optimizes sleep score for 7-9 hours
- Combines all factors into a comprehensive score

## Error Codes

| Code | Constant | Description |
|------|----------|-------------|
| 100 | ERR-NOT-AUTHORIZED | Unauthorized access attempt |
| 101 | ERR-ATHLETE-NOT-FOUND | Athlete not registered |
| 102 | ERR-INVALID-METRIC | Metric value outside valid range |
| 103 | ERR-ALREADY-EXISTS | Entity already registered |
| 104 | ERR-INVALID-VALUE | Invalid input value |
| 105 | ERR-NOT-COACH | Caller is not a registered coach |
| 106 | ERR-PERMISSION-DENIED | Insufficient permissions |

## Usage Examples

### Registering an Athlete
```clarity
(contract-call? .athlete-wellness register-athlete 
    'SP1234567890ABCDEF 
    "John Doe" 
    "Basketball" 
    "Lakers" 
    'SP0987654321FEDCBA)
```

### Recording Wellness Data
```clarity
(contract-call? .athlete-wellness record-wellness-metrics 
    'SP1234567890ABCDEF 
    u20240115 
    u65 
    u8 
    u3 
    u8 
    u7 
    u2 
    u7500 
    "Feeling good today")
```

### Granting Access Permission
```clarity
(contract-call? .athlete-wellness grant-permission 
    'SP1234567890ABCDEF 
    'SP1111222233334444 
    true 
    false)
```

## Security Features

- **Self-Registration**: Only principals can register themselves
- **Data Ownership**: Athletes maintain full control over their data
- **Role-Based Access**: Coaches have automatic access to their athletes' data
- **Granular Permissions**: Fine-grained read/write access control
- **Input Validation**: Comprehensive validation for all metrics and inputs
- **Immutable Records**: Blockchain-based immutable audit trail

## Best Practices

1. **Regular Data Entry**: Record wellness metrics daily for meaningful trends
2. **Permission Management**: Regularly review and update access permissions
3. **Data Quality**: Ensure accurate and consistent data entry
4. **Privacy Awareness**: Be mindful of who has access to sensitive health data
5. **Backup Considerations**: While blockchain provides immutability, maintain external backups of critical metadata

## Contract Deployment

Deploy this contract to the Stacks blockchain using Clarinet or other Stacks development tools. Ensure proper testing in a testnet environment before mainnet deployment.