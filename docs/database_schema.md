# Database Schema (Firebase Firestore)

- Agencies: {agency_id, name, subscription_plan, stripe_connect_id}
- Users: {user_id, agency_id, role (SuperAdmin, AgencyAdmin, Broker, Owner, Tenant), full_name}
- Properties: {property_id, agency_id, owner_id, type, status, location}
- Leases: {lease_id, property_id, tenant_id, rent_amount, dates}
- Transactions: {transaction_id, lease_id, split_logic (platform_fee, agency_fee, owner_payout)}
