# Privacy & Data Protection Policy

Smoking patterns and cravings reflect deeply intimate habits, health vulnerabilities, and personal routines. Clarity treats this data with the highest standard of privacy.

---

## 1. Principles of Privacy
1. **Zero Advertising Monopolies**: Clarity does not sell, license, or share user health data with data brokers, advertisers, or third-party behavioral profiling networks.
2. **Encrypted in Transit & at Rest**: All API interactions require TLS/HTTPS encryption. Passwords are cryptographically salted with `bcrypt` (work factor 12+).
3. **Structured Context Minimization**: When interacting with AI coaches, the system does NOT transmit the user's raw database or personal identifiers. It sends only aggregated behavioral metrics (current target, count, delay capacity, triggers).
4. **GDPR / CCPA Compliant Rights**:
   - **Right to Access & Portability**: Users can download an unencrypted JSON export of their complete smoking history, cravings, targets, and progress snapshots at any time (`GET /api/v1/settings/export-data`).
   - **Right to Erasure (Forget Me)**: Users can permanently delete their account with one tap (`DELETE /api/v1/settings/account`). All foreign key relationships cascade-delete immediately.
