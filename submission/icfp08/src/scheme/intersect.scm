#lang scheme

(provide line-intersects-circle? line-intersects-circle?-alt
         ray-circle-intersection-times
         ray-circle-intersection-first-time
         ray-circle-intersection-first-point
         curve-circle-intersection-angle
         )
(require "vec2.scm")
(require "misc-syntax.ss")
(require (only-in rnrs/base-6 assert))

(define (line-intersects-circle? p0 p1 center radius)
  (line-intersects-circle?-raw
   (vec2-x p0) (vec2-y p0)
   (vec2-x p1) (vec2-y p1)
   (vec2-x center) (vec2-y center)
   radius))   

(define (line-intersects-circle?-raw line-x0 line-y0 line-x1 line-y1 circle-x circle-y r)
  (when (> line-x0 line-x1)
    (swap! line-x0 line-x1)
    (swap! line-y0 line-y1))
  
  (and (not (or (> line-x0 (+ circle-x r))  ; completely to the right of vertical segment
                (< line-x1 (- circle-x r))  ; completely to the left of vertical segment
                (= line-x0 line-x1)         ; zero-length line
                ))

       (let* ((a (/ (- line-y0 line-y1) (- line-x0 line-x1)))
              (b (- line-y0 (* line-x0 a)))
              (c (sqrt (+ 1 (sqr a))))
              (D (- (sqr r) (sqr (/ (- circle-y (* a circle-x) b) c)))))
         (and (not (negative? D))
              (let ((rh (/ (sqrt D) c))
                    (lh (/ (+ (* a circle-y) circle-x (* a b -1))
                           (+ 1 (sqr a)))))
                (or (<= line-x0 (- lh rh) line-x1)
                    (<= line-x1 (+ lh rh) line-x1)))))))

(define (line-intersects-circle?-alt p0 p1 center radius)
  (ormap (lambda (time) (<= 0 time 1))
         (ray-circle-intersection-times p0 (vec2- p1 p0) center radius)))

(define (ray-circle-quadratic origin ray center radius)
  ; |origin + t * ray - center |^2 - r^2 = 0
  (let ((diff (vec2- origin center))
        (r2 (sqr radius)))
    ; |t * ray + diff |^2 - r^2 = 0
    ; (dx + t * rx)^2 + (..y..) - r^2 = 0
    ; dx^2 + 2*t*dx*rx + t^2*rx^2 + (..y..) - r^2 = 0
    ; (dx^2+dy^2-r^2) + (2*(dx*rx+dy*ry))*t + (rx^2+ry^2)*t^2 = 0
    ; C                     + B*t         + A*t^2           = 0
    (let ((c (- (vec2-length-squared diff) r2))
          (b (* 2 (vec2-dot-product ray diff)))
          (a (vec2-length-squared ray)))
      (values a b c))))

(define (ray-circle-intersection-times origin ray center radius)
  (let-values (((a b c) (ray-circle-quadratic origin ray center radius)))
    (solve-quadratic a b c)))

(define (ray-circle-intersection-first-time origin ray center radius)
  (ormap (lambda (time)
           (if (>= time 0)
               time
               #f))
         (ray-circle-intersection-times origin ray center radius)))

  
; returns the first intersection point or #f
(define (ray-circle-intersection-first-point origin ray center radius)
  (let ((time (ray-circle-intersection-first-time origin ray center radius)))
    (and time
         (vec2+ origin (vec2-scale time ray)))))

(define (solve-quadratic a b c)
  (let* ((b (* -1/2 b))
         (delta (- (* b b)
                   (* a c))))
    (cond
      ((< delta 0)
       '()) ; complex roots
      ((= delta 0)
       (list (/ b a))) ; one double root
      (else ; two distinct roots
       (let ((root (sqrt delta)))
         (list (/ (- b root) a)
               (/ (+ b root) a)))))))

; A curve is like a ray, but it goes along a circle arc. it's defined by a
; start-point, a curve-center and a direction (1 for ccw, -1 for cw).
; Returns the relative angle of the first intersection, or #f.
; The relative angle is always a positive number that tells how many degrees
; along the curve circle you have to go in the specified direction to hit
; the obstacle.
(define (curve-circle-intersection-angle curve-start curve-center direction
                                         obj-center obj-radius)
  ; see http://local.wasp.uwa.edu.au/~pbourke/geometry/2circle/ for formulas
  (let* ((curve-radius (vec2-length (vec2- curve-start curve-center)))
         (d-vec (vec2- obj-center curve-center))
         (d-squared (vec2-length-squared d-vec))
         (d (sqrt d-squared)))
    (and (< d (+ obj-radius curve-radius)) ; circles must intersect
         (> d (abs (- curve-radius obj-radius))) ; and not contain each other
         (let* ((s (+ (sqr curve-radius) (- (sqr obj-radius)) d-squared))
                (a (/ s (* 2 d)))
                (p2 (vec2+ curve-center (vec2-scale (/ a d) d-vec)))
                
                (h (sqrt (- (sqr curve-radius) (sqr a))))
                (h-vec (vec2-scale (/ h d) (vec2-rotate-ccw-90 d-vec)))
                
                (p3-1 (vec2+ p2 h-vec))
                (p3-2 (vec2- p2 h-vec))
                
                (angle1 (curve-angle curve-start curve-center p3-1 direction))
                (angle2 (curve-angle curve-start curve-center p3-2 direction)))
           (min angle1 angle2)))))

(define (test)
  (define (should-intersect p0 p1 c r)
    (assert (line-intersects-circle? p0 p1 c r))
    (assert (line-intersects-circle?-alt p0 p1 c r)))
  (should-intersect (make-vec2 -10 0) (make-vec2 10 0) (make-vec2 0 0) 5)
  (should-intersect (make-vec2 0 -10) (make-vec2 0 10) (make-vec2 0 0) 5)
  )

(define (test2)
  (define (t d)
    (let ((r (curve-circle-intersection-angle (make-vec2 50 10)
                                              (make-vec2 50 20) d
                                              (make-vec2 60 30) 10)))
      (printf "~a~n" r)
      r))
  (define (about-eq? a b) (< (abs (- a b)) 0.001))
  (assert (about-eq? (t 1) 90.0))
  (assert (about-eq? (t -1) 180)))
