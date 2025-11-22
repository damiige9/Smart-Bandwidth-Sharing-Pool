
(define-fungible-token bandwidth-token)

(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-insufficient-bandwidth (err u101))
(define-constant err-user-not-found (err u102))
(define-constant err-invalid-amount (err u103))
(define-constant err-pool-not-found (err u104))
(define-constant err-already-registered (err u105))
(define-constant err-insufficient-balance (err u106))
(define-constant err-invalid-sharing-rate (err u107))
(define-constant err-reward-calculation-failed (err u108))
(define-constant err-invalid-referrer (err u109))
(define-constant err-self-referral (err u110))
(define-constant err-referral-already-set (err u111))
(define-constant err-lease-not-found (err u112))
(define-constant err-lease-expired (err u113))
(define-constant err-lease-active (err u114))
(define-constant err-insufficient-lease-balance (err u115))
(define-constant err-invalid-duration (err u116))

(define-data-var total-bandwidth-shared uint u0)
(define-data-var total-pools uint u0)
(define-data-var reward-rate uint u10)
(define-data-var minimum-contribution uint u100)
(define-data-var referral-bonus-percentage uint u10)
(define-data-var minimum-referral-contribution uint u500)
(define-data-var total-leases uint u0)
(define-data-var minimum-lease-duration uint u144)
(define-data-var maximum-lease-duration uint u52560)

(define-private (min-uint (a uint) (b uint))
  (if (<= a b) a b)
)

(define-map user-profiles
  principal
  {
    bandwidth-contributed: uint,
    bandwidth-consumed: uint,
    rewards-earned: uint,
    registration-height: uint,
    is-active: bool,
    reputation-score: uint
  }
)

(define-map bandwidth-pools
  uint
  {
    pool-name: (string-ascii 64),
    total-bandwidth: uint,
    active-contributors: uint,
    reward-per-mb: uint,
    created-height: uint,
    is-active: bool
  }
)

(define-map user-pool-contributions
  { user: principal, pool-id: uint }
  {
    bandwidth-shared: uint,
    rewards-pending: uint,
    last-contribution-height: uint
  }
)

(define-map pool-members
  { pool-id: uint, member: principal }
  bool
)

(define-map user-referrals
  principal
  {
    referrer: (optional principal),
    total-referrals: uint,
    referral-rewards: uint,
    referral-set: bool
  }
)

(define-map bandwidth-leases
  uint
  {
    lessor: principal,
    lessee: (optional principal),
    bandwidth-amount: uint,
    rate-per-mb: uint,
    start-height: uint,
    duration-blocks: uint,
    total-cost: uint,
    is-active: bool,
    pool-id: uint
  }
)

(define-map user-active-leases
  { user: principal, lease-id: uint }
  bool
)

(define-public (register-user)
  (let
    (
      (user tx-sender)
      (current-height stacks-block-height)
    )
    (asserts! (is-none (map-get? user-profiles user)) err-already-registered)
    (map-set user-profiles user
      {
        bandwidth-contributed: u0,
        bandwidth-consumed: u0,
        rewards-earned: u0,
        registration-height: current-height,
        is-active: true,
        reputation-score: u100
      }
    )
    (map-set user-referrals user
      {
        referrer: none,
        total-referrals: u0,
        referral-rewards: u0,
        referral-set: false
      }
    )
    (ok true)
  )
)

(define-public (create-bandwidth-pool (pool-name (string-ascii 64)) (reward-per-mb uint))
  (let
    (
      (pool-id (+ (var-get total-pools) u1))
      (current-height stacks-block-height)
    )
    (asserts! (> (len pool-name) u0) err-invalid-amount)
    (asserts! (> reward-per-mb u0) err-invalid-amount)
    (map-set bandwidth-pools pool-id
      {
        pool-name: pool-name,
        total-bandwidth: u0,
        active-contributors: u0,
        reward-per-mb: reward-per-mb,
        created-height: current-height,
        is-active: true
      }
    )
    (var-set total-pools pool-id)
    (ok pool-id)
  )
)

(define-public (contribute-bandwidth (pool-id uint) (bandwidth-amount uint))
  (let
    (
      (user tx-sender)
      (current-height stacks-block-height)
      (user-profile (unwrap! (map-get? user-profiles user) err-user-not-found))
      (pool (unwrap! (map-get? bandwidth-pools pool-id) err-pool-not-found))
      (existing-contribution (map-get? user-pool-contributions { user: user, pool-id: pool-id }))
    )
    (asserts! (>= bandwidth-amount (var-get minimum-contribution)) err-invalid-amount)
    (asserts! (get is-active pool) err-pool-not-found)
    (asserts! (get is-active user-profile) err-user-not-found)
    
    (if (is-none existing-contribution)
      (begin
        (map-set pool-members { pool-id: pool-id, member: user } true)
        (map-set bandwidth-pools pool-id
          (merge pool { active-contributors: (+ (get active-contributors pool) u1) })
        )
      )
      true
    )
    
    (let
      (
        (existing-contrib-data (default-to { bandwidth-shared: u0, rewards-pending: u0, last-contribution-height: u0 } existing-contribution))
        (current-contribution (get bandwidth-shared existing-contrib-data))
        (current-pending (get rewards-pending existing-contrib-data))
        (new-total-bandwidth (+ bandwidth-amount current-contribution))
        (reward-amount (* bandwidth-amount (get reward-per-mb pool)))
      )
      (map-set user-pool-contributions { user: user, pool-id: pool-id }
        {
          bandwidth-shared: new-total-bandwidth,
          rewards-pending: (+ current-pending reward-amount),
          last-contribution-height: current-height
        }
      )
      
      (map-set bandwidth-pools pool-id
        (merge pool { total-bandwidth: (+ (get total-bandwidth pool) bandwidth-amount) })
      )
      
      (map-set user-profiles user
        (merge user-profile
          {
            bandwidth-contributed: (+ (get bandwidth-contributed user-profile) bandwidth-amount),
            reputation-score: (min-uint u1000 (+ (get reputation-score user-profile) (/ bandwidth-amount u10)))
          }
        )
      )
      
      (var-set total-bandwidth-shared (+ (var-get total-bandwidth-shared) bandwidth-amount))
      (try! (ft-mint? bandwidth-token reward-amount user))
      
      (let
        (
          (user-referral-data (unwrap! (map-get? user-referrals user) err-user-not-found))
          (referrer-opt (get referrer user-referral-data))
        )
        (match referrer-opt
          referrer-principal
          (let
            (
              (referrer-data (unwrap! (map-get? user-referrals referrer-principal) err-invalid-referrer))
              (referral-bonus (/ (* reward-amount (var-get referral-bonus-percentage)) u100))
            )
            (if (>= bandwidth-amount (var-get minimum-referral-contribution))
              (begin
                (try! (ft-mint? bandwidth-token referral-bonus referrer-principal))
                (map-set user-referrals referrer-principal
                  (merge referrer-data { referral-rewards: (+ (get referral-rewards referrer-data) referral-bonus) })
                )
                true
              )
              true
            )
          )
          true
        )
      )
      
      (ok reward-amount)
    )
  )
)

(define-public (consume-bandwidth (pool-id uint) (bandwidth-amount uint))
  (let
    (
      (user tx-sender)
      (user-profile (unwrap! (map-get? user-profiles user) err-user-not-found))
      (pool (unwrap! (map-get? bandwidth-pools pool-id) err-pool-not-found))
      (cost (* bandwidth-amount (get reward-per-mb pool)))
    )
    (asserts! (> bandwidth-amount u0) err-invalid-amount)
    (asserts! (get is-active pool) err-pool-not-found)
    (asserts! (<= bandwidth-amount (get total-bandwidth pool)) err-insufficient-bandwidth)
    (asserts! (>= (ft-get-balance bandwidth-token user) cost) err-insufficient-balance)
    
    (try! (ft-burn? bandwidth-token cost user))
    
    (map-set bandwidth-pools pool-id
      (merge pool { total-bandwidth: (- (get total-bandwidth pool) bandwidth-amount) })
    )
    
    (map-set user-profiles user
      (merge user-profile { bandwidth-consumed: (+ (get bandwidth-consumed user-profile) bandwidth-amount) })
    )
    
    (ok bandwidth-amount)
  )
)

(define-public (claim-rewards (pool-id uint))
  (let
    (
      (user tx-sender)
      (user-profile (unwrap! (map-get? user-profiles user) err-user-not-found))
      (contribution (unwrap! (map-get? user-pool-contributions { user: user, pool-id: pool-id }) err-user-not-found))
      (pending-rewards (get rewards-pending contribution))
    )
    (asserts! (> pending-rewards u0) err-invalid-amount)
    
    (map-set user-pool-contributions { user: user, pool-id: pool-id }
      (merge contribution { rewards-pending: u0 })
    )
    
    (map-set user-profiles user
      (merge user-profile { rewards-earned: (+ (get rewards-earned user-profile) pending-rewards) })
    )
    
    (try! (ft-mint? bandwidth-token pending-rewards user))
    (ok pending-rewards)
  )
)

(define-public (update-reward-rate (new-rate uint))
  (begin
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (asserts! (and (>= new-rate u1) (<= new-rate u100)) err-invalid-amount)
    (var-set reward-rate new-rate)
    (ok true)
  )
)

(define-public (set-referrer (referrer-principal principal))
  (let
    (
      (user tx-sender)
      (user-referral-data (unwrap! (map-get? user-referrals user) err-user-not-found))
      (referrer-profile (unwrap! (map-get? user-profiles referrer-principal) err-invalid-referrer))
      (referrer-data (unwrap! (map-get? user-referrals referrer-principal) err-invalid-referrer))
    )
    (asserts! (not (is-eq user referrer-principal)) err-self-referral)
    (asserts! (not (get referral-set user-referral-data)) err-referral-already-set)
    (asserts! (get is-active referrer-profile) err-invalid-referrer)
    
    (map-set user-referrals user
      (merge user-referral-data
        {
          referrer: (some referrer-principal),
          referral-set: true
        }
      )
    )
    
    (map-set user-referrals referrer-principal
      (merge referrer-data
        {
          total-referrals: (+ (get total-referrals referrer-data) u1)
        }
      )
    )
    
    (ok true)
  )
)

(define-public (deactivate-pool (pool-id uint))
  (let
    (
      (pool (unwrap! (map-get? bandwidth-pools pool-id) err-pool-not-found))
    )
    (asserts! (is-eq tx-sender contract-owner) err-owner-only)
    (map-set bandwidth-pools pool-id (merge pool { is-active: false }))
    (ok true)
  )
)

(define-read-only (get-user-profile (user principal))
  (map-get? user-profiles user)
)

(define-read-only (get-pool-info (pool-id uint))
  (map-get? bandwidth-pools pool-id)
)

(define-read-only (get-user-contribution (user principal) (pool-id uint))
  (map-get? user-pool-contributions { user: user, pool-id: pool-id })
)

(define-read-only (get-total-bandwidth-shared)
  (var-get total-bandwidth-shared)
)

(define-read-only (get-total-pools)
  (var-get total-pools)
)

(define-read-only (get-reward-rate)
  (var-get reward-rate)
)

(define-read-only (is-pool-member (pool-id uint) (user principal))
  (default-to false (map-get? pool-members { pool-id: pool-id, member: user }))
)

(define-read-only (get-referral-info (user principal))
  (map-get? user-referrals user)
)

(define-read-only (get-referral-bonus-percentage)
  (var-get referral-bonus-percentage)
)

(define-read-only (calculate-user-efficiency (user principal))
  (match (map-get? user-profiles user)
    user-profile
    (let
      (
        (contributed (get bandwidth-contributed user-profile))
        (consumed (get bandwidth-consumed user-profile))
      )
      (if (is-eq consumed u0)
        u1000
        (if (> contributed consumed)
          (min-uint u1000 (* (/ contributed consumed) u100))
          (/ (* contributed u100) consumed)
        )
      )
    )
    u0
  )
)

(define-public (create-bandwidth-lease (pool-id uint) (bandwidth-amount uint) (rate-per-mb uint) (duration-blocks uint))
  (let
    (
      (user tx-sender)
      (current-height stacks-block-height)
      (lease-id (+ (var-get total-leases) u1))
      (user-profile (unwrap! (map-get? user-profiles user) err-user-not-found))
      (pool (unwrap! (map-get? bandwidth-pools pool-id) err-pool-not-found))
      (contribution (unwrap! (map-get? user-pool-contributions { user: user, pool-id: pool-id }) err-user-not-found))
    )
    (asserts! (> bandwidth-amount u0) err-invalid-amount)
    (asserts! (> rate-per-mb u0) err-invalid-amount)
    (asserts! (>= duration-blocks (var-get minimum-lease-duration)) err-invalid-duration)
    (asserts! (<= duration-blocks (var-get maximum-lease-duration)) err-invalid-duration)
    (asserts! (get is-active pool) err-pool-not-found)
    (asserts! (<= bandwidth-amount (get bandwidth-shared contribution)) err-insufficient-bandwidth)
    
    (let
      (
        (total-cost (* bandwidth-amount rate-per-mb))
      )
      (map-set bandwidth-leases lease-id
        {
          lessor: user,
          lessee: none,
          bandwidth-amount: bandwidth-amount,
          rate-per-mb: rate-per-mb,
          start-height: current-height,
          duration-blocks: duration-blocks,
          total-cost: total-cost,
          is-active: true,
          pool-id: pool-id
        }
      )
      
      (map-set user-active-leases { user: user, lease-id: lease-id } true)
      (var-set total-leases lease-id)
      (ok lease-id)
    )
  )
)

(define-public (accept-bandwidth-lease (lease-id uint))
  (let
    (
      (user tx-sender)
      (current-height stacks-block-height)
      (lease (unwrap! (map-get? bandwidth-leases lease-id) err-lease-not-found))
      (user-profile (unwrap! (map-get? user-profiles user) err-user-not-found))
    )
    (asserts! (get is-active lease) err-lease-not-found)
    (asserts! (is-none (get lessee lease)) err-lease-active)
    (asserts! (not (is-eq user (get lessor lease))) err-self-referral)
    (asserts! (<= (+ (get start-height lease) (get duration-blocks lease)) (+ current-height (get duration-blocks lease))) err-lease-expired)
    (asserts! (>= (ft-get-balance bandwidth-token user) (get total-cost lease)) err-insufficient-balance)
    
    (try! (ft-transfer? bandwidth-token (get total-cost lease) user (get lessor lease)))
    
    (map-set bandwidth-leases lease-id
      (merge lease { lessee: (some user) })
    )
    
    (map-set user-active-leases { user: user, lease-id: lease-id } true)
    (ok true)
  )
)

(define-public (terminate-lease (lease-id uint))
  (let
    (
      (user tx-sender)
      (current-height stacks-block-height)
      (lease (unwrap! (map-get? bandwidth-leases lease-id) err-lease-not-found))
    )
    (asserts! (get is-active lease) err-lease-not-found)
    (asserts! (or (is-eq user (get lessor lease)) (> current-height (+ (get start-height lease) (get duration-blocks lease)))) err-owner-only)
    
    (map-set bandwidth-leases lease-id
      (merge lease { is-active: false })
    )
    
    (ok true)
  )
)

(define-public (withdraw-expired-bandwidth (lease-id uint))
  (let
    (
      (user tx-sender)
      (current-height stacks-block-height)
      (lease (unwrap! (map-get? bandwidth-leases lease-id) err-lease-not-found))
    )
    (asserts! (is-eq user (get lessor lease)) err-owner-only)
    (asserts! (not (get is-active lease)) err-lease-active)
    (asserts! (> current-height (+ (get start-height lease) (get duration-blocks lease))) err-lease-active)
    
    (ok (get bandwidth-amount lease))
  )
)

(define-read-only (get-lease-info (lease-id uint))
  (map-get? bandwidth-leases lease-id)
)

(define-read-only (is-lease-active (lease-id uint))
  (match (map-get? bandwidth-leases lease-id)
    lease
    (let
      (
        (current-height stacks-block-height)
        (expiry-height (+ (get start-height lease) (get duration-blocks lease)))
      )
      (and (get is-active lease) (<= current-height expiry-height))
    )
    false
  )
)

(define-read-only (get-user-lease-status (user principal) (lease-id uint))
  (default-to false (map-get? user-active-leases { user: user, lease-id: lease-id }))
)

(define-read-only (get-total-leases)
  (var-get total-leases)
)

(define-read-only (calculate-lease-value (lease-id uint))
  (match (map-get? bandwidth-leases lease-id)
    lease
    (let
      (
        (current-height stacks-block-height)
        (expiry-height (+ (get start-height lease) (get duration-blocks lease)))
        (blocks-remaining (if (> expiry-height current-height) (- expiry-height current-height) u0))
      )
      (* (get bandwidth-amount lease) blocks-remaining)
    )
    u0
  )
)

