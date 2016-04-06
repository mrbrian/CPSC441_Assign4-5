module Semantic where

import AST
import SymbolTable
import IR

same_type :: ST -> String -> M_expr -> Bool
same_type st name expr = v
	where
		sym_i_desc1 = look_up st name
		type1 = get_type_sid sym_i_desc1		
		type2 = get_type_expr st expr
		
		v1 = checkExpr expr st
		v2 = type1 == type2
		v = v1 && v2

get_type :: M_expr -> ST -> M_type
get_type e st = case e of
	M_ival _ -> M_int
	M_rval _ -> M_real
	M_bval _ -> M_bool
	M_size (str, x) -> M_int
	M_id (str,exs) -> t
		where
			I_VARIABLE (_,_,t,_) = look_up st str
	M_app (op, e:exs) -> get_type e st

all_same_type :: ST -> [M_expr] -> Bool
all_same_type st [] = True
all_same_type st (e:exs) = (case not_same of
		[] -> True
		_ -> False)
	where
		t1 = get_type e st
		not_same = [x | x <- exs, not ((get_type x st) == t1)]		
		
are_ints :: ST -> [M_expr] -> Bool
are_ints st exs = (case not_ints of
	[] -> True
	_ -> False)
	where
		not_ints = [ x | x <- exs, not (is_int st x)]
		
is_int :: ST -> M_expr -> Bool
is_int st e = case e of
	M_ival _ -> True
	M_rval _ -> False
	M_bval _ -> False
	M_size (str, x) -> True
	M_id (str,exs) -> are_ints st exs 
	M_app (_, exs) -> are_ints st exs	

checkExpr :: M_expr -> ST -> Bool
checkExpr exp st = case exp of 
			M_ival _ -> True
			M_rval _ -> True
			M_bval _ -> True
			M_size (str, x) -> True
			M_id (str,exs) -> are_ints st exs					
			M_app (_, exs) -> all_same_type st exs
		
checkProg :: M_prog -> Bool
checkProg (M_prog (decls, stmts)) = v
   where
	 st = new_scope L_PROG []
	 (n, st1, v1) = checkDecls decls (1, st)	
	 v2 = checkStmts stmts (n,st1)
	 v = v1 && v2

checkDecls :: [M_decl] -> (Int, ST) -> (Int, ST, Bool)
checkDecls [] (n,st) = (n, st, True)
checkDecls (decl:decls) (n,st) = (n2,st2,v)
     where 
		(n1,st1,v1) = checkDecl decl (n,st)
		(n2,st2,v2) = checkDecls decls (n1,st1)
		v = v1 && v2
		
checkDecl :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkDecl decl (n,st) = case decl of 
	M_var _ -> checkVar decl (n,st)
	M_fun _ -> checkFun decl (n,st)
	
checkVar :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkVar (M_var (name, arr_exprs, typ)) (n, st) = (n', st', v)
	where		
		v = are_ints st arr_exprs
		dim = length arr_exprs
		(n', st') = insert n st (VARIABLE (name, typ, dim))		
					 
insert_args :: [(String, Int, M_type)] -> (Int, ST) -> (Int, ST)
insert_args [] (n,st) = (n, st)
insert_args (a:rest) (n,st) = (n'', st'')
	where
		(n', st') = insert_arg a (n,st)
		(n'', st'') = insert_args rest (n',st')

insert_arg :: (String, Int, M_type) -> (Int, ST) -> (Int, ST)
insert_arg (name, dim, typ) (n,st) = (n', st')
	where
		(n', st') = insert n st (ARGUMENT (name, typ, dim))

checkFun :: M_decl -> (Int, ST) -> (Int, ST, Bool)
checkFun (M_fun (name, args, ret_type, decls, stmts)) (n, st) = (n2, st4, v)
	where		
		sym_args = map (\(nam, dim, typ) -> (typ, dim)) args
		(n1, st1) = insert n st (FUNCTION (name, sym_args, ret_type))
		
		st2 = new_scope (L_FUN ret_type) st1
		
		(st3,v1) = checkArgs n1 st2 args
		(n2, st4, v2) = checkDecls decls (n1,st3) 
		v3 = checkStmts stmts (n2,st4) 
		v = v1 && v2 && v3 
		
	
checkArgs :: Int -> ST -> [(String,Int,M_type)] -> (ST, Bool)
checkArgs n st [] = (st, True)
checkArgs n st (arg:rest) = (st'',v)
	where
		(st',v1) = checkArg n st arg
		(st'',v2) = checkArgs n st' rest
		v = v1 && v2
		
checkArg :: Int -> ST -> (String,Int,M_type) -> (ST, Bool)
checkArg n st (name, dim, typ) = (st', True)
	where
		(n, st') = insert n st (ARGUMENT (name, typ, dim))
		
checkStmts :: [M_stmt] -> (Int,ST) -> Bool
checkStmts [] (n,st) = True
checkStmts (stmt:rest) (n,st) = v
	where
		(n1, st1, v1) = checkStmt stmt (n,st)
		v2 = checkStmts rest (n1,st1)
		v = v1 && v2
			
checkStmt :: M_stmt -> (Int,ST) -> (Int, ST, Bool)
checkStmt stmt (n,st) = case stmt of
	M_ass (name, arrs, exp) -> (n,st, v)
		where 	
			(I_VARIABLE (lvl, off, _, _)) = look_up st name 
			arrs' = transExprs arrs st
			exp' = transExpr exp st	
			v = same_type st name exp
	M_while (exp, stmt) -> (n',st', exp' && stmt')
		where
			exp' = checkExpr exp st
			(n',st',stmt') = checkStmt stmt (n,st)	
	M_cond (e, s1, s2) -> (n'', st'', e' && s1' && s2')
		where
			e' = checkExpr e st
			(n',st', s1')   = checkStmt s1 (n,st)
			(n'', st'', s2') = checkStmt s2 (n',st')
	M_read (name, arrs) -> (case typ of
			M_int  -> (n,st, True)
			M_bool -> (n,st, True)
			M_real -> (n,st, True))
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs st
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> (n,st, True)
		M_rval v -> (n,st, True)
		M_bval v -> (n,st, True)	 
		M_size v -> (n,st, True)	 
		M_app v  -> (n,st, (checkExpr e st))
		M_id (v, exs)  -> (n,st, (are_ints st exs)))
	M_block (decls, stmts) -> (n', st', v)
		where  
			(n', st', v1) = checkDecls decls (n,st)
			v2 = checkStmts stmts (n',st')
			v = v1 && v2
	M_return e -> (n,st, e')
		where
			e' = checkExpr e st
		
				
				