module IR where

import AST
import SymbolTable

data I_prog = I_PROG ([I_fbody],Int,[(Int,[I_expr])],[I_stmt])
		-- functions, number of local variables, array descriptions, body.
data I_fbody = I_FUN (String,[I_fbody],Int,Int,[(Int,[I_expr])],[I_stmt])
		-- functions, number of local variables, number of arguments
		-- array descriptions, body
data I_stmt = I_ASS (Int,Int,[I_expr],I_expr)
		-- level, offset, array indexes, expressions
		| I_WHILE (I_expr,I_stmt)
		| I_COND (I_expr,I_stmt,I_stmt)
		-- | I_CASE (I_expr,[(Int,Int,I_stmt)])
		-- each case branch has a constructor number, a number of arguments,
		-- and the code statements
		| I_READ_B (Int,Int,[I_expr])
		-- level, offset, array indexes
		| I_PRINT_B I_expr
		| I_READ_I (Int,Int,[I_expr])
		| I_PRINT_I I_expr
		| I_READ_F (Int,Int,[I_expr])
		| I_PRINT_F I_expr
{-  M++
		| I_READ_C (Int,Int,[I_expr])
		| I_PRINT_C I_expr   -} 
		| I_RETURN I_expr
		| I_BLOCK ([I_fbody],Int,[(Int,[I_expr])],[I_stmt])
		-- functions, number of local variables, array descriptions, body.
data I_expr = I_IVAL Int
		| I_RVAL Float
		| I_BVAL Bool
		| I_CVAL Char
		| I_ID (Int,Int,[I_expr])
		-- level, offset, array indices
		| I_APP (I_opn,[I_expr])
		| I_REF (Int,Int)
		-- for passing an array reference as an argument
		-- of a function: level, offset
		| I_SIZE (Int,Int,Int)
		-- for retrieving the dimension of an array: level,offset,dimension
data I_opn = I_CALL (String,Int)
		-- label and level
		| I_CONS (Int,Int)
		-- constructor number and number of arguments
		| I_ADD_I | I_MUL_I | I_SUB_I | I_DIV_I | I_NEG_I
		| I_ADD_F | I_MUL_F | I_SUB_F | I_DIV_F | I_NEG_F
		| I_LT_I  | I_LE_I  | I_GT_I  | I_GE_I  | I_EQ_I
		| I_LT_F  | I_LE_F  | I_GT_F  | I_GE_F  | I_EQ_F
		| I_LT_C  | I_LE_C  | I_GT_C  | I_GE_C  | I_EQ_C
		| I_NOT | I_AND | I_OR | I_FLOAT | I_FLOOR | I_CEIL
		
--([I_fbody],Int,[(Int,[I_expr])],[I_stmt])


transProg :: M_prog -> I_prog
transProg (M_prog (ds, stmts)) = I_PROG (fs, nv, arrs, body)
	where
		st = transDecls ds -- ...  but what if it recurses?  take the tail
		Symbol_table (sctyp, nv, na, syms) = tail st
		fs = filter isFun syms
		arrs = filter isVar syms
		body = transStmts stmts  

transStmts :: Int -> [M_stmt] -> ST -> (Int, [I_stmt])
transStmts n stmts st = v
	where  
		v = map transStmt n stmts

transStmt :: Int -> M_stmt -> ST -> (Int, I_stmt)
transStmt n stmt st = case stmt of
	M_ass (name, arrs, exp) -> I_ASS (lvl, off, arrs', exp')
		where 
			(I_VARIABLE (lvl, off, _, _)) = look_up st name 
			arrs' = transExprs arrs
			exp' = transExpr exp		
	M_while (exp, stmt) -> I_WHILE (exp', stmt')
		where
			exp' = transExpr exp
			stmt' = transStmt stmt		
	M_cond (e, s1, s2) -> I_COND (e', s1', s2')
		where
			e' = transExpr e
			s1' = transStmt s1
			s2' = transStmt s2		
	M_read (name, arrs) -> (case typ of
			M_int  -> I_READ_I loc
			M_bool -> I_READ_B loc
			M_real -> I_READ_F loc)
		where
			(I_VARIABLE (lvl, off, typ, _)) = look_up st name
			arrs' = transExprs arrs
			loc = (lvl, off, arrs')
	M_print (e) -> (case e of 
		M_ival v -> I_PRINT_I v
		M_rval v -> I_PRINT_F v
		M_bval v -> I_PRINT_B v)	  
	M_return (e) -> I_RETURN e'
		where
			e' = transExpr e
	M_block (decls, stmts) -> I_BLOCK (fs', nv, vars, stmts')
		where  
			vs = filter isVar decls
			nv = length vs
			vars = transDecls n vs st
			fs = filter isFun decls
			(n', fs') = transDecls n fs st
			stmts' = transStmts n' stmts st
			
transDecls :: Int -> [M_decl] -> ST -> (Int, ST)
transDecls n [] st = (n, st)
transDecls n (d:ds) st = (n'', st'')
	where
		(n', st')   = transDecl n d st
		(n'', st'') = transDecls n' ds st'

transDecl :: Int -> M_decl -> ST -> (Int, ST)
transDecl n d st = (n', st')
	where
		(n', st') = case d of 
			M_var (vn, vd, vt) -> insert n st (VARIABLE (vn, vt, vd'))
				where 
					vd' = length vd
			M_fun (fn, fps, frt, fds, fstmts) -> insert (n+1) st (FUNCTION (fn, fps', frt))
				where 
					fps' = map (\(aN, aD, aT) -> (aT, aD)) fps

transExprs :: [M_expr] -> ST -> [I_expr]
transExprs (e:es) st = ies
	where		
		ies = (transExpr e st):(transExprs es st)

transExpr :: M_expr -> ST -> I_expr
transExpr e st = case e of
	M_ival v -> I_IVAL (fromIntegral v) 
	M_rval v -> I_RVAL v 
	M_bval v -> I_BVAL v 
	M_size (str, dim) -> I_SIZE (lvl, off, dim)
		where 
			(I_VARIABLE (lvl, off, _, dim)) = look_up st str
	M_id (str, es) -> I_ID (lvl, off, es')
		where
			(I_VARIABLE (lvl, off, _, dim)) = look_up st str
			es' = transExprs es st
	--M_app (op, es)  -> I_REF (op', es')   what about this one
	M_app (op, ess) -> I_APP (op', ess')
		where
			(e:es) = ess
			op' = transOper op e st
			ess' = transExprs (ess) st

transOper :: M_operation -> M_expr -> ST -> I_opn
transOper op e st = case op of
	M_fn str ->  I_CALL	(label, lvl)
		where (I_FUNCTION (lvl, label, _, _)) = look_up st str
		--  | I_CONS (Int,Int)  m++
	M_add    -> (case e of 
		M_ival v -> I_ADD_I
		M_rval v -> I_ADD_F)
	M_mul    -> (case e of 
		M_ival v -> I_MUL_I
		M_rval v -> I_MUL_F)
	M_sub    -> (case e of
		M_ival v -> I_SUB_I
		M_rval v -> I_SUB_F)
	M_div    -> (case e of
		M_ival v -> I_DIV_I
		M_rval v -> I_DIV_F)
	M_neg    -> (case e of
		M_ival v -> I_DIV_I
		M_rval v -> I_DIV_F)
	M_lt     -> (case e of
		M_ival v -> I_LT_I
		M_rval v -> I_LT_F)
	M_le     -> (case e of
		M_ival v -> I_LE_I
		M_rval v -> I_LE_F)
	M_gt     -> (case e of
		M_ival v -> I_GT_I
		M_rval v -> I_GT_F)
	M_ge     -> (case e of
		M_ival v -> I_GE_I
		M_rval v -> I_GE_F)
	M_eq     -> (case e of
		M_ival v -> I_EQ_I
		M_rval v -> I_EQ_F)
	M_not    -> I_NOT
	M_and    -> I_AND
	M_or     -> I_OR
	M_float  -> I_FLOAT
	M_floor  -> I_FLOOR
	M_ceil   -> I_CEIL
				 
		 
		 
		 
		
		
		 
		 
		 
		 
		
		  
		  
		  
		 
		
		 
		 
		
		
	



