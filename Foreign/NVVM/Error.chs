{-# LANGUAGE BangPatterns #-}
--------------------------------------------------------------------------------
-- |
-- Module    : Foreign.NVVM.Error
-- Copyright : [2016] Trevor L. McDonell
-- License   : BSD
--
-- Error handling
--
--------------------------------------------------------------------------------

module Foreign.NVVM.Error (

  Status(..),
  describe,
  resultIfOk, nothingIfOk,
  nvvmError, nvvmErrorIO,

) where

import Foreign.NVVM.Internal.C2HS
import Foreign.C.String

import Control.Exception


#include "cbits/stubs.h"
{# context lib="nvvm" #}


-- Return codes
-- ------------

-- | NVVM API function return code
--
{# enum nvvmResult as Status
  { underscoreToCase
  , NVVM_SUCCESS                   as Success
  , NVVM_ERROR_IR_VERSION_MISMATCH as IRVersionMismatch
  , NVVM_ERROR_INVALID_IR          as InvalidIR
  }
  with prefix="NVVM_ERROR" deriving (Eq, Show) #}


-- | Get the descriptive message string for the given result code
--
{#
  fun pure unsafe nvvmGetErrorString as describe
    { cFromEnum `Status'
    }
    -> `String' peekCString*
#}


-- Exceptions
-- ----------

data NVVMException
  = ExitCode Status
  | UserError String

instance Exception NVVMException

instance Show NVVMException where
  showsPrec _ (ExitCode  s) = showString ("NVVM Exception: " ++ describe s)
  showsPrec _ (UserError s) = showString ("NVVM Exception: " ++ s)


-- | Throw an exception. Exceptions may be thrown from pure code, but can only
-- be caught in the 'IO' monad.
--
nvvmError :: String -> a
nvvmError s = throw (UserError s)

-- | Raise an NVVM exception in the 'IO' monad
--
nvvmErrorIO :: String -> IO a
nvvmErrorIO s = throwIO (UserError s)


-- Helper functions
-- ----------------

-- | Return the result of a function on successful execution, otherwise throw an
-- exception.
--
{-# INLINE resultIfOk #-}
resultIfOk :: (Status, a) -> IO a
resultIfOk (status, result) =
  case status of
    Success -> return $! result
    _       -> throwIO (ExitCode status)

-- | Throw an exception on an unsuccessful return code
--
{-# INLINE nothingIfOk #-}
nothingIfOk :: Status -> IO ()
nothingIfOk status =
  case status of
    Success -> return ()
    _       -> throwIO (ExitCode status)
