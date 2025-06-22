;; Security Administrator Verification Contract
;; Manages and validates security administrators

(define-constant CONTRACT_OWNER tx-sender)
(define-constant ERR_UNAUTHORIZED (err u100))
(define-constant ERR_ADMIN_EXISTS (err u101))
(define-constant ERR_ADMIN_NOT_FOUND (err u102))

;; Data maps
(define-map security-admins principal bool)
(define-map admin-metadata principal {
    added-at: uint,
    added-by: principal,
    status: (string-ascii 20)
})

;; Initialize contract owner as first admin
(map-set security-admins CONTRACT_OWNER true)
(map-set admin-metadata CONTRACT_OWNER {
    added-at: block-height,
    added-by: CONTRACT_OWNER,
    status: "active"
})

;; Read-only functions
(define-read-only (is-security-admin (admin principal))
    (default-to false (map-get? security-admins admin))
)

(define-read-only (get-admin-info (admin principal))
    (map-get? admin-metadata admin)
)

(define-read-only (get-total-admins)
    (var-get admin-count)
)

;; Data variables
(define-data-var admin-count uint u1)

;; Public functions
(define-public (add-security-admin (new-admin principal))
    (begin
        (asserts! (is-security-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (not (is-security-admin new-admin)) ERR_ADMIN_EXISTS)

        (map-set security-admins new-admin true)
        (map-set admin-metadata new-admin {
            added-at: block-height,
            added-by: tx-sender,
            status: "active"
        })
        (var-set admin-count (+ (var-get admin-count) u1))
        (ok true)
    )
)

(define-public (remove-security-admin (admin principal))
    (begin
        (asserts! (is-security-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-security-admin admin) ERR_ADMIN_NOT_FOUND)
        (asserts! (not (is-eq admin CONTRACT_OWNER)) ERR_UNAUTHORIZED)

        (map-delete security-admins admin)
        (map-delete admin-metadata admin)
        (var-set admin-count (- (var-get admin-count) u1))
        (ok true)
    )
)

(define-public (update-admin-status (admin principal) (new-status (string-ascii 20)))
    (begin
        (asserts! (is-security-admin tx-sender) ERR_UNAUTHORIZED)
        (asserts! (is-security-admin admin) ERR_ADMIN_NOT_FOUND)

        (match (map-get? admin-metadata admin)
            admin-data (begin
                (map-set admin-metadata admin (merge admin-data { status: new-status }))
                (ok true)
            )
            ERR_ADMIN_NOT_FOUND
        )
    )
)
