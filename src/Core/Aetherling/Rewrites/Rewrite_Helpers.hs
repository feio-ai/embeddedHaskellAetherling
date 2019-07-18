module Aetherling.Rewrites.Rewrite_Helpers where
import Control.Monad.Except
import Control.Monad.Identity
import System.IO

type Rewrite_StateM = Except Rewrite_Failure

type Rewrite_IO_StateM = ExceptT Rewrite_Failure IO

data Rewrite_Failure = Expr_Failure {rw_msg :: String}
                     | Type_Failure {rw_msg :: String}
                     | Value_Failure {rw_msg :: String}
                     | Input_Failure {rw_msg :: String}
                     | Module_Failure {rw_msg :: String}
                     | Slowdown_Failure {rw_msg :: String}
  deriving (Eq, Show)
