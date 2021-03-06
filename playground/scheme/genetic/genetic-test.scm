#lang scheme

(require "gen-opt.scm")
(require "../cache/memoize.scm")

;Example of using genetic-optimize to find the minimum of a function in a range
;The function has some local minima to confuse the algorithm, see graph.jpg

;Some parameters you can tinker with
(let ((num-start 100) (num-pop 20) (num-child 10) (num-iter 10))
  (time
   (let/ec k
     (genetic-optimize
      ;Initial candidates: num-start random points in the range 0..10
      (for/list ((c (in-range num-start)))
        (* 10 (random)))
      ;Size of the population that survives
      num-pop
      ;Evaluation function. higher = better
      (memoize 10
               (lambda (x)
                 ;Find the minimum
                 (sleep .001)
                 (-
                  ;of y = cos(pi * x) / x
                  (/ (cos (* pi x)) x))))
      ;Combine two values, with some random mutation thrown in
      (lambda (x y)
        ;Multiply 100% +- some
        (* (+ 1 (/ (- (random) .5) 20))
           ;with the average of the two values
           (/ (+ x y) 2)))
      ;How many children will there be per surviving entity?
      num-child
      ;Callback
      (let ((i 0))
        (lambda (winners)
          (display winners) (newline)
          (set! i (add1 i))
          (when (> i num-iter)
            ;break
            (k (vector-ref winners 0)))))))))
