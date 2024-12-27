;; FrameNest Contract
;; Storage and management of photo collections

;; Constants
(define-constant contract-owner tx-sender)
(define-constant err-owner-only (err u100))
(define-constant err-not-found (err u101))
(define-constant err-unauthorized (err u102))

;; Data Maps
(define-map collections 
    { collection-id: uint } 
    {
        owner: principal,
        name: (string-ascii 64),
        description: (string-ascii 256),
        created-at: uint
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
            created-at: block-height
        }
    )
    (var-set last-collection-id new-id)
    (ok new-id))
)

(define-public (add-photo 
    (collection-id uint) 
    (url (string-utf8 256)) 
    (metadata (string-utf8 1024)))
    (let (
        (new-id (+ (var-get last-photo-id) u1))
    )
    (if (is-authorized collection-id tx-sender)
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
            (var-set last-photo-id new-id)
            (ok new-id)
        )
        err-unauthorized
    ))
)

(define-public (set-permissions 
    (collection-id uint) 
    (user principal) 
    (can-view bool) 
    (can-edit bool))
    (let (
        (collection (unwrap! (map-get? collections {collection-id: collection-id}) err-not-found))
    )
    (if (is-eq (get owner collection) tx-sender)
        (begin
            (map-set collection-permissions
                {collection-id: collection-id, user: user}
                {can-view: can-view, can-edit: can-edit}
            )
            (ok true)
        )
        err-unauthorized
    ))
)

;; Read-only Functions
(define-read-only (get-collection (collection-id uint))
    (ok (map-get? collections {collection-id: collection-id}))
)

(define-read-only (get-photo (photo-id uint) (collection-id uint))
    (ok (map-get? photos {photo-id: photo-id, collection-id: collection-id}))
)

(define-read-only (get-permissions (collection-id uint) (user principal))
    (ok (map-get? collection-permissions {collection-id: collection-id, user: user}))
)