;; Athlete Wellness Tracking Smart Contract
;; This contract manages athlete wellness data, metrics, and access permissions

;; Error constants
(define-constant ERR-NOT-AUTHORIZED (err u100))
(define-constant ERR-ATHLETE-NOT-FOUND (err u101))
(define-constant ERR-INVALID-METRIC (err u102))
(define-constant ERR-ALREADY-EXISTS (err u103))
(define-constant ERR-INVALID-VALUE (err u104))
(define-constant ERR-NOT-COACH (err u105))
(define-constant ERR-PERMISSION-DENIED (err u106))

;; Contract owner
(define-constant CONTRACT-OWNER tx-sender)

;; Data structures
(define-map athletes 
    { athlete-id: principal }
    {
        name: (string-ascii 50),
        sport: (string-ascii 30),
        team: (string-ascii 50),
        coach: principal,
        is-active: bool,
        created-at: uint
    }
)

(define-map wellness-metrics
    { athlete-id: principal, date: uint }
    {
        heart-rate-resting: uint,
        sleep-hours: uint,
        stress-level: uint, ;; 1-10 scale
        energy-level: uint, ;; 1-10 scale
        hydration-level: uint, ;; 1-10 scale
        muscle-soreness: uint, ;; 1-10 scale
        weight: uint, ;; in kg * 100 (to handle decimals)
        notes: (string-ascii 200),
        recorded-by: principal,
        timestamp: uint
    }
)

(define-map training-sessions
    { athlete-id: principal, session-id: uint }
    {
        date: uint,
        duration: uint, ;; in minutes
        intensity: uint, ;; 1-10 scale
        session-type: (string-ascii 50),
        calories-burned: uint,
        notes: (string-ascii 200),
        recorded-by: principal
    }
)

(define-map coaches
    { coach-id: principal }
    {
        name: (string-ascii 50),
        certification: (string-ascii 100),
        specialization: (string-ascii 50),
        is-active: bool
    }
)

(define-map athlete-permissions
    { athlete-id: principal, accessor: principal }
    { can-read: bool, can-write: bool }
)

;; Data variables
(define-data-var next-session-id uint u1)

;; Public functions

;; Register a new athlete
(define-public (register-athlete (athlete-id principal) (name (string-ascii 50)) (sport (string-ascii 30)) (team (string-ascii 50)) (coach principal))
    (begin
        (asserts! (is-eq tx-sender athlete-id) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? athletes { athlete-id: athlete-id })) ERR-ALREADY-EXISTS)
        (asserts! (> (len name) u0) ERR-INVALID-VALUE)
        (asserts! (> (len sport) u0) ERR-INVALID-VALUE)
        
        (map-set athletes 
            { athlete-id: athlete-id }
            {
                name: name,
                sport: sport,
                team: team,
                coach: coach,
                is-active: true,
                created-at: stacks-block-height
            }
        )
        (ok true)
    )
)

;; Register a new coach
(define-public (register-coach (coach-id principal) (name (string-ascii 50)) (certification (string-ascii 100)) (specialization (string-ascii 50)))
    (begin
        (asserts! (is-eq tx-sender coach-id) ERR-NOT-AUTHORIZED)
        (asserts! (is-none (map-get? coaches { coach-id: coach-id })) ERR-ALREADY-EXISTS)
        (asserts! (> (len name) u0) ERR-INVALID-VALUE)
        
        (map-set coaches
            { coach-id: coach-id }
            {
                name: name,
                certification: certification,
                specialization: specialization,
                is-active: true
            }
        )
        (ok true)
    )
)

;; Record daily wellness metrics
(define-public (record-wellness-metrics 
    (athlete-id principal) 
    (date uint) 
    (heart-rate-resting uint) 
    (sleep-hours uint) 
    (stress-level uint) 
    (energy-level uint) 
    (hydration-level uint) 
    (muscle-soreness uint) 
    (weight uint) 
    (notes (string-ascii 200)))
    (let ((athlete-data (unwrap! (map-get? athletes { athlete-id: athlete-id }) ERR-ATHLETE-NOT-FOUND)))
        (begin
            (asserts! (or (is-eq tx-sender athlete-id) 
                         (is-eq tx-sender (get coach athlete-data))
                         (default-to false (get can-write (map-get? athlete-permissions { athlete-id: athlete-id, accessor: tx-sender })))) 
                     ERR-NOT-AUTHORIZED)
            (asserts! (<= stress-level u10) ERR-INVALID-METRIC)
            (asserts! (<= energy-level u10) ERR-INVALID-METRIC)
            (asserts! (<= hydration-level u10) ERR-INVALID-METRIC)
            (asserts! (<= muscle-soreness u10) ERR-INVALID-METRIC)
            (asserts! (> stress-level u0) ERR-INVALID-METRIC)
            (asserts! (> energy-level u0) ERR-INVALID-METRIC)
            (asserts! (> hydration-level u0) ERR-INVALID-METRIC)
            (asserts! (> muscle-soreness u0) ERR-INVALID-METRIC)
            (asserts! (> heart-rate-resting u30) ERR-INVALID-METRIC) ;; Minimum reasonable resting heart rate
            (asserts! (< heart-rate-resting u200) ERR-INVALID-METRIC) ;; Maximum reasonable resting heart rate
            (asserts! (<= sleep-hours u24) ERR-INVALID-METRIC)
            
            (map-set wellness-metrics
                { athlete-id: athlete-id, date: date }
                {
                    heart-rate-resting: heart-rate-resting,
                    sleep-hours: sleep-hours,
                    stress-level: stress-level,
                    energy-level: energy-level,
                    hydration-level: hydration-level,
                    muscle-soreness: muscle-soreness,
                    weight: weight,
                    notes: notes,
                    recorded-by: tx-sender,
                    timestamp: stacks-block-height
                }
            )
            (ok true)
        )
    )
)

;; Record training session
(define-public (record-training-session 
    (athlete-id principal) 
    (date uint) 
    (duration uint) 
    (intensity uint) 
    (session-type (string-ascii 50)) 
    (calories-burned uint) 
    (notes (string-ascii 200)))
    (let ((athlete-data (unwrap! (map-get? athletes { athlete-id: athlete-id }) ERR-ATHLETE-NOT-FOUND))
          (session-id (var-get next-session-id)))
        (begin
            (asserts! (or (is-eq tx-sender athlete-id) 
                         (is-eq tx-sender (get coach athlete-data))
                         (default-to false (get can-write (map-get? athlete-permissions { athlete-id: athlete-id, accessor: tx-sender })))) 
                     ERR-NOT-AUTHORIZED)
            (asserts! (<= intensity u10) ERR-INVALID-METRIC)
            (asserts! (> intensity u0) ERR-INVALID-METRIC)
            (asserts! (> duration u0) ERR-INVALID-VALUE)
            (asserts! (> (len session-type) u0) ERR-INVALID-VALUE)
            
            (map-set training-sessions
                { athlete-id: athlete-id, session-id: session-id }
                {
                    date: date,
                    duration: duration,
                    intensity: intensity,
                    session-type: session-type,
                    calories-burned: calories-burned,
                    notes: notes,
                    recorded-by: tx-sender
                }
            )
            (var-set next-session-id (+ session-id u1))
            (ok session-id)
        )
    )
)

;; Grant permissions to access athlete data
(define-public (grant-permission (athlete-id principal) (accessor principal) (can-read bool) (can-write bool))
    (begin
        (asserts! (is-eq tx-sender athlete-id) ERR-NOT-AUTHORIZED)
        (asserts! (is-some (map-get? athletes { athlete-id: athlete-id })) ERR-ATHLETE-NOT-FOUND)
        
        (map-set athlete-permissions
            { athlete-id: athlete-id, accessor: accessor }
            { can-read: can-read, can-write: can-write }
        )
        (ok true)
    )
)

;; Revoke permissions
(define-public (revoke-permission (athlete-id principal) (accessor principal))
    (begin
        (asserts! (is-eq tx-sender athlete-id) ERR-NOT-AUTHORIZED)
        (map-delete athlete-permissions { athlete-id: athlete-id, accessor: accessor })
        (ok true)
    )
)

;; Update athlete status
(define-public (update-athlete-status (athlete-id principal) (is-active bool))
    (let ((athlete-data (unwrap! (map-get? athletes { athlete-id: athlete-id }) ERR-ATHLETE-NOT-FOUND)))
        (begin
            (asserts! (or (is-eq tx-sender athlete-id) (is-eq tx-sender CONTRACT-OWNER)) ERR-NOT-AUTHORIZED)
            (map-set athletes
                { athlete-id: athlete-id }
                (merge athlete-data { is-active: is-active })
            )
            (ok true)
        )
    )
)

;; Read-only functions

;; Get athlete information
(define-read-only (get-athlete (athlete-id principal))
    (map-get? athletes { athlete-id: athlete-id })
)

;; Get coach information
(define-read-only (get-coach (coach-id principal))
    (map-get? coaches { coach-id: coach-id })
)

;; Get wellness metrics for a specific date
(define-read-only (get-wellness-metrics (athlete-id principal) (date uint))
    (let ((athlete-data (map-get? athletes { athlete-id: athlete-id }))
          (permissions (map-get? athlete-permissions { athlete-id: athlete-id, accessor: tx-sender })))
        (if (or (is-eq tx-sender athlete-id)
                (is-eq tx-sender CONTRACT-OWNER)
                (and (is-some athlete-data) (is-eq tx-sender (get coach (unwrap-panic athlete-data))))
                (default-to false (get can-read permissions)))
            (map-get? wellness-metrics { athlete-id: athlete-id, date: date })
            none
        )
    )
)

;; Get training session
(define-read-only (get-training-session (athlete-id principal) (session-id uint))
    (let ((athlete-data (map-get? athletes { athlete-id: athlete-id }))
          (permissions (map-get? athlete-permissions { athlete-id: athlete-id, accessor: tx-sender })))
        (if (or (is-eq tx-sender athlete-id)
                (is-eq tx-sender CONTRACT-OWNER)
                (and (is-some athlete-data) (is-eq tx-sender (get coach (unwrap-panic athlete-data))))
                (default-to false (get can-read permissions)))
            (map-get? training-sessions { athlete-id: athlete-id, session-id: session-id })
            none
        )
    )
)

;; Check permissions
(define-read-only (get-permissions (athlete-id principal) (accessor principal))
    (if (is-eq tx-sender athlete-id)
        (map-get? athlete-permissions { athlete-id: athlete-id, accessor: accessor })
        none
    )
)

;; Check if caller can access athlete data
(define-read-only (can-access-athlete-data (athlete-id principal))
    (let ((athlete-data (map-get? athletes { athlete-id: athlete-id }))
          (permissions (map-get? athlete-permissions { athlete-id: athlete-id, accessor: tx-sender })))
        (or (is-eq tx-sender athlete-id)
            (is-eq tx-sender CONTRACT-OWNER)
            (and (is-some athlete-data) (is-eq tx-sender (get coach (unwrap-panic athlete-data))))
            (default-to false (get can-read permissions))
        )
    )
)

;; Get current session ID counter
(define-read-only (get-next-session-id)
    (var-get next-session-id)
)

;; Helper function to calculate wellness score (1-100)
(define-read-only (calculate-wellness-score (stress-level uint) (energy-level uint) (hydration-level uint) (muscle-soreness uint) (sleep-hours uint))
    (let ((stress-score (- u11 stress-level)) ;; Invert stress (lower is better)
          (energy-score energy-level)
          (hydration-score hydration-level)
          (soreness-score (- u11 muscle-soreness)) ;; Invert soreness (lower is better)
          (sleep-score (if (<= sleep-hours u6) u5 (if (<= sleep-hours u9) u10 u8)))) ;; 7-9 hours optimal
        (/ (* (+ stress-score energy-score hydration-score soreness-score sleep-score) u100) u50)
    )
)