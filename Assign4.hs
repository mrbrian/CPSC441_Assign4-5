module Main where

-- Haskell module generated by the BNF converter

import Text.Show.Pretty 
import LexMp
import ParMp
import ErrM
import System.Environment
import AbsMp
import SkelMp
import AST
import SymbolTable
		
process :: M_prog -> ST
process (M_prog (ds, sts)) = st''
   where
     st   = new_scope L_PROG empty
     st'  = transDecls 0 st ds
     st'' = transStmts 0 st' sts

isVar :: M_decl -> Bool
isVar (M_var _) = True
isVar _ = False

transDecls :: Int -> ST -> [M_decl] -> ST
transDecls n st [] = st
transDecls n st decls = st''
     where 
        vs = filter (\a -> isVar a) decls
        fs = filter (\a -> not (isVar a)) decls
        (d:rest) = vs++fs
        st'    = transDecl n st d
        st''   = transDecls n st' rest

--   M_fun (String,[(String,Int,M_type)],M_type,[M_decl],[M_stmt]) ->
--   M_data (String,[(String,[M_type])]) ->
--   ARGUMENT (name, ty, val) -> insert n? (transDecl st d) : (transDecls rest)


transDecl :: Int -> ST -> M_decl -> ST
transDecl n st d = proc_d n st d
   where
     add_args n st [] = st
     add_args n st ((name, dim, typ):ps) = add_args n' st' ps
       where (n', st') = insert n st (ARGUMENT (name, typ, dim)) 
	 
     proc_d n st d = case d of
       M_var (name, arrSize, typ) -> st'
	     where (fn, st') = insert n st (VARIABLE (name, typ, length arrSize))     
       M_fun (name,pL,rT,ds,_) -> st''''
         where 
           (n', st') = insert (n+1) st (FUNCTION (name, [], rT))
           st'' = new_scope (L_FUN rT) st'
           st''' = add_args n' st'' pL
           st'''' = transDecls n' st''' ds

transStmts :: Int -> ST -> [M_stmt] -> ST
transStmts n st [] = st 
transStmts n st (s:rest) = st''
    where
       st'  = transStmt n st s
       st'' = transStmts n st' rest

transStmt :: Int -> ST -> M_stmt -> ST
transStmt n st d = case d of
--M_cond (M_expr, M_stmt,M_stmt) 
	M_cond (e, s1, s2) -> st''
           where 
              st' = transStmt n st s1
              st'' = transStmt n st' s2
	M_block (decls, stmts) -> st''
           where 
              st' = new_scope L_BLK st
              st''= transDecls n st' decls
	x -> st

{-	data M_stmt = M_ass (String,[M_expr], M_expr)
            | M_while (M_expr, M_stmt)
            | M_cond (M_expr, M_stmt,M_stmt) 
            | M_read (String, [M_expr])
            | M_print (M_expr)
            | M_return (M_expr)
            | M_block ([M_decl],[M_stmt])
-}
			
wf_exp :: M_expr -> ST -> Bool
wf_exp (M_ival v) _ = True
--wf_exp (M_rval v) _ = True
wf_exp (M_bval v) _ = True
--wf_exp (M_size (str, v)) _ = True
--wf_exp (M_id (str, es)) st = look_up str st
{- wf_exp (M_app (_, e)) st = v
  where
    map (\a -> wf_exp) 
	v = wf_exp -}
wf_exp _  _ = False

{-
            | M_rval Float
            | M_bval Bool
            | M_size (String,Int)
            | M_id (String,[M_expr])
            | M_app (M_operation,[M_expr])
			-}
main = do
    args <- getArgs
    conts <- readFile (args !! 0)
    let tok = tokens conts
    let ptree = pProg tok       
    putStrLn "The AST Tree:\n"
    case ptree of
        Ok  tree -> do
            let ast = transProg tree
            let st = process ast
            putStrLn $ ((ppShow ast) ++ "\n\n" ++ (ppShow st))
        Bad msg-> putStrLn msg
