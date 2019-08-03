%{
  #include <cstdio>
  #include <string>
  #include "../semantic/ast.hpp"
  #include "../lexer/lexer.hpp"

  SymbolTable st;
  std::vector<int> rt_stack;
  #define DEBUG true
%}

%define parse.error verbose
%verbose
%define parse.trace


%token T_and          "and"
%token T_array        "array"
%token T_begin        "begin"
%token T_boolean      "boolean"
%token T_char         "char"
%token T_dispose      "dispose"
%token T_div          "div"
%token T_do           "do"
%token T_else         "else"
%token T_end          "end"
%token T_false        "false"
%token T_forward      "forward"
%token T_function     "function"
%token T_goto         "goto"
%token T_if           "if"
%token T_integer      "integer"
%token T_label        "label"
%token T_mod          "mod"
%token T_new          "new"
%token T_nil          "nil"
%token T_not          "not"
%token T_of           "of"
%token T_or           "or"
%token T_procedure    "procedure"
%token T_program      "program"
%token T_real         "real"
%token T_result       "result"
%token T_return       "return"
%token T_then         "then"
%token T_true         "true"
%token T_var          "var"
%token T_while        "while"

%token T_op_eq "="
%token T_op_g ">"
%token T_op_l "<"
%token T_op_neq "<>"
%token T_op_leq "<="
%token T_op_geq ">="
%token T_op_p "+"
%token T_op_m "-"
%token T_op_mul "*"
%token T_op_d "/"
%token T_op_point "^"
%token T_op_addr "@"

%token T_op_assign ":="
%token T_op_semicol ";"
%token T_op_dot "."
%token T_op_lpar "("
%token T_op_rpar ")"
%token T_op_col ":"
%token T_op_com ","
%token T_op_lbr "["
%token T_op_rbr "]"

%token T_int_const
%token T_real_const
%token T_const_char
%token T_const_string
%token<sval> T_id

/*operators*/
%left<op> "+" "-" "="
%left<op> "*" "div" "mod" "or"
%left<op> "(" ")" "[" "]" "<=" ">=" "<" ">" "<>" "and" "/" "not"
%right<op>  "@" "^"

%expect 1

%union {
  Body *body;
  Local *local;
  Block *block;
  Header *header;
  Label *label;
  Id_list *id_list;
  Decl *decl;
  Decl_list *decl_list;
  Formal *formal;
  Formal_list *formal_list;
  Stmt *stmt;
  Stmt_list *stmt_list;
  Constint *constint;
  Constchar *constchar;
  Constreal *constreal;
  Conststring *conststring;
  Expr *expr;
  Expr_list *expr_list;
  Call *call;


  Type *type;
  Rval *rval;
  Lval *lval;
  int num;
  double re;
  char var;
  char *op;

  std::string* sval;
}

%type<body>  body local_list
%type<block>  block
%type<local>  local
%type<header>  header
%type<label>  decl_label
%type<id_list> id_list
%type<decl_list> decl_list
%type<decl> decl
%type<formal_list> formal_list
%type<formal> formal
%type<stmt>  stmt
%type<stmt_list> stmt_list
%type<expr_list> expr_list
%type<call> call


%type<expr>  expr
%type<type>  type
%type<rval>  r-value
%type<lval>  l-value
%type<constint>    T_int_const
%type<constchar>    T_const_char
%type<constreal>    T_real_const
%type<conststring>    T_const_string

%%

program:
  "program" T_id ";" body "."{
    //$4->sem();
    // std::cout << "AST: " << *$1 << std::endl;
    //$1->run();
  }
  ;

body:
  /*nothing*/ { $$ = new Body(); }
|local_list block { $1->merge($2); $$ = $1; if(DEBUG) $$->printOn(std::cout); }
  ;

local_list:
  /*nothing*/ { $$ = new Body(); }
  |local_list local { $1->append_local($2); $$ = $1; if(DEBUG) $$->printOn(std::cout); }
  ;

local:
 "var" decl_list { $$ = new Local($2); }
 | "label" decl_label { $$ = new Local($2); }
 | header ";" body ";" { $$ = new Local($1, $3); }
 | "forward" header ";" { $$ = new Local($2); }
 ;

decl_label:
  T_id id_list ";" { $2->append_id($1); $$ = new Label($2); }
  ;


id_list:
  /*nothing*/ { $$ = new Id_list(); }
  | id_list "," T_id { $1->append_id($3); $$ = $1; }
  ;

decl_list:
  decl { $$ = new Decl_list(); $$->append_decl($1);}
  | decl_list decl { $1->append_decl($2); $$ = $1; }
  ;

decl:
  T_id id_list ":" type ";" { $2->append_id($1); $$ = new Decl($2, $4);}

header:
 "procedure" T_id "(" formal formal_list  ")" { $5->append_formal($4); $$ = new Procedure($2, $5); }
 | "procedure" T_id "(" ")" { $$ = new Procedure($2); }
 | "function" T_id "(" formal formal_list  ")" ":" type { $5->append_formal($4); $$ = new Function($2, $8, $5); }
 | "function" T_id "(" ")" ":" type { $$ = new Function($2, $6); }
 ;

formal_list:
  /*nothing*/ { $$ = new Formal_list(); }
  | formal_list ";" formal { $1->append_formal($3); $$ = $1; }
  ;

formal:
  "var" T_id  id_list ":" type { $3->append_id($2); $$ = new Formal($3, $5); }
  |T_id  id_list ":" type { $2->append_id($1); $$ = new Formal($2, $4); }
  ;

type:
 "integer" { $$ = new Integer(); }
 | "real" { $$ = new Real(); }
 | "boolean" { $$ = new Boolean(); }
 | "char" { $$ = new Char(); }
 | "array" "[" T_int_const "]" "of" type { $$ = new Array($6, $3); }
 | "array" "of" type { $$ = new Array($3); }
 | "^" type { $$ = new Pointer($2); }
 ;

block:
  "begin" stmt stmt_list "end" { $3->append_stmt($2); $$ = new Block($3); }
  ;

stmt_list:
  /*nothing*/ { $$ = new Stmt_list(); }
  | stmt_list ";" stmt { $1->append_stmt($3); $$ = $1; }
  ;

stmt:
  /*nothing*/
  | l-value ":=" expr
  | expr "^" ":=" expr
  | block
  | call
  | "if" expr "then" stmt
  | "if" expr "then" stmt "else" stmt
  | "while" expr "do" stmt
  | T_id ":" stmt
  | "goto" T_id
  | "return"
  | "new" "[" expr "]" l-value
  | "new" "[" expr "]" expr "^"
  | "new" l-value
  | "new" expr "^"
  | "dispose" "[" "]" l-value
  | "dispose" "[" "]" expr "^"
  | "dispose" l-value
  | "dispose" expr "^"
  ;

expr:
 l-value
 | r-value
 ;

l-value:
 T_id
 | "result"
 | T_const_string
 | l-value "[" expr "]"
 | "(" l-value ")"
 ;


r-value:
 T_int_const
 | "true"
 | "false"
 | T_real_const
 | T_const_char
 | "(" r-value ")"
 | "nil"
 | call
 | "@" l-value
 | "not" expr
 | "+" expr
 | "-" expr
 | expr "+" expr
 | expr "-" expr
 | expr "*" expr
 | expr "/" expr
 | expr "div" expr
 | expr "mod" expr
 | expr "or" expr
 | expr "and" expr
 | expr "=" expr
 | expr "<>" expr
 | expr "<" expr
 | expr "<=" expr
 | expr ">" expr
 | expr ">=" expr
 ;

call:
  T_id "(" expr  expr_list  ")" { $4->append_expr($3); $$ = new Call($1, $4); }
  |T_id "(" ")" { $$ = new Call($1); }
  ;

expr_list:
  /*nothing*/ { $$ = new Expr_list(); }
  | expr_list "," expr { $1->append_expr($3); $$ = $1; }
  ;



%%

int main() {
  int result = yyparse();
  if (result == 0) printf("Success.\n");
  return result;
}
