;; FrameNest Contract
;; Storage and management of photo collections

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-exists (err u104))

;; Events
(define-data-var last-event-id uint u0)

(define-map collections 
    { collection-id: uint } 
    {
        owner: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        created-at: uint,
        photo-count: uint,
        last-modified: uint
    }
)

(define-map photos
    { photo-id: uint, collection-id: uint }
    {
        url: (string-utf8 256),
        metadata: (string-utf8 1024),
        uploaded-by: principal,
        upload-time: uint
    }
)

(define-map collection-permissions
    { collection-id: uint, user: principal }
    {
        can-view: bool,
        can-edit: bool
    }
)

;; Data Variables
(define-data-var last-collection-id uint u0)
(define-data-var last-photo-id uint u0)

;; Private Functions
(define-private (is-valid-url (url (string-utf8 256)))
    (let (
        (url-length (len url))
        (has-protocol (match (slice? url u0 u4) "http" true false))
    )
    (and 
        (>= url-length u10)
        has-protocol
    ))
)

(define-private (emit-event (event-type (string-ascii 24)) (data (string-utf8 256)))
    (let ((event-id (+ (var-get last-event-id) u1)))
        (var-set last-event-id event-id)
        (print { event-id: event-id, type: event-type, data: data })
    )
)

(define-private (is-authorized (collection-id uint) (user principal))
    (let (
        (collection (unwrap! (map-get? collections {collection-id: collection-id}) false))
        (permissions (map-get? collection-permissions {collection-id: collection-id, user: user}))
    )
    (or
        (is-eq (get owner collection) user)
        (and
            (is-some permissions)
            (get can-edit (unwrap! permissions false))
        )
    ))
)

;; Public Functions
(define-public (create-collection (name (string-ascii 64)) (description (string-ascii 256)))
    (let (
        (new-id (+ (var-get last-collection-id) u1))
    )
    (map-set collections
        {collection-id: new-id}
        {
            owner: tx-sender,
            name: name,
            description: description,
            created-at: block-height,
            photo-count: u0,
            last-modified: block-height
        }
    )
    (var-set last-collection-id new-id)
    (emit-event "collection_created" (concat (to-utf8 name) (uint-to-utf8 new-id)))
    (ok new-id))
)

;; Batch photo retrieval
(define-read-only (get-collection-photos (collection-id uint) (start-id uint) (limit uint))
    (let (
        (collection (unwrap! (map-get? collections {collection-id: collection-id}) err-not-found))
        (end-id (+ start-id limit))
    )
    (ok (filter not-none 
        (map unwrap-panic
            (map 
                (lambda (id) (map-get? photos {photo-id: id, collection-id: collection-id}))
                (list start-id end-id)
            )
        )
    )))
)

[Previous functions remain unchanged...]
