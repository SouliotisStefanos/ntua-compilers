#include "error.h"
#include "symbol.h"
#include <string>
#include <iostream>

void ERROR (const char * fmt, ...);

inline std::ostream& operator<<(std::ostream &out, Type t) {
  switch (t) {
  case TYPE_INTEGER: out << "int"; break;
  case TYPE_BOOLEAN: out << "bool"; break;
  case TYPE_REAL: out << "real"; break;
  case TYPE_ARRAY: out << "array known length"; break;
  case TYPE_IARRAY: out << "array unknown length"; break;
  }
  return out;
}

class AST {
public:
  virtual ~AST() {}
  virtual void printOn(std::ostream &out) const = 0;
  virtual void sem() {}
};

inline std::ostream& operator<<(std::ostream &out, const AST &t) {
  t.printOn(out);
  return out;
}

class Expr: public AST {
public:
  virtual int eval() const = 0;
  bool type_check(Type t) {
    sem();
    if (type != t) {
      return 0;
    }
    else{
      return 1;
    }
  }
  Type type;
};


class BinOp: public Expr {
public:
  BinOp(Expr *l, std::string o, Expr *r): left(l), op(o), right(r) {}
  ~BinOp() { delete left; delete right; }
  virtual void printOn(std::ostream &out) const override {
    out << op << "(" << *left << ", " << *right << ")";
  }
  virtual bool check_number(Expr *left, Expr *right){
    return ((left->type_check(TYPE_REAL) && right->type_check(TYPE_INTEGER))||(left->type_check(TYPE_INTEGER) && right->type_check(TYPE_REAL))||(left->type_check(TYPE_REAL) && right->type_check(TYPE_REAL))||(left->type_check(TYPE_INTEGER) && right->type_check(TYPE_INTEGER)));
  }
  virtual void sem() override {
    if(! op.compare("+") || ! op.compare("*") || ! op.compare("-")){
      if( left->type_check(TYPE_INTEGER) && right->type_check(TYPE_INTEGER)){
        type = TYPE_INTEGER;
      }
      else if(left->type_check(TYPE_REAL) || right->type_check(TYPE_REAL)){
        type = TYPE_REAL;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
    if(! op.compare("/")){
      if(check_number(left, right)){
        type = TYPE_REAL;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
    if(! op.compare("mod") || ! op.compare("div")){
      if( left->type_check(TYPE_INTEGER) && right->type_check(TYPE_INTEGER)){
        type = TYPE_INTEGER;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
    if(! op.compare("=") || ! op.compare("<>")){
      if(check_number(left, right) || ((left->type == right->type) && (!left->type_check(TYPE_ARRAY) || !left->type_check(TYPE_IARRAY)))){
        type = TYPE_BOOLEAN;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
    if(! op.compare("<") || ! op.compare(">") || ! op.compare("<=") || ! op.compare(">=")){
      if(check_number(left, right)){
        type = TYPE_BOOLEAN;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
    if(! op.compare("or") || ! op.compare("and")){
      if(left->type_check(TYPE_BOOLEAN) && right->type_check(TYPE_BOOLEAN)){
        type = TYPE_BOOLEAN;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
  }
  virtual int eval() const override {
    if(! op.compare("+")) return left->eval() + right->eval();
    if(! op.compare("-")) return left->eval() - right->eval();
    if(! op.compare("*")) return left->eval() * right->eval();
    if(! op.compare("/")) return left->eval() / right->eval();
    if(! op.compare("=")) return left->eval() == right->eval();
    if(! op.compare("<")) return left->eval() < right->eval();
    if(! op.compare(">")) return left->eval() > right->eval();
    if(! op.compare("<=")) return left->eval() <= right->eval();
    if(! op.compare(">=")) return left->eval() >= right->eval();
    if(! op.compare("<>")) return left->eval() != right->eval();
    if(! op.compare("div")) return left->eval() / right->eval();
    if(! op.compare("mod")) return left->eval() % right->eval();
    if(! op.compare("or")) return left->eval() || right->eval();
    if(! op.compare("and")) return left->eval() && right->eval();
    return 0;  // this will never be reached.
  }
private:
  Expr *left;
  std::string op;
  Expr *right;
};


class UnOp: public Expr {
public:
  UnOp(std::string o, Expr *r): op(o), right(r) {}
  ~UnOp() { delete right; }
  virtual void printOn(std::ostream &out) const override {
    out << op << "(" << *right << ")";
  }
  virtual void sem() override {
    if(! op.compare("+") || ! op.compare("-")){
      if(right->type_check(TYPE_INTEGER) || right->type_check(TYPE_REAL)){
        type = right->type;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
    if( ! op.compare("not")){
      if(right->type_check(TYPE_BOOLEAN)){
        type = TYPE_BOOLEAN;
      }
      else{
        ERROR("Type mismatch!"); exit(1);
      }
    }
  }
  virtual int eval() const override {
    if(! op.compare("+")) return  right->eval();
    if(! op.compare("-")) return -right->eval();
    if(! op.compare("not")) return !right->eval();
    return 0;  // this will never be reached.
  }
private:
  std::string op;
  Expr *right;
};
