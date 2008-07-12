#lang scheme

(require "messages.scm")
(require "network.scm")
(require "remember.scm")
(require "angles.scm")
(require (prefix-in sse- "steering-speed-estimator.scm"))
(require (prefix-in control- "control.scm"))
(require "path.scm")

(provide handle-message)

(define (handle-message m)
  ;(printf "~a~n" m)
  (cond
    ((init? m)
     (control-init (init-max-turn m) (init-max-hard-turn m))
     (clear-remembered)
     (sse-clear-history))
    ((end? m)
     (control-clear)
     (sse-clear-history))
    ((bump? m)
     (sse-clear-history))
    ((success? m)
     (control-clear)
     (sse-clear-history))
    ((failure? m)
     (control-clear)
     (sse-clear-history))
    ((telemetry? m)
     (remember-objects (telemetry-seen m))
     ;(print-remembered)
     (let* ((t (telemetry-time m))
            (self (telemetry-vehicle m))
            (x (vehicle-x self))
            (y (vehicle-y self))
            (dir (vehicle-dir self))
            (speed (vehicle-speed self))
            (target-dir (atan-deg (- y) (- x))))
       (sse-learn t dir)
       (let* ((dir-max-accel (sse-max-acceleration))
              (mht (control-max-hard-turn))
              (dir-target-diff (deg- target-dir dir))
              (steer (* 4 dir-target-diff))
              (accel (cond
                       ; not sure if this is the best way to compensate for steering speed...
                       ((< (* dir-max-accel (abs dir-target-diff))  50000) 1)
                       ((< (* dir-max-accel (abs dir-target-diff)) 100000) 0)
                       (else -1))))
         ;(printf "sse: ~a~n" dir-max-accel)
         ;(printf "steer: ~a~n" steer)
         (control-set-state-deg/sec accel steer))))))