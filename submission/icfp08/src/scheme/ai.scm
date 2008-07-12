#lang scheme

(require "messages.scm")
(require "network.scm")
(require "remember.scm")
(require "angles.scm")
(require (prefix-in control- "control.scm"))
(require "path.scm")

(provide handle-message)

(define (handle-message m)
  ;(printf "~a~n" m)
  (cond
    ((init? m)
     (control-init (init-max-turn m) (init-max-hard-turn m))
     (clear-remembered)
     )
    ((end? m)
     (control-clear)
    ((bump? m)
    ((success? m)
     (control-clear)
    ((failure? m)
     (control-clear)
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
              (dir-target-diff (deg- target-dir dir))
              (steer (* 2 dir-target-diff))
              (accel (cond
                       ; pedal to the medal as long as we're not *completely* off course!
                       ((< (abs dir-target-diff)  120) 1)
                       ((< (abs dir-target-diff)  120) 0)
                       (else -1))))
         (control-set-state-deg/sec accel steer))))))