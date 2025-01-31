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
        votes: uint,
        reviews: (list 10 {reviewer: principal, comment: (string-ascii 200)}),
        photos: (list 5 (string-ascii 200))
    }
)

(define-map guides
    uint
    {
        title: (string-ascii 100),
        curator: principal,
        stops: (list 20 uint),
        rating: uint,
        votes: uint,
        favorited-by: (list 100 principal),
        comments: (list 20 {commenter: principal, text: (string-ascii 200)})
    }
)

(define-map curators
    principal
    {
        reputation: uint,
        guides-created: uint,
        followers: (list 100 principal),
        following: (list 100 principal)
    }
)

;; Data variables for IDs
(define-data-var next-location-id uint u1)
(define-data-var next-guide-id uint u1)

;; Add new location with photos
(define-public (add-location (name (string-ascii 100)) 
                         (lat int)
                         (long int)
                         (category (string-ascii 20))
                         (description (string-ascii 500))
                         (photos (list 5 (string-ascii 200))))
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
                votes: u0,
                reviews: (list),
                photos: photos
            }
        )
        (var-set next-location-id (+ location-id u1))
        (ok location-id)
    )
)

;; Add review to location
(define-public (add-location-review (location-id uint) (comment (string-ascii 200)))
    (let ((location (unwrap! (map-get? locations location-id) err-not-found)))
        (map-set locations
            location-id
            (merge location {
                reviews: (unwrap! (as-max-len? 
                    (append (get reviews location) 
                            {reviewer: tx-sender, comment: comment})
                    u10)
                    err-unauthorized)
            })
        )
        (ok true)
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
                votes: u0,
                favorited-by: (list),
                comments: (list)
            }
        )
        (try! (add-curator-guide tx-sender))
        (var-set next-guide-id (+ guide-id u1))
        (ok guide-id)
    )
)

;; Follow a curator
(define-public (follow-curator (curator-to-follow principal))
    (let ((curator-data (unwrap! (map-get? curators curator-to-follow) err-not-found))
          (follower-data (default-to 
              {reputation: u0, guides-created: u0, followers: (list), following: (list)}
              (map-get? curators tx-sender))))
        
        ;; Update curator's followers
        (map-set curators
            curator-to-follow
            (merge curator-data {
                followers: (unwrap! (as-max-len?
                    (append (get followers curator-data) tx-sender)
                    u100)
                    err-unauthorized)
            })
        )
        
        ;; Update follower's following list
        (map-set curators
            tx-sender
            (merge follower-data {
                following: (unwrap! (as-max-len?
                    (append (get following follower-data) curator-to-follow)
                    u100)
                    err-unauthorized)
            })
        )
        (ok true)
    )
)

;; Favorite a guide
(define-public (favorite-guide (guide-id uint))
    (let ((guide (unwrap! (map-get? guides guide-id) err-not-found)))
        (map-set guides
            guide-id
            (merge guide {
                favorited-by: (unwrap! (as-max-len?
                    (append (get favorited-by guide) tx-sender)
                    u100)
                    err-unauthorized)
            })
        )
        (ok true)
    )
)

;; Comment on guide
(define-public (comment-on-guide (guide-id uint) (comment (string-ascii 200)))
    (let ((guide (unwrap! (map-get? guides guide-id) err-not-found)))
        (map-set guides
            guide-id
            (merge guide {
                comments: (unwrap! (as-max-len?
                    (append (get comments guide) 
                            {commenter: tx-sender, text: comment})
                    u20)
                    err-unauthorized)
            })
        )
        (ok true)
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
    (let ((curator-data (default-to { reputation: u0, guides-created: u0, followers: (list), following: (list) }
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
