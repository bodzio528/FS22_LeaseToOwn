# FS22_LeaseToOwn
Mod for Farming Simulator 22

## Description
In general, lease-to-own refers to methods by which a lease contract provides for the tenant to eventually purchase the property.
One common lease-to-own strategy is to include an option to purchase provision in the lease.
This clause states that the tenant may purchase the leased premises during a particular time period and according to terms specified in the lease.

This mod enable to purchase leased equipment at the price reduced by the paid leasing installments.
The residual value of the post-lease vehicle is 22% of the initial value.

All amounts are aligned with the lease costs in the the base game.

## Usage limit and extended lease period behaviour

After lease agreement expiry (3 years/20 hours) installments are still paid in unchanged amount, that is not deduced from item residual value.
It is user responsibility to purchase the item when it is most cost efficient (which just after 36 months OR 20 operating hours)

Note that situation where equipment is used for 20 hours exactly 3 years after the lease started is nearly impossible in practice.
At that moment farmer may not have the funds required to finalize the transation, thus automatic repurchase of leased property could not be made.
I decided to put abovementioned limits to protect residual value of equipment from reaching less than zero by extedned leasing.
This way owner will never actually get additional cash from leasing.

All installments paid above limit is lost.

### Example 1: target residual value reached (both lease period and operating time fully utilized)

Equipment cost was 100 000 purchase after 3 years. Total operating hours count is 20.
  Initial base fee (2%) = 2 000
  Monthly installments paid (1% x 36) = 36 000
  Operating hours paid (2.1% x 20) = 42 000
  Leasing agreement is fully utilized (all 36 months)
  Purchase cost = 22000
  Total cost = 102000 (102% of store price)

### Example 2: neither operating hours limit nor lease period reached

Equipment cost was 100 000 purchase after 2 years. Total operating hours count is 10.

  Initial base fee (2%) = 2 000
  Monthly installments paid (1% x 24) = 24 000
  Operating hours paid (2.1% x 10) = 21 000
  Leasing agreement is utilized in 2/3rd = 666 to be returned
  Purchase cost = 54 334
  Total = 101 334 (101.33% of store price)

### Example 3: lease period overdue, operating hours limit exceeded

Equipment cost was 100 000 purchase after 4 years. Total operating hours count is 30.

  Initial base fee (2%) = 2 000
  Monthly installments paid (1% x 48) = 48 000
  Operating hours paid (2.1 x 30) = 63 000
  Leasing agreement is fully utilized (36+ months)
  Purchase cost = 22 000 (residual value)
  Total = 135 000 (135% of store price)

### Example 4: purchase immediately after leasing

Equipment cost was 100 000 purchase after 0 months. Total operating hours count is 0.

  Initial base fee (2%) = 2 000
  Monthly installments paid (1% x 1) = 1 000
  Operating hours paid (2.1 x 1) = 2 100
  Leasing agreement not utilized at all (2 000 to be returned)
  Purchase cost = 94 900
  Total = 100 000 (100% of store price)

## Notes
Mod does not interact with savegame files. No new savegame is required, and disabling the mod does not break the save.
