;; PathNest Trip Guide Contract

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))

;; Define NFT for verified locations
(define-non-fungible-token location uint)

;; Define SFT for curator reputation
(define-fungible-token curator-rep)

;; Data Variables
(define-map locations 
    uint 
    {
        name: (string-ascii 100),
        lat: int,
        long: int,
        category: (string-ascii 20),
        description: (string-ascii 500),
        verified: bool,
        rating: uint,
        votes: uint
    }
)

(define-map guides
    uint
    {
        title: (string-ascii 100),
        curator: principal,
        stops: (list 20 uint),
        rating: uint,
        votes: uint
    }
)

(define-map curators
    principal
    {
        reputation: uint,
        guides-created: uint
    }
)

;; Data variables for IDs
(define-data-var next-location-id uint u1)
(define-data-var next-guide-id uint u1)

;; Add new location
(define-public (add-location (name (string-ascii 100)) 
                           (lat int)
                           (long int)
                           (category (string-ascii 20))
                           (description (string-ascii 500)))
    (let ((location-id (var-get next-location-id)))
        (map-insert locations 
            location-id
            {
                name: name,
                lat: lat,
                long: long,
                category: category,
                description: description,
                verified: false,
                rating: u0,
                votes: u0
            }
        )
        (var-set next-location-id (+ location-id u1))
        (ok location-id)
    )
)

;; Create new guide
(define-public (create-guide (title (string-ascii 100)) (stops (list 20 uint)))
    (let ((guide-id (var-get next-guide-id)))
        (map-insert guides
            guide-id
            {
                title: title,
                curator: tx-sender,
                stops: stops,
                rating: u0,
                votes: u0
            }
        )
        (try! (add-curator-guide tx-sender))
        (var-set next-guide-id (+ guide-id u1))
        (ok guide-id)
    )
)

;; Rate location
(define-public (rate-location (location-id uint) (rating uint))
    (let ((location (unwrap! (map-get? locations location-id) err-not-found)))
        (map-set locations
            location-id
            (merge location {
                rating: (/ (+ (* (get votes location) (get rating location)) rating)
                          (+ (get votes location) u1)),
                votes: (+ (get votes location) u1)
            })
        )
        (ok true)
    )
)

;; Verify location (owner only)
(define-public (verify-location (location-id uint))
    (if (is-eq tx-sender contract-owner)
        (let ((location (unwrap! (map-get? locations location-id) err-not-found)))
            (try! (nft-mint? location location-id tx-sender))
            (map-set locations
                location-id
                (merge location { verified: true })
            )
            (ok true)
        )
        err-owner-only
    )
)

;; Helper function to track curator guides
(define-private (add-curator-guide (curator principal))
    (let ((curator-data (default-to { reputation: u0, guides-created: u0 }
                                  (map-get? curators curator))))
        (map-set curators
            curator
            (merge curator-data {
                guides-created: (+ (get guides-created curator-data) u1)
            })
        )
        (ok true)
    )
)

;; Read-only functions
(define-read-only (get-location (location-id uint))
    (map-get? locations location-id)
)

(define-read-only (get-guide (guide-id uint))
    (map-get? guides guide-id)
)

(define-read-only (get-curator-info (curator principal))
    (map-get? curators curator)
)