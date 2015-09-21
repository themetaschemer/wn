#lang racket

(require ffi/unsafe
         ffi/unsafe/define)
(require racket/generator)
(require racket/splicing)

(define-ffi-definer define-wn (ffi-lib "libWN"))

;;;------------------------------------------------------------------------------------
;;; Some basic definitions
;;;------------------------------------------------------------------------------------

(define allsenses        0)        ;; pass to findtheinfo() if want all senses
(define maxid           15)        ;; maximum id number in lexicographer file
(define maxdepth        20)        ;; maximum tree depth - used to find cycles
(define maxsense        75)        ;; maximum number of senses in database
(define max_forms        5)        ;; max # of different 'forms' word can have
(define maxfnum         44)        ;; maximum number of lexicographer files


;;;------------------------------------------------------------------------------------
;; Pointer type and search type counts
;;;------------------------------------------------------------------------------------
(define _search-type
  (_enum '(
           antonym = 1
           recursive-antonym = -1                   
           hypernym = 2
           recursive-hypernym = -2                   
           hyponym = 3
           recursive-hyponym = -3                   
           entails = 4
           recursive-entails = -4                   
           similar = 5
           recursive-similar = -5                   
           member-meronym = 6
           recursive-member-meronym = -6                   
           substance-meronym = 7
           recursive-substance-meronym = -7                   
           part-meronym = 8
           recursive-part-meronym = -8                   
           member-holonym = 9
           recursive-member-holonym = -9                   
           substance-holonym = 10
           recursive-substance-holonym = -10                   
           part-holonym = 11
           recursive-part-holonym = -11                   
           meronym = 12
           recursive-meronym = -12                   
           holonym = 13
           recursive-holonym = -13                   
           cause = 14
           recursive-cause = -14                   
           participle-of-verb = 15
           recursive-participle-of-verb = -15                   
           see-also = 16
           recursive-see-also = -16                   
           pertains-to = 17
           recursive-pertains-to = -17                   
           attribute = 18
           recursive-attribute = -18                   
           verb-group = 19
           recursive-verb-group = -19                   
           derivation = 20
           recursive-derivation = -20                   
           classification = 21
           recursive-classification = -21                   
           class = 22
           recursive-class = -22                   
           synonym = 23
           recursive-synonym = -23                   
           polysemy = 24
           recursive-polysemy = -24                   
           frame = 25
           recursive-frame = -25                   
           noun-coordinate = 26
           recursive-noun-coordinate = -26                   
           relative = 27
           recursive-relative = -27                   
           hierarchical-meronym = 28
           recursive-hierarchical-meronym = -28                   
           hierarchical-holonym = 29
           recursive-hierarchical-holonym = -29                   
           keyword-by-substring = 30
           recursive-keyword-by-substring = -30                   
           overview = 31
           recursive-overview = -31                   
           classification-category = 32
           recursive-classification-category = -32                   
           classification-usage = 33
           recursive-classification-usage = -33                   
           classification-regional = 34
           recursive-classification-regional = -34                   
           class-category = 35
           recursive-class-category = -35                   
           class-usage = 36
           recursive-class-usage = -36                   
           class-regional = 37
           recursive-class-regional = -37                   
           instance-of = 38
           recursive-instance-of = -38                   
           instances = 39
           recursive-instances = -39
           )))

(define search-type-list
  '(
    antonym recursive-antonym hypernym recursive-hypernym hyponym
    recursive-hyponym entails recursive-entails similar recursive-similar 
    member-meronym recursive-member-meronym substance-meronym 
    recursive-substance-meronym part-meronym recursive-part-meronym
    member-holonym recursive-member-holonym substance-holonym 
    recursive-substance-holonym part-holonym recursive-part-holonym 
    meronym recursive-meronym holonym recursive-holonym cause
    recursive-cause participle-of-verb recursive-participle-of-verb 
    see-also recursive-see-also pertains-to recursive-pertains-to
    attribute recursive-attribute verb-group recursive-verb-group derivation
    recursive-derivation classification recursive-classification class
    recursive-class synonym recursive-synonyms polysemy recursive-polysemy
    frame recursive-frame noun-coordinate recursive-noun-coordinate 
    relative recursive-relative hierarchical-meronym recursive-hierarchical-meronym
    hierarchical-holonym recursive-hierarchical-holonym keyword-by-substring
    recursive-keyword-by-substring overview recursive-overview             
    classification-category recursive-classification-category classification-usage
    recursive-classification-usage classification-regional recursive-classification-regional
    class-category recursive-class-category class-usage recursive-class-usage class-regional 
    recursive-class-regional instance-of recursive-instance-of instances recursive-instances
    ))

(define (search-type? x)
  (member x search-type-list))

(define (limited-search-type? x)
  (and (search-type? x)
       (not (member x '(see-also pertains-to verb-group polysemy frame relative keyword-by-substring overview)))))

;;;------------------------------------------------------------------------------------
;; WordNet part of speech stuff
;;;------------------------------------------------------------------------------------

(define numparts        4)        ;; number of parts of speech
(define numframes       35)       ;; number of verb frames

;; Generic names for part of speech
(define _parts-of-speech
  (_enum '(all-parts-of-speech = 0
           noun = 1
           verb
           adjective
           adverb
           satellite)))

(define parts-of-speech '(noun verb adjective adverb satellite))
(define (part-of-speech? x) (member x parts-of-speech))

;; Adjective markers

(define _adjective-markers
  (_enum '(unknown-marker = 0 
           padj = 1 
           npadj 
           ipadj)))

(define attributive                   'npadj)
(define predicative                   'padj)
(define immediate-postnominal             'ipadj)

(define (sense-id? x) (and (integer? x) (>= x 0)))

;;;------------------------------------------------------------------------------------
;; Data structures used by search code functions.
;;;------------------------------------------------------------------------------------

;; Basic definitions for pointers
(define-cpointer-type _long-pointer)
(define-cpointer-type _int-pointer)
(define-cpointer-type _string-pointer)
(define-cpointer-type _FILE)


;; Structure for index file entry
(define-cstruct _c-index
  ([index-offset          _long]               ;; byte offset of entry in index file
   [word                  _string]             ;; word string
   [part-of-speech        _string]             ;; part of speech
   [sense-count           _int]                ;; sense (collins) count
   [offset-count          _int]                ;; number of offsets
   [tagged-count          _int]                ;; number senses that are tagged
   [offset                _long-pointer]       ;; offsets of synsets containing word, _pointer to _long
   [pointers-used-count   _int]                ;; number of pointers used
   [pointers-used         _int-pointer]))      ;; pointers used _pointer to _int|#


;; Structure for data file synset
(define-cstruct _c-synset 
    ([here-i-am                   _long]               ;; current file position
     [synset-type                 _adjective-markers]  ;; type of ADJ synset
     [file-num                    _int]                ;; file number that synset comes from
     [part-of-speech              _string]             ;; part of speech
     [word-count                  _int]                ;; number of words in synset
     [c-words                     _string-pointer]     ;; words in synset (pointer to string)|#
     [lex-id                      _int-pointer]        ;; unique id in lexicographer file (pointer to int)|#
     [wn-sense                    _int-pointer]        ;; sense number in wordnet (pointer to int)|#
     [which-word                  _int]                ;; which word in synset we're looking for
     [pointer-count               _int]                ;; number of pointers
     [pointer-type                _int-pointer]        ;; pointer types (pointer to int)|#
     [pointer-offsets             _long-pointer]       ;; pointer offsets (pointer to long)
     [pointer-part-of-speech      _int-pointer]        ;; pointer part of speech (pointer to int)|#
     [pointer-to                  _int-pointer]        ;; pointer 'to' fields (pointer to int)|#
     [pointer-from                _int-pointer]        ;; pointer 'from' fields (pointer to int)|#
     [verb-frame-count            _int]                ;; number of verb frames
     [frame-ids                   _int-pointer]        ;; frame numbers (pointer to int)|#
     [frame-to                    _int-pointer]        ;; frame 'to' fields (pointer to int)|#
     [definition                  _string]             ;; synset gloss (definition)
     [key                         _uint]               ;; unique synset key

     ;; these fields are used if a data structure is returned instead of a text buffer

     [next-synset                 _c-synset-pointer/null]   ;; ptr to next synset containing searchword (pointer to synset)|#
     [next-form                   _c-synset-pointer/null]   ;; ptr to list of synsets for alternate spelling of wordform  (pointer to synset)|#
     [search-type                 _search-type]             ;; type of search performed
     [pointer-list                _c-synset-pointer/null]   ;; ptr to synset list result of search (pointer to synset)|#
     [head-word                   _string]                  ;; if pos is "s", this is cluster head word
     [head-sense                  _short]))                 ;; sense number of headword

;; Synset Index
(define-cstruct _c-sns-index
  ([sense-key         _string]                ;; sense key
   [word              _string]                ;; word string
   [offset            _long]                  ;; synset offset
   [wn-sense          _int]                   ;; WordNet sense number
   [tag-cnt           _int]                   ;; number of semantic tags to sense
   [next-sns-index    _c-sns-index-pointer])) ;; ptr to next sense index entry (pointer to c-sns-index)|#

;; Search Results
(define-cstruct _c-search-results 
  ((sense-count     (_array _int max_forms))     ;; number of senses word form has                                   
   (out-sense-count (_array _int max_forms))     ;; number of senses printed for word form
   (num-forms       _int)                        ;; number of word forms searchword has
   (print-count     _int)                        ;; number of senses printed by search
   (search-buf      _string)                     ;; buffer containing formatted results
   (search-ds       _c-synset-pointer)))         ;; data structure containing search results


;;;------------------------------------------------------------------------------------
;;; External library function prototypes
;;;------------------------------------------------------------------------------------

;;;------------------------------------------------------------------------------------
;;;  Search and database functions (search.c) 
;;;------------------------------------------------------------------------------------

;; Primary search algorithm for use with user interfaces
(define-wn find-the-info (_fun _string  _parts-of-speech  _search-type _int -> _string) #:c-id findtheinfo)        

;; Primary search algorithm for use with programs (returns data structure)
(define-wn find-the-info-ds (_fun _string  _parts-of-speech _search-type _int -> _c-synset-pointer/null) #:c-id findtheinfo_ds)

;; Set bit for each search type that is valid for the search word
;;   passed and return bit mask.
(define-wn is-defined (_fun _string  _parts-of-speech -> _uint) #:c-id is_defined)

(define (available-search-types string part-of-speech)
  (call/cc
   (λ (k)
    (for/fold ([avail '()]
               [mask   (is-defined string part-of-speech)]) ([i (in-naturals 0)])
      (cond
       [(= mask 0) (k avail)]
       [(= 1 (modulo mask 2))  (values (cons (list-ref search-type-list (* 2 i)) avail) (quotient mask 2))]
       [else (values avail (quotient mask 2))])))))

;; Set bit for each POS that search word is in.  0 returned if word is not in WordNet.
(define-wn in-wn (_fun _string  _int -> _uint) #:c-id in_wn)        

;; Find word in index file and return parsed entry in data structure.
;;   Input word must be exact match of string in database.
(define-wn index-lookup (_fun _string  _int -> _c-index-pointer) #:c-id index_lookup) 

;; smart search of index file.  Find word in index file trying different
;; techniques - replace hyphens with underscores replace underscores with
;; hyphens strip hyphens and underscores strip periods.

(define-wn get-index (_fun _string  _int -> _c-index-pointer) #:c-id getindex)        
(define-wn parse-index (_fun _long _int _string  -> _c-index-pointer) #:c-id parse_index)

;; Read synset from data file at byte offset passed and return parsed
;; entry in data structure.
(define-wn read-synset (_fun _int _long _string  -> _c-synset-pointer) #:c-id read_synset)

;; Read synset at current byte offset in file and return parsed entry
;;   in data structure.
(define-wn parse-synset (_fun _FILE _int _string  -> _c-synset-pointer) #:c-id parse_synset) 

;; Free a synset linked list allocated by findtheinfo_ds()
(define-wn free-syns (_fun _c-synset-pointer -> _void) #:c-id free_syns)        

;; Free a synset
(define-wn free-synset (_fun _c-synset-pointer -> _void) #:c-id free_synset)        

;; Free an index structure
(define-wn free-index (_fun _c-index-pointer -> _void) #:c-id free_index)        

;; Recursive search algorithm to trace a pointer tree and return results
;; in linked list of data structures.
(define-wn trace-ptrs-ds (_fun _c-synset-pointer _int _int _int -> _c-synset-pointer) #:c-id traceptrs_ds)

;; Do requested search on synset passed returning output in buffer.
(define-wn do-trace (_fun _c-synset-pointer _int _int _int -> _string) #:c-id do_trace)


;;;------------------------------------------------------------------------------------
;;; Morphology functions (morph.c) 
;;;------------------------------------------------------------------------------------

;; Open exception list files
(define-wn morph-init (_fun  -> _int) #:c-id morphinit)        

;; Close exception list files and reopen
(define-wn re-morph-init (_fun  -> _int) #:c-id re_morphinit)        

;; Try to find baseform (lemma) of word or collocation in POS.
(define-wn morph-str (_fun _string  _parts-of-speech -> _string) #:c-id morphstr)        

;; Try to find baseform (lemma) of individual word in POS.
(define-wn morph-word (_fun _string  _parts-of-speech -> _string) #:c-id morphword)        

;;;------------------------------------------------------------------------------------
;;; Utility functions (wnutil.c) 
;;; ------------------------------------------------------------------------------------

;; Top level function to open database files initialize wn_filenames,
;; and open exeception lists.
(define-wn wn-init (_fun  -> _int) #:c-id wninit)                

;; Top level function to close and reopen database files initialize
;;   wn_filenames and open exception lists.
(define-wn re-wn-init (_fun  -> _int) #:c-id re_wninit)        

;; Count the number of underscore or space separated words in a string.
(define-wn count-words (_fun _string  _byte -> _int) #:c-id cntwords)                

;; Return pointer code for pointer type characer passed.
(define-wn get-ptr-type (_fun _string  -> _int) #:c-id getptrtype)        

;; Return part of speech code for string passed
(define-wn get-pos (_fun _string  -> _int) #:c-id getpos)                

;; Return synset type code for string passed.
(define-wn get-synset-type (_fun _string  -> _int) #:c-id getsstype)                

;; Reconstruct synset from synset pointer and return ptr to buffer
(define-wn format-synset (_fun _c-synset-pointer _int -> _string) #:c-id FmtSynset)        

;; Find string for 'searchstr' as it is in index file
(define-wn get-wn-str (_fun _string  _int -> _string) #:c-id GetWNStr)

;; Pass in string for POS return corresponding integer value
(define-wn str-to-pos (_fun _string  -> _int) #:c-id StrToPos)

;; Return synset for sense key passed.
(define-wn get-synset-for-sense (_fun _string  -> _c-synset-pointer) #:c-id GetSynsetForSense)

;; Find offset of sense key in data file
(define-wn get-data-offset (_fun _string  -> _long) #:c-id GetDataOffset)

;; Find polysemy (collins) count for sense key passed.
(define-wn get-poly-count (_fun _string  -> _int) #:c-id GetPolyCount)

;; Return word part of sense key
(define-wn get-word-for-sense-key (_fun _string  -> _string) #:c-id GetWORD)

;; Return POS code for sense key passed.
(define-wn get-pos-for-sense-key (_fun _string  -> _int) #:c-id GetPOS)

;; Convert WordNet sense number passed of _c-index-pointer entry to sense key.
(define-wn wn-sns-to-str (_fun _c-index-pointer _int -> _string) #:c-id WNSnsToStr)

;; Search for string and/or baseform of word in database and return index structure for word if found in database.
(define-wn get-valid-index-pointer (_fun _string  _int -> _c-index-pointer) #:c-id GetValidIndexPointer)

;; Return sense number in database for word and lexsn passed.
(define-wn get-wn-sense (_fun _string  _string  -> _int) #:c-id GetWNSense)

(define-wn get-sense-index (_fun _string  -> _c-sns-index-pointer) #:c-id GetSenseIndex)

(define-wn get-offset-for-key (_fun _uint -> _string) #:c-id GetOffsetForKey)
(define-wn get-key-for-offset (_fun _string  -> _uint) #:c-id GetKeyForOffset)

(define-wn set-search-dir (_fun  -> _string) #:c-id SetSearchdir)

;; Return number of times sense is tagged
(define-wn get-tag-count (_fun _c-index-pointer _int -> _int) #:c-id GetTagcnt)


;;;------------------------------------------------------------------------------------
;;; A saner interface to synset navigation to use within racket. 
;;;------------------------------------------------------------------------------------

;; Iterators over the results

(define-syntax (in-sense x)
  (syntax-case x ()
    [(_ synset-ptr)
     #'(in-generator (let loop ([s synset-ptr])
                       (when s
                             (yield s)
                             (loop (c-synset-next-synset s)))))]))

(define-syntax (in-results x)
  (syntax-case x ()
    [(_ synset-ptr)
     #'(in-generator (let loop ([s synset-ptr])
                       (when s
                             (yield s)
                             (loop (c-synset-pointer-list s)))))]))

(define-syntax (in-words x)
  (syntax-case x ()
    [(_ synset-ptr)
     #'(in-generator (let ([s synset-ptr])
                       (for ([i (in-range (c-synset-word-count s))])
                         (yield (ptr-ref (c-synset-c-words s) _string i)))))]))

;; A cleaner way to access the words inside a synset

(define (c-synset-words c-synset-ptr)
  (for/list ([word (in-words c-synset-ptr)]) word))


(define (all-results word part-of-speech search-type)
  (let ([synset (find-the-info-ds word part-of-speech search-type 0)])
    (remove-duplicates
     (for*/list ([sense (in-sense synset)]
                 [result (in-results sense)]
                 [word  (in-words result)])
                word))))

(define-syntax (declare-search-functions x)
  (syntax-case x ()
    [(_ scope search-type ...)
     (with-syntax ([(fname ...) 
                    (datum->syntax #'scope
                                   (map 
                                    (λ (d) (if (symbol? d)
                                               (string->symbol (format "~as" d))
                                               (string->symbol (format "~a" (car d)))))
                                    (syntax->datum #'(search-type ...))))]
                   [(sname ...) 
                    (datum->syntax #'scope
                                   (map 
                                    (λ (d) (if (symbol? d) d (cadr d)))
                                    (syntax->datum #'(search-type ...))))]
                   [(recursive-search-type ...) 
                    (datum->syntax #'scope 
                                   (map 
                                    (λ (d) (if (symbol? d)
                                               (string->symbol (format "recursive-~a" d))
                                               (string->symbol (format "recursive-~a" (cadr d)))))
                                    (syntax->datum #'(search-type ...))))])
                  #'(begin
                      (define (fname word part-of-speech #:recursive [recursive #t])
                        (if recursive
                            (all-results word part-of-speech 'recursive-search-type)
                            (all-results word part-of-speech 'sname)))
                      ...))]))

(declare-search-functions all-results ;; All functions are declared at the same scope of this name.
                          antonym hypernym hyponym entail similar  member-meronym
                          substance-meronym part-meronym member-holonym substance-holonym part-holonym
                          meronym holonym cause [participles-of-verb participle-of-verb] attribute
                          derivation classification [classes class] synonym noun-coordinate
                          hierarchical-meronym hierarchical-holonym
                          [classification-categories classification-category]
                          classification-usage classification-regional
                          [class-categories class-category] class-usage class-regional
                          [instances-of instance-of] instance)
 
(define (lemma word part-of-speech) (morph-str word part-of-speech))

(provide (all-defined-out))

