#lang scribble/manual
@(require (for-label racket/base "wn.ss")) 
@title{WordNet - A Lexical Database for English}

This is a Racket FFI interface to the Princeton University's WordNet® library. The following excerpt from their website adequately summarizes what WordNet is.

@nested[#:style 'inset]{@italic{WordNet is a large lexical database of English. Nouns, verbs, adjectives and adverbs are grouped into sets of cognitive synonyms (synsets), each expressing a distinct concept. Synsets are interlinked by means of conceptual-semantic and lexical relations. The resulting network of meaningfully related words and concepts can be navigated with the browser. WordNet is also freely and publicly available for download. WordNet's structure makes it a useful tool for computational linguistics and natural language processing.}

@italic{WordNet superficially resembles a thesaurus, in that it groups words together based on their meanings. However, there are some important distinctions. First, WordNet interlinks not just word forms—strings of letters—but specific senses of words. As a result, words that are found in close proximity to one another in the network are semantically disambiguated. Second, WordNet labels the semantic relations among words, whereas the groupings of words in a thesaurus does not follow any explicit pattern other than meaning similarity.}}

@section{Requirements}

This package has been developed and tested on Mac OS X (10.10). The instructions here should largely be applicable for Linux and other forms of Unix. If you run into any issues, please contact the author. 

@section{Installing the WordNet library}

The WordNet library is available from @link["https://wordnet.princeton.edu/wordnet/download/current-version/"]{here}. The default library available from WordNet links into a static library, which is unusable by the Racket FFI.
Follow the instructions in this section to build a shared library.

Assume that ~/Downloads/WordNet-3.0 is the directory into which the tarball has been untar'd.

@verbatim{
> cd ~/Downloads/WordNet-3.0
}

Edit the @code{configure.ac} file and add the following lines to it, after the line that says @code{AC_PROG_INSTALL}:

@verbatim{
AC_ENABLE_SHARED
AC_DISABLE_STATIC
AC_PROG_LIBTOOL(libtool)
}

Edit the @code{lib/Makefile.am} file and replace its contents with the following:

@verbatim{
lib_LTLIBRARIES = libWN.la
libWN_la_SOURCES = binsrch.c morph.c search.c wnglobal.c wnhelp.c wnrtl.c\
                   wnutil.c
libWN_la_CPPFLAGS = $(INCLUDES) -fPIC
libWN_la_LDFLAGS = -shared -fPIC
INCLUDES = -I$(top_srcdir) -I$(top_srcdir)/include
SUBDIRS = wnres
}

Now, reconfigure and build the distribution. Replace the prefix to suit your installation appropriately

@verbatim{
> autoreconf -i
> ./configure --prefix="/usr/local"  
> make
> sudo make install
}

Your library and its associate data will now be installed in @code{/usr/local}

@section{About the library}
@defmodule[wn/wn #:packages ("base")]

The WordNet library consists of a few sections: Search, Morphology and Utilities. This Racket interface to the library leaves out some of the utilities because they are largely redundant. The documentation of the original C library functions is available @hyperlink["https://wordnet.princeton.edu/wordnet/documentation/"]{here}.

The library must be initialized before any of the functions can be used. The following function initializes the library.

@defproc[(wn-init) integer?]{
                   Returns 0 upon successful initialization, a non-zero number othrewise. This function must be called before any of the other functions are called. 
}

@section{High Level Interface}
This section describes a higher level interface for accessing the word-net functions. It largely consists of two things: Searching and Lemmatization. 
The searching functions are defined as functions that return lists of words based on the search criteria. All the search-functions have an identical format which is as follows. 
@defproc[(<search-fn> [word string?]
                     [part-of-speech parts-of-speech?]
                     [#:recursive recursive? boolean? #t]) (listof string?)]{
                     Apply the search-function designated by the name @tt{<search-fn>} and return the results as a list of words.
                     @var{word} can be any word, or a collocation (words joined by `_').
                     @var{part-of-speech} is one of @tt{'noun},@tt{'verb},@tt{'adjective},@tt{'adverb}, or @tt{satellite}. Refer to the type definition below for details.
                     @var{recursive?} indicates if the results should be searched recursively. The default is to return results recursively. For example, when searching for hypernyms of a word, @var{recursive?} being @tt{#t} will
                     return not just the immediate hypernyms, but will recursively follow those hypernyms returning a whole chain of hypernyms. Providing @tt{#f} for this argument will
                     only return immediate hypernyms.
                     }
The following search functions are provided:
@verbatim{
antonyms 
hypernyms 
hyponyms 
entails 
similars  
member-meronyms 
substance-meronyms 
part-meronyms
member-holonyms 
substance-holonyms 
part-holonyms  
meronyms 
holonyms 
causes 
participles-of-verb 
attributes 
derivations 
classifications 
classes 
synonyms 
noun-coordinates 
hierarchical-meronyms
hierarchical-holonyms 
classification-categories
classification-usages 
classification-regionals
class-categories 
class-usages 
class-regionals 
instances-of 
instances
}

@defproc[(lemma [word string?]
                [part-of-speech parts-of-speech?]) (or/c string? #f)]{
                Lemmatize the provided word, in the given part of speech. @var{part-of-speech} is one of @tt{'noun},@tt{'verb},@tt{'adjective},@tt{'adverb}, or @tt{satellite}. Refer to the type definition below for details
                }

@defproc[(parts-of-speech? [x any/c]) boolean]{
  Returns @code{#t} if x is one of: @racket['noun], @racket['verb], @racket['adjective], @racket['adverb], @racket['satellite].
  Most of these are obvious, but @tt{'satellite} stands for an adjective cluster which consists of more than one concept in it. This part-of-speech very specific to WordNet. Use it if you understand what it is. 
}

@section{The C Library Interface}
This section covers the lower-level C library interface. The high-level interface covers most of what is necessary, but should you need deeper access into the library, the following document should help.
                
@subsection{Basic Type Definitions}

@defproc[(search-type? [x any/c]) boolean?]{
Returns @code{#f} if x is not one of the following values (which are mostly self-explanatory.):
 @racket['antonym], @racket['recursive-antonym],@(linebreak)
 @racket['hypernym], @racket['recursive-hypernym],@(linebreak)
 @racket['hyponym], @racket['recursive-hyponym],@(linebreak)
 @racket['entails], @racket['recursive-entails],@(linebreak)
 @racket['similar], @racket['recursive-similar],@(linebreak)
 @racket['member-meronym], @racket['recursive-member-meronym],@(linebreak)
 @racket['substance-meronym], @racket['recursive-substance-meronym],@(linebreak)
 @racket['part-meronym], @racket['recursive-part-meronym],@(linebreak)
 @racket['member-holonym], @racket['recursive-member-holonym],@(linebreak)
 @racket['substance-holonym], @racket['recursive-substance-holonym],@(linebreak)
 @racket['part-holonym], @racket['recursive-part-holonym],@(linebreak)
 @racket['meronym], @racket['recursive-meronym],@(linebreak)
 @racket['holonym], @racket['recursive-holonym],@(linebreak)
 @racket['cause], @racket['recursive-cause],@(linebreak)
 @racket['particple-of-verb], @racket['recursive-particple-of-verb],@(linebreak)
 @racket['see-also], @racket['recursive-see-also],@(linebreak)
 @racket['pertains-to], @racket['recursive-pertains-to],@(linebreak)
 @racket['attribute], @racket['recursive-attribute],@(linebreak)
 @racket['verb-group], @racket['recursive-verb-group],@(linebreak)
 @racket['derivation], @racket['recursive-derivation],@(linebreak)
 @racket['classification], @racket['recursive-classification],@(linebreak)
 @racket['class], @racket['recursive-class],@(linebreak)
 @racket['synonyms], @racket['recursive-synonyms],@(linebreak)
 @racket['polysemy], @racket['recursive-polysemy],@(linebreak)
 @racket['frames], @racket['recursive-frames],@(linebreak)
 @racket['noun-coordinates], @racket['recursive-noun-coord@(linebreak)inates],
 @racket['relatives], @racket['recursive-relatives],@(linebreak)
 @racket['hierarchical-meronym], @racket['recursive-hierarchical-meronym],@(linebreak)
 @racket['hierarchical-holonym], @racket['recursive-hierarchical-holonym],@(linebreak)
 @racket['keywords-by-substring], @racket['recursive-keywords-by-substring],@(linebreak)
 @racket['overview], @racket['recursive-overview],@(linebreak)
 @racket['classification-category], @racket['recursive-classification-category],@(linebreak)
 @racket['classification-usage], @racket['recursive-classification-usage],@(linebreak)
 @racket['classification-regional], @racket['recursive-classification-regional],@(linebreak)
 @racket['class-category], @racket['recursive-class-category],@(linebreak)
 @racket['class-usage], @racket['recursive-class-usage],@(linebreak)
 @racket['class-regional], @racket['recursive-class-regional],@(linebreak)
 @racket['instance-of], @racket['recursive-instance-of],@(linebreak)
 @racket['instances], @racket['recursive-instances].

The names here are made more readable, but are drawn from the list of
``search ptrs'' in the documentation. They correspond to
@tt{#define}'d constants in the file wn.h in the WordNet source
directory. The `@tt{recursive-}' versions of these constants are
negated, according to the convention used by WordNet, which uses
negative search types for recursive searches.  For more information
about these search types, it is best to refer to the code. The WordNet
Documentation is sparse, and will mostly direct you to play with the
command line tools.  
}

@defproc[(limited-search-type? [x any/c]) boolean?]{
  Excludes the following symbols from @code{search-type?}:
  @racket['see-also], @racket['pertains-to] @racket['verb-group] @racket['polysemy] @racket['frames] @racket['relatives] @racket['keywords-by-substring] @racket['overview]
  The @racket{find-the-info-ds} function only accepts @tt{limited-search-type?} values.                       
}

@defproc[(c-synset? [x any?]) boolean?]{
  Values returned by the low level search function in the WordNet library. Results are pointers to a structure of this type. @tt{findTheInfo_ds} in t                   
}


@subsection{Search Functions}
@defproc[(find-the-info [search-str     string?]
                        [part-of-speech part-of-speech?]
                        [search-type    search-type?]
                        [sense-id       non-negative-integer?]) (or/c string? #f)]{
             Finds the information about a word and returns it in the form of a string. Search results are automatically formatted, and the formatted string is returned.
             @var[search-str] is either the word, or a collocation (words conjoined by "_") to search for.
             Available search-types can be queried by calling @tt{available-search-types}.
             @var[sense-id] is a non-negative integer indicating which sense is sought. Using 0 returns results for all senses.                       
}

@defproc[(available-search-types [string string?]
                                 [part-of-speech part-of-speech?]) (list-of search-type?)]{
                                 Returns the types of searches that are available for a give string. It only return non-recursive versions of search types. 
}
                                 
@defproc[(find-the-info-ds [search-str string?]
                         [part-of-speech part-of-speech?]
                         [search-type limited-search-type?]
                         [sense-id    non-negative-integer?]) (or/c c-synset? #f)]{

             Finds the information about a word and returns it in the form of a list of synsets. 
             @var[search-str] is either the word, or a collocation (words conjoined by "_") to search for.
             Available search-types can be queried by calling @tt{available-search-types}, but note that they must be of @racket{limited-search-type?}.
             @var[sense-id] is a non-negative integer indicating which sense is sought. Using 0 returns results for all senses.                       
}

@defform[(in-senses c-synset-ptr)
                     #:contracts [(c-synset-ptr (or/c c-synset? #f))]]{
                      A form intended to be used in @tt{for} comprehensions to iterate over all the senses of a synset
}

@defform[(in-results c-synset-ptr) #:contracts [(c-synset-ptr (or/c c-synset? #f))]]{
                      A form intended to be used in @tt{for} comprehensions to iterate over all the results in a sense of synset
}

@defform[(in-words c-synset-ptr) #:contracts [(c-synset-ptr (or/c c-synset? #f))]]{
                      A form intended to be used in @tt{for} comprehensions to iterate over all the words in a synset
}
                         

@subsection{Example for iteration forms}
The following example illustrates how to navigate a synset result and extract the returned values.
@racketblock[
        (define (hypernyms word part-of-speech search-type)
          (let ([synset (find-the-info-ds word part-of-speech 'recursive-hypernym 0)])
            (remove-duplicates
               (for*/list ([sense (in-senses synset)]
                           [result (in-results sense)]
                           [word  (in-words result)])
                  word))))]{}




@subsection{The @tt{c-synset} data-structure}
The @tt{c-synset} data structure is defined as follows. For each of the following fields, a field accessor called @tt{c-synset-<field-name>} is defined and can be used to access data from returned C pointers. Refer to the FFI documentation for more information.

@racketblock[
(define-cstruct _c-synset 
    ([here-i-am                   _long]                    (code:comment @#,t{current file position})
     [synset-type                 _adjective-markers]       (code:comment @#,t{type of ADJ synset})
     [file-num                    _int]                     (code:comment @#,t{file number that synset comes from})
     [part-of-speech              _string]                  (code:comment @#,t{part of speech})
     [word-count                  _int]                     (code:comment @#,t{number of words in synset})
     [c-words                     _string-pointer]          (code:comment @#,t{words in synset (pointer to string)})
     [lex-id                      _int-pointer]             (code:comment @#,t{unique id in lexicographer file (pointer to int)})
     [wn-sense                    _int-pointer]             (code:comment @#,t{sense number in wordnet (pointer to int)})
     [which-word                  _int]                     (code:comment @#,t{which word in synset we're looking for})
     [pointer-count               _int]                     (code:comment @#,t{number of pointers})
     [pointer-type                _int-pointer]             (code:comment @#,t{pointer types (pointer to int)})
     [pointer-offsets             _long-pointer]            (code:comment @#,t{pointer offsets (pointer to long)})
     [pointer-part-of-speech      _int-pointer]             (code:comment @#,t{pointer part of speech (pointer to int)})
     [pointer-to                  _int-pointer]             (code:comment @#,t{pointer 'to' fields (pointer to int)})
     [pointer-from                _int-pointer]             (code:comment @#,t{pointer 'from' fields (pointer to int)})
     [verb-frame-count            _int]                     (code:comment @#,t{number of verb frames})
     [frame-ids                   _int-pointer]             (code:comment @#,t{frame numbers (pointer to int)})
     [frame-to                    _int-pointer]             (code:comment @#,t{frame 'to' fields (pointer to int)})
     [definition                  _string]                  (code:comment @#,t{synset gloss (definition)})
     [key                         _uint]                    (code:comment @#,t{unique synset key})
     [next-synset                 _c-synset-pointer/null]   (code:comment @#,t{ptr to next synset containing searchword (pointer to synset)})
     [next-form                   _c-synset-pointer/null]   (code:comment @#,t{ptr to list of synsets for alternate spelling of wordform  (pointer to synset)})
     [search-type                 _search-type]             (code:comment @#,t{type of search performed})
     [pointer-list                _c-synset-pointer/null]   (code:comment @#,t{ptr to synset list result of search (pointer to synset)})
     [head-word                   _string]                  (code:comment @#,t{if pos is "s", this is cluster head word})
     [head-sense                  _short]))                 (code:comment @#,t{sense number of headword})
]     