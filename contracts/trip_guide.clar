;; PathNest Trip Guide Contract

;; Constants 
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-already-exists (err u102))
(define-constant err-unauthorized (err u103))
(define-constant err-invalid-rating (err u104))
(define-constant err-already-following (err u105))
(define-constant err-not-following (err u106))

;; Rating constants
(define-constant min-rating u0)
(define-constant max-rating u5)

;; Reputation points
(define-constant guide-creation-points u10)
(define-constant guide-favorite-points u2)

;; Define NFT for verified locations
(define-non-fungible-token location uint)

;; Define SFT for curator reputation
(define-fungible-token curator-rep)

[Previous data variables remain unchanged...]

;; Add new location with photos and input validation
(define-public (add-location (name (string-ascii 100)) 
                         (lat int)
                         (long int)
                         (category (string-ascii 20))
                         (description (string-ascii 500))
                         (photos (list 5 (string-ascii 200))))
    (let ((location-id (var-get next-location-id)))
        (asserts! (> (len name) u0) err-unauthorized)
        (asserts! (> (len category) u0) err-unauthorized)
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

;; Rate location with validation
(define-public (rate-location (location-id uint) (rating uint))
    (let ((location (unwrap! (map-get? locations location-id) err-not-found)))
        (asserts! (and (>= rating min-rating) (<= rating max-rating)) err-invalid-rating)
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

;; Follow curator with duplicate check
(define-public (follow-curator (curator-to-follow principal))
    (let ((curator-data (unwrap! (map-get? curators curator-to-follow) err-not-found))
          (follower-data (default-to 
              {reputation: u0, guides-created: u0, followers: (list), following: (list)}
              (map-get? curators tx-sender))))
        
        (asserts! (not (is-eq curator-to-follow tx-sender)) err-unauthorized)
        (asserts! (is-none (index-of (get followers curator-data) tx-sender)) err-already-following)
        
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

;; Unfollow curator
(define-public (unfollow-curator (curator-to-unfollow principal))
    (let ((curator-data (unwrap! (map-get? curators curator-to-unfollow) err-not-found))
          (follower-data (unwrap! (map-get? curators tx-sender) err-not-found)))
        
        (asserts! (is-some (index-of (get following follower-data) curator-to-unfollow)) err-not-following)
        
        ;; Update curator's followers
        (map-set curators
            curator-to-unfollow
            (merge curator-data {
                followers: (filter not-tx-sender (get followers curator-data))
            })
        )
        
        ;; Update follower's following list
        (map-set curators
            tx-sender
            (merge follower-data {
                following: (filter (compose not (partial is-eq curator-to-unfollow)) 
                                (get following follower-data))
            })
        )
        (ok true)
    )
)

;; Helper function for filtering
(define-private (not-tx-sender (user principal))
    (not (is-eq user tx-sender))
)

[Previous functions remain unchanged...]
