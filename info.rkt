#lang setup/infotab
(define name "wn")
(define blurb '("FFI interface to the WordNet 3.0 Library: A Lexical Database for English"))
(define primary-file "wn.rkt")
(define scribblings '(("wn.scrbl" ())))
(define categories '(misc nlp))
(define homepage "https://github.com/themetaschemer/wn/")
(define collection "wn")
(define version "0.1")



(define deps '("base"))
(define build-deps '("racket-doc"
                     "scribble-lib"))
