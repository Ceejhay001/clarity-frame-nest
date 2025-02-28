;; FrameNest Contract
;; Storage and management of photo collections

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))
(define-constant err-invalid-input (err u103))
(define-constant err-already-exists (err u104))

;; Data Maps
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
    (if (< (len url) u5) 
        false
        true
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
    (ok new-id))
)

(define-public (transfer-collection (collection-id uint) (new-owner principal))
    (let (
        (collection (unwrap! (map-get? collections {collection-id: collection-id}) err-not-found))
    )
    (if (is-eq (get owner collection) tx-sender)
        (begin
            (map-set collections
                {collection-id: collection-id}
                (merge collection {owner: new-owner, last-modified: block-height})
            )
            (ok true)
        )
        err-unauthorized
    ))
)

(define-public (delete-collection (collection-id uint))
    (let (
        (collection (unwrap! (map-get? collections {collection-id: collection-id}) err-not-found))
    )
    (if (is-eq (get owner collection) tx-sender)
        (begin
            (map-delete collections {collection-id: collection-id})
            (ok true)
        )
        err-unauthorized
    ))
)

(define-public (add-photo 
    (collection-id uint) 
    (url (string-utf8 256)) 
    (metadata (string-utf8 1024)))
    (let (
        (new-id (+ (var-get last-photo-id) u1))
        (collection (unwrap! (map-get? collections {collection-id: collection-id}) err-not-found))
    )
    (if (and (is-authorized collection-id tx-sender) (is-valid-url url))
        (begin
            (map-set photos
                {photo-id: new-id, collection-id: collection-id}
                {
                    url: url,
                    metadata: metadata,
                    uploaded-by: tx-sender,
                    upload-time: block-height
                }
            )
            (map-set collections
                {collection-id: collection-id}
                (merge collection 
                    {
                        photo-count: (+ (get photo-count collection) u1),
                        last-modified: block-height
                    }
                )
            )
            (var-set last-photo-id new-id)
            (ok new-id)
        )
        err-unauthorized
    ))
)

;; Read-only Functions
(define-read-only (get-collection-stats (collection-id uint))
    (ok (map-get? collections {collection-id: collection-id}))
)

[Previous functions remain unchanged...]
