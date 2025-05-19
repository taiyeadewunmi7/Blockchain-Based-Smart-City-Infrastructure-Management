;; Performance Analytics Contract
;; Tracks efficiency and service levels

;; Define data variables
(define-data-var last-metric-id uint u0)

;; Define data maps
(define-map performance-metrics
  { metric-id: uint }
  {
    asset-id: uint,
    metric-type: (string-utf8 50),
    timestamp: uint,
    value: int,
    unit: (string-utf8 20)
  }
)

(define-map service-level-agreements
  { asset-id: uint, metric-type: (string-utf8 50) }
  {
    target-value: int,
    min-acceptable: int,
    max-acceptable: int
  }
)

(define-map performance-summaries
  { asset-id: uint, period-start: uint, period-end: uint }
  {
    uptime-percentage: uint,
    maintenance-count: uint,
    average-response-time: uint,
    compliance-score: uint
  }
)

;; Public functions

;; Record a performance metric
(define-public (record-metric (asset-id uint)
                             (metric-type (string-utf8 50))
                             (timestamp uint)
                             (value int)
                             (unit (string-utf8 20)))
  (let ((new-metric-id (+ (var-get last-metric-id) u1)))
    (begin
      (asserts! (is-eq tx-sender contract-caller) (err u403))
      (var-set last-metric-id new-metric-id)
      (map-set performance-metrics
        { metric-id: new-metric-id }
        {
          asset-id: asset-id,
          metric-type: metric-type,
          timestamp: timestamp,
          value: value,
          unit: unit
        }
      )
      (ok new-metric-id)
    )
  )
)

;; Set service level agreement
(define-public (set-sla (asset-id uint)
                       (metric-type (string-utf8 50))
                       (target-value int)
                       (min-acceptable int)
                       (max-acceptable int))
  (begin
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set service-level-agreements
      { asset-id: asset-id, metric-type: metric-type }
      {
        target-value: target-value,
        min-acceptable: min-acceptable,
        max-acceptable: max-acceptable
      }
    )
    (ok true)
  )
)

;; Record performance summary
(define-public (record-summary (asset-id uint)
                              (period-start uint)
                              (period-end uint)
                              (uptime-percentage uint)
                              (maintenance-count uint)
                              (average-response-time uint)
                              (compliance-score uint))
  (begin
    (asserts! (is-eq tx-sender contract-caller) (err u403))
    (map-set performance-summaries
      { asset-id: asset-id, period-start: period-start, period-end: period-end }
      {
        uptime-percentage: uptime-percentage,
        maintenance-count: maintenance-count,
        average-response-time: average-response-time,
        compliance-score: compliance-score
      }
    )
    (ok true)
  )
)

;; Read-only functions

;; Get metric details
(define-read-only (get-metric (metric-id uint))
  (map-get? performance-metrics { metric-id: metric-id })
)

;; Get SLA for an asset and metric type
(define-read-only (get-sla (asset-id uint) (metric-type (string-utf8 50)))
  (map-get? service-level-agreements { asset-id: asset-id, metric-type: metric-type })
)

;; Get performance summary
(define-read-only (get-summary (asset-id uint) (period-start uint) (period-end uint))
  (map-get? performance-summaries { asset-id: asset-id, period-start: period-start, period-end: period-end })
)

;; Check if a metric is within SLA
(define-read-only (is-within-sla (asset-id uint) (metric-type (string-utf8 50)) (value int))
  (let ((sla (map-get? service-level-agreements { asset-id: asset-id, metric-type: metric-type })))
    (if (is-some sla)
      (let ((sla-data (unwrap-panic sla)))
        (and (>= value (get min-acceptable sla-data))
             (<= value (get max-acceptable sla-data))))
      false)
  )
)
