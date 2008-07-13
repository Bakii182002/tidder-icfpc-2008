#lang scheme

(require "libraries/search/astar.ss")
(require "vec2.scm")
(require "remember.scm")
(require "intersect.scm")
(require "messages.scm")
(require "tangent.scm")

(provide safety-margin compute-target)

; The idea is to store a "planned path", i.e. the path we will follow if no
; information arrives, and to recompute it whenever the planned path turns out
; to be blocked.

; Disregarding acceleration, an optimal path around an obstacle course is
; always a combination of straight lines tangential to an obstacle, and
; arcs around an obstacle. I think we can make the simplifying assumption
; that this is true even with acceleration.

; Given that, paths are compactly stored as a list of relevant obstacles that
; are circled around, plus the direction in which we avoid the obstacles.
; The empty list corresponds to the path that goes directly to the end point.

(define safety-margin 1.0) ; 100% of vehicle's width

(define (safe-radius o)
  (+ safety-margin
     (obj-radius o)))

(define (compute-target pos)
  ; pos = position of our rover
  (safe-point pos (make-vec2 0 0)))

; Returns a point that we can safely travel to. For the full pathfinding,
; this needs to generate all suitable points.
(define (safe-point pos target)
  (let ((real-target target)
        (visited (make-hash))
        (obstacle #f)
        (direction 0))
    (let avoidance-loop ()
      (printf ".")
      (let* ((ray (vec2- target pos))
             (b (first-hit-obj pos ray)))
        (when (and b (not (hash-ref visited b #f)))
          (hash-set! visited b #t)
          (let ((t (ray-circle-intersection-first-time
                    pos ray (obj-pos b) (obj-radius b))))
            (when (< t 1)
              ; adjust target to be left tangent point
              ; this is the point where we will need to branch for the full
              ; search, and also consider the right tangent point.
              (set! target (tangent pos (obj-pos b) (safe-radius b) 1))
              (set! obstacle b)
              (set! direction 1)
              (avoidance-loop))))))
    (tangent-point pos real-target obstacle direction)))

; Finds a tangent point on the obstacle with the given direction, keeping an
; eye on the final target. If another obstacle is connected to this one and
; blocks the arc that we want to drive, considers finding a tangent point on
; that obstacle instead.
(define (tangent-point pos target obstacle direction)
  (let ((p (tangent pos (obj-pos obstacle) (safe-radius obstacle) direction)))
    ; TODO
    p))
