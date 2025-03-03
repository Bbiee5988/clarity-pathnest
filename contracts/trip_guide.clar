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
(define-constant err-invalid-coordinates (err u107))
(define-constant err-invalid-photos (err u108))

;; Coordinate validation constants
(define-constant min-latitude (- 90))
(define-constant max-latitude 90)
(define-constant min-longitude (- 180))
(define-constant max-longitude 180)

;; Rating constants
(define-constant min-rating u0)
(define-constant max-rating u5)

;; Reputation points
(define-constant guide-creation-points u10)
(define-constant guide-favorite-points u2)
(define-constant reputation-decay-rate u1)

;; Define NFT for verified locations
(define-non-fungible-token location uint)

;; Define SFT for curator reputation
(define-fungible-token curator-rep)

;; Events
(define-data-var last-event-id uint u0)

;; Add new location with enhanced validation
(define-public (add-location (name (string-ascii 100)) 
                         (lat int)
                         (long int)
                         (category (string-ascii 20))
                         (description (string-ascii 500))
                         (photos (list 5 (string-ascii 200))))
    (let ((location-id (var-get next-location-id)))
        ;; Input validation
        (asserts! (> (len name) u0) err-unauthorized)
        (asserts! (> (len category) u0) err-unauthorized)
        (asserts! (and 
            (>= lat min-latitude) 
            (<= lat max-latitude)
            (>= long min-longitude)
            (<= long max-longitude)) 
            err-invalid-coordinates)
        
        ;; Validate photos
        (asserts! (map check-photo-url photos) err-invalid-photos)
        
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
                photos: photos,
                last-rated: u0
            }
        )
        (var-set next-location-id (+ location-id u1))
        (emit-location-added location-id name)
        (ok location-id)
    )
)

;; Rate location with rate limiting
(define-public (rate-location (location-id uint) (rating uint))
    (let ((location (unwrap! (map-get? locations location-id) err-not-found))
          (current-block-height block-height))
        (asserts! (and (>= rating min-rating) (<= rating max-rating)) err-invalid-rating)
        (asserts! (> (- current-block-height (get last-rated location)) u100) err-unauthorized)
        
        (map-set locations
            location-id
            (merge location {
                rating: (/ (+ (* (get votes location) (get rating location)) rating)
                          (+ (get votes location) u1)),
                votes: (+ (get votes location) u1),
                last-rated: current-block-height
            })
        )
        (emit-location-rated location-id rating)
        (ok true)
    )
)

;; Helper function to validate photo URLs
(define-private (check-photo-url (url (string-ascii 200)))
    (> (len url) u0)
)

;; Event emission helpers
(define-private (emit-location-added (location-id uint) (name (string-ascii 100)))
    (let ((event-id (var-get last-event-id)))
        (print {event: "location-added", location-id: location-id, name: name})
        (var-set last-event-id (+ event-id u1))
        true
    )
)

(define-private (emit-location-rated (location-id uint) (rating uint))
    (let ((event-id (var-get last-event-id)))
        (print {event: "location-rated", location-id: location-id, rating: rating})
        (var-set last-event-id (+ event-id u1))
        true
    )
)

[Previous functions remain unchanged...]
