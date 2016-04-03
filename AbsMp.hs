

module AbsMp where

-- Haskell module generated by the BNF converter




newtype Ident = Ident String deriving (Eq, Ord, Show, Read)
newtype Ival = Ival String deriving (Eq, Ord, Show, Read)
newtype Rval = Rval String deriving (Eq, Ord, Show, Read)
data Prog = ProgBlock Block
  deriving (Eq, Ord, Show, Read)

data Block = Block1 Declarations Program_body
  deriving (Eq, Ord, Show, Read)

data Declarations
    = Declarations1 Declaration Declarations | Declarations2
  deriving (Eq, Ord, Show, Read)

data Declaration
    = DeclarationVar_declaration Var_declaration
    | DeclarationFun_declaration Fun_declaration
  deriving (Eq, Ord, Show, Read)

data Var_declaration = Var_declaration1 Ident Array_dimensions Type
  deriving (Eq, Ord, Show, Read)

data Type = Type_int | Type_real | Type_bool
  deriving (Eq, Ord, Show, Read)

data Array_dimensions
    = Array_dimensions1 Expr Array_dimensions | Array_dimensions2
  deriving (Eq, Ord, Show, Read)

data Fun_declaration
    = Fun_declaration1 Ident Param_list Type Fun_block
  deriving (Eq, Ord, Show, Read)

data Fun_block = Fun_block1 Declarations Fun_body
  deriving (Eq, Ord, Show, Read)

data Param_list = Param_list1 Parameters
  deriving (Eq, Ord, Show, Read)

data Parameters
    = Parameters1 Basic_declaration More_parameters | Parameters2
  deriving (Eq, Ord, Show, Read)

data More_parameters
    = More_parameters1 Basic_declaration More_parameters
    | More_parameters2
  deriving (Eq, Ord, Show, Read)

data Basic_declaration
    = Basic_declaration1 Ident Basic_array_dimensions Type
  deriving (Eq, Ord, Show, Read)

data Basic_array_dimensions
    = Basic_array_dimensions1 Basic_array_dimensions
    | Basic_array_dimensions2
  deriving (Eq, Ord, Show, Read)

data Program_body = Program_body1 Prog_stmts
  deriving (Eq, Ord, Show, Read)

data Fun_body = Fun_body1 Prog_stmts Expr
  deriving (Eq, Ord, Show, Read)

data Prog_stmts = Prog_stmts1 Prog_stmt Prog_stmts | Prog_stmts2
  deriving (Eq, Ord, Show, Read)

data Prog_stmt
    = Prog_stmt1 Expr Prog_stmt Prog_stmt
    | Prog_stmt2 Expr Prog_stmt
    | Prog_stmt3 Identifier
    | Prog_stmt4 Identifier Expr
    | Prog_stmt5 Expr
    | Prog_stmt6 Block
  deriving (Eq, Ord, Show, Read)

data Identifier = Identifier1 Ident Array_dimensions
  deriving (Eq, Ord, Show, Read)

data Expr = Expr1 Expr Bint_term | ExprBint_term Bint_term
  deriving (Eq, Ord, Show, Read)

data Bint_term
    = Bint_term1 Bint_term Bint_factor
    | Bint_termBint_factor Bint_factor
  deriving (Eq, Ord, Show, Read)

data Bint_factor
    = Bint_factor1 Bint_factor
    | Bint_factor2 Int_expr Compare_op Int_expr
    | Bint_factorInt_expr Int_expr
  deriving (Eq, Ord, Show, Read)

data Compare_op
    = Compare_op1
    | Compare_op2
    | Compare_op3
    | Compare_op4
    | Compare_op5
  deriving (Eq, Ord, Show, Read)

data Int_expr
    = Int_expr1 Int_expr Addop Int_term | Int_exprInt_term Int_term
  deriving (Eq, Ord, Show, Read)

data Addop = Addop1 | Addop2
  deriving (Eq, Ord, Show, Read)

data Int_term
    = Int_term1 Int_term Mulop Int_factor
    | Int_termInt_factor Int_factor
  deriving (Eq, Ord, Show, Read)

data Mulop = Mulop1 | Mulop2
  deriving (Eq, Ord, Show, Read)

data Int_factor
    = Int_factor1 Expr
    | Int_factor2 Ident Basic_array_dimensions
    | Int_factor3 Expr
    | Int_factor4 Expr
    | Int_factor5 Expr
    | Int_factor6 Ident Modifier_list
    | Int_factorIval Ival
    | Int_factorRval Rval
    | Int_factorBval Bval
    | Int_factor7 Int_factor
  deriving (Eq, Ord, Show, Read)

data Modifier_list
    = Modifier_list1 Arguments
    | Modifier_listArray_dimensions Array_dimensions
  deriving (Eq, Ord, Show, Read)

data Arguments = Arguments1 Expr More_arguments | Arguments2
  deriving (Eq, Ord, Show, Read)

data More_arguments
    = More_arguments1 Expr More_arguments | More_arguments2
  deriving (Eq, Ord, Show, Read)

data Bval = Bval_true | Bval_false
  deriving (Eq, Ord, Show, Read)
