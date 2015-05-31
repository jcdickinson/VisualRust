lexer grammar RustLexer;

tokens {
    EQ, LT, LE, EQEQ, NE, GE, GT, ANDAND, OROR, NOT, TILDE,
    MINUS, STAR, SLASH, PERCENT, CARET, AND, OR, SHL, SHR, BINOP,
    BINOPEQ, AT, DOT, DOTDOT, DOTDOTDOT, COMMA, SEMI, COLON,
    MOD_SEP, RARROW, FAT_ARROW, LPAREN, RPAREN, LBRACKET, RBRACKET,
    LBRACE, RBRACE, POUND, DOLLAR, UNDERSCORE, LIT_CHAR,
    LIT_INTEGER, LIT_FLOAT, LIT_STR, LIT_STR_RAW, LIT_BINARY,
    LIT_BINARY_RAW, IDENT, LIFETIME, WHITESPACE, DOC_COMMENT,
    COMMENT, SHEBANG, DOC_BLOCK_COMMENT, BLOCK_COMMENT
}

import xidstart , xidcontinue;


/* Expression-operator symbols */

EQ      : '=' ;
LT      : '<' ;
LE      : '<=' ;
EQEQ    : '==' ;
NE      : '!=' ;
GE      : '>=' ;
GT      : '>' ;
ANDAND  : '&&' ;
OROR    : '||' ;
NOT     : '!' ;
TILDE   : '~' ;
PLUS    : '+' ;
MINUS   : '-' ;
STAR    : '*' ;
SLASH   : '/' ;
PERCENT : '%' ;
CARET   : '^' ;
AND     : '&' ;
OR      : '|' ;
SHL     : '<<' ;
SHR     : '>>' ;

BINOP
    : PLUS
    | SLASH
    | MINUS
    | STAR
    | PERCENT
    | CARET
    | AND
    | OR
    | SHL
    | SHR
    ;

BINOPEQ : BINOP EQ ;

/* "Structural symbols" */

AT         : '@' ;
DOT        : '.' ;
DOTDOT     : '..' ;
DOTDOTDOT  : '...' ;
COMMA      : ',' ;
SEMI       : ';' ;
COLON      : ':' ;
MOD_SEP    : '::' ;
RARROW     : '->' ;
FAT_ARROW  : '=>' ;
LPAREN     : '(' ;
RPAREN     : ')' ;
LBRACKET   : '[' ;
RBRACKET   : ']' ;
LBRACE     : '{' ;
RBRACE     : '}' ;
POUND      : '#';
DOLLAR     : '$' ;
UNDERSCORE : '_' ;

// Literals

fragment HEXIT
  : [0-9a-fA-F]
  ;

fragment CHAR_ESCAPE
  : [nrt\\'"0]
  | [xX] HEXIT HEXIT
  | 'u' HEXIT HEXIT HEXIT HEXIT
  | 'U' HEXIT HEXIT HEXIT HEXIT HEXIT HEXIT HEXIT HEXIT
  | 'u{' HEXIT '}'
  | 'u{' HEXIT HEXIT '}'
  | 'u{' HEXIT HEXIT HEXIT '}'
  | 'u{' HEXIT HEXIT HEXIT HEXIT '}'
  | 'u{' HEXIT HEXIT HEXIT HEXIT HEXIT '}'
  | 'u{' HEXIT HEXIT HEXIT HEXIT HEXIT HEXIT '}'
  ;

fragment SUFFIX
  : IDENT
  ;

fragment INTEGER_SUFFIX
  : { _input.La(1) != 'e' && _input.La(1) != 'E' }? SUFFIX
  ;

LIT_CHAR
  : '\'' ( '\\' CHAR_ESCAPE
         | ~[\\'\n\t\r]
         | '\ud800' .. '\udbff' '\udc00' .. '\udfff'
         )
    ('\'' SUFFIX? | '\n'| '\r\n' | EOF)
  ;

LIT_BYTE
  : 'b\'' ( '\\' ( [xX] HEXIT HEXIT
                 | [nrt\\'"0] )
          | ~[\\'\n\t\r] '\udc00'..'\udfff'?
          )
    ('\'' SUFFIX? | '\n'| '\r\n' | EOF)
  ;

LIT_INTEGER

  : [0-9][0-9_]* INTEGER_SUFFIX?
  | '0b' [01_]+ INTEGER_SUFFIX?
  | '0o' [0-7_]+ INTEGER_SUFFIX?
  | '0x' [0-9a-fA-F_]+ INTEGER_SUFFIX?
  ;

LIT_FLOAT
  : [0-9][0-9_]* ('.' {
        /* dot followed by another dot is a range, not a float */
        _input.La(1) != '.' &&
        /* dot followed by an identifier is an integer with a function call, not a float */
        _input.La(1) != '_' &&
        !(_input.La(1) >= 'a' && _input.La(1) <= 'z') &&
        !(_input.La(1) >= 'A' && _input.La(1) <= 'Z')
  }? | ('.' [0-9][0-9_]*)? ([eE] [-+]? [0-9][0-9_]*)? SUFFIX?)
  ;

LIT_STR
  : '"' ('\\\n' | '\\\r\n' | '\\' CHAR_ESCAPE | .)*? ('"' SUFFIX? | '\n'| '\r\n' | EOF)
  ;

LIT_BINARY : 'b' LIT_STR ;
LIT_BINARY_RAW : 'b' LIT_STR_RAW ;

/* this is a bit messy */

fragment LIT_STR_RAW_INNER
  : '"' .*? '"'
  | LIT_STR_RAW_INNER2
  ;

fragment LIT_STR_RAW_INNER2
  : POUND LIT_STR_RAW_INNER POUND
  ;

LIT_STR_RAW
  : 'r' LIT_STR_RAW_INNER SUFFIX?
  ;


QUESTION : '?';

IDENT : XID_Start XID_Continue* ;

fragment QUESTION_IDENTIFIER : QUESTION? IDENT;

LIFETIME : '\'' IDENT ;

WHITESPACE : [ \r\n\t]+ ;

UNDOC_COMMENT     : '////' ~[\n]* -> type(COMMENT) ;
YESDOC_COMMENT    : '///' ~[\r\n]* -> type(DOC_COMMENT) ;
OUTER_DOC_COMMENT : '//!' ~[\r\n]* -> type(DOC_COMMENT) ;
LINE_COMMENT      : '//' ( ~[/\n] ~[\n]* )? -> type(COMMENT) ;

DOC_BLOCK_COMMENT
  : ('/**' ~[*] | '/*!') (DOC_BLOCK_COMMENT | .)*? ('*/' | '\n'| '\r\n'  | EOF)  -> type(DOC_BLOCK_COMMENT)
  ;

BLOCK_COMMENT : '/*' (BLOCK_COMMENT | .)*? ('*/' | '\n'| '\r\n' | EOF)  -> type(BLOCK_COMMENT) ;

/* these appear at the beginning of a file */

SHEBANG : '#!' { isAt(2) && _input.La(1) != '[' }? ~[\r\n]* -> type(SHEBANG) ;

UTF8_BOM : '\ufeff' { isAt(1) }? -> skip ;
