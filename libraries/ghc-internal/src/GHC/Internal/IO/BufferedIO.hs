{-# LANGUAGE Trustworthy #-}
{-# LANGUAGE NoImplicitPrelude #-}
{-# OPTIONS_GHC -funbox-strict-fields #-}

-----------------------------------------------------------------------------
-- |
-- Module      :  GHC.Internal.IO.BufferedIO
-- Copyright   :  (c) The University of Glasgow 2008
-- License     :  see libraries/base/LICENSE
--
-- Maintainer  :  ghc-devs@haskell.org
-- Stability   :  internal
-- Portability :  non-portable (GHC Extensions)
--
-- Class of buffered IO devices
--
-----------------------------------------------------------------------------

module GHC.Internal.IO.BufferedIO (
        BufferedIO(..),
        readBuf, readBufNonBlocking, writeBuf, writeBufNonBlocking
    ) where

import GHC.Internal.Base
import GHC.Internal.Ptr
import GHC.Internal.Word
import GHC.Internal.Num
import GHC.Internal.IO.Device as IODevice
import GHC.Internal.IO.Device as RawIO
import GHC.Internal.IO.Buffer

-- | The purpose of 'BufferedIO' is to provide a common interface for I/O
-- devices that can read and write data through a buffer.  Devices that
-- implement 'BufferedIO' include ordinary files, memory-mapped files,
-- and bytestrings.  The underlying device implementing a 'System.IO.Handle'
-- must provide 'BufferedIO'.
--
class BufferedIO dev where
  -- | allocate a new buffer.  The size of the buffer is at the
  -- discretion of the device; e.g. for a memory-mapped file the
  -- buffer will probably cover the entire file.
  newBuffer         :: dev -> BufferState -> IO (Buffer Word8)

  -- | reads bytes into the buffer, blocking if there are no bytes
  -- available.  Returns the number of bytes read (zero indicates
  -- end-of-file), and the new buffer.
  fillReadBuffer    :: dev -> Buffer Word8 -> IO (Int, Buffer Word8)

  -- | reads bytes into the buffer without blocking.  Returns the
  -- number of bytes read (Nothing indicates end-of-file), and the new
  -- buffer.
  fillReadBuffer0   :: dev -> Buffer Word8 -> IO (Maybe Int, Buffer Word8)

  -- | Prepares an empty write buffer.  This lets the device decide
  -- how to set up a write buffer: the buffer may need to point to a
  -- specific location in memory, for example.  This is typically used
  -- by the client when switching from reading to writing on a
  -- buffered read/write device.
  --
  -- There is no corresponding operation for read buffers, because before
  -- reading the client will always call 'fillReadBuffer'.
  emptyWriteBuffer  :: dev -> Buffer Word8 -> IO (Buffer Word8)
  emptyWriteBuffer _dev buf
    = return buf{ bufL=0, bufR=0, bufState = WriteBuffer }

  -- | Flush all the data from the supplied write buffer out to the device.
  -- The returned buffer should be empty, and ready for writing.
  flushWriteBuffer  :: dev -> Buffer Word8 -> IO (Buffer Word8)

  -- | Flush data from the supplied write buffer out to the device
  -- without blocking.  Returns the number of bytes written and the
  -- remaining buffer.
  flushWriteBuffer0 :: dev -> Buffer Word8 -> IO (Int, Buffer Word8)

-- for an I/O device, these operations will perform reading/writing
-- to/from the device.

-- for a memory-mapped file, the buffer will be the whole file in
-- memory.  fillReadBuffer sets the pointers to encompass the whole
-- file, and flushWriteBuffer needs to do no I/O.  A memory-mapped
-- file has to maintain its own file pointer.

-- for a bytestring, again the buffer should match the bytestring in
-- memory.

-- ---------------------------------------------------------------------------
-- Low-level read/write to/from buffers

-- These operations make it easy to implement an instance of 'BufferedIO'
-- for an object that supports 'RawIO'.

readBuf :: RawIO dev => dev -> Buffer Word8 -> IO (Int, Buffer Word8)
readBuf dev bbuf = do
  let bytes = bufferAvailable bbuf
  let offset = bufferOffset bbuf
  res <- withBuffer bbuf $ \ptr ->
             RawIO.read dev (ptr `plusPtr` bufR bbuf) offset bytes
  let bbuf' = bufferAddOffset res bbuf
  return (res, bbuf'{ bufR = bufR bbuf' + res })
         -- zero indicates end of file

readBufNonBlocking :: RawIO dev => dev -> Buffer Word8
                     -> IO (Maybe Int,   -- Nothing ==> end of file
                                         -- Just n  ==> n bytes were read (n>=0)
                            Buffer Word8)
readBufNonBlocking dev bbuf = do
  let bytes = bufferAvailable bbuf
  let offset = bufferOffset bbuf
  res <- withBuffer bbuf $ \ptr ->
           IODevice.readNonBlocking dev (ptr `plusPtr` bufR bbuf) offset bytes
  case res of
     Nothing -> return (Nothing, bbuf)
     Just n  -> do let bbuf' = bufferAddOffset n bbuf
                   return (Just n, bbuf'{ bufR = bufR bbuf' + n })

writeBuf :: RawIO dev => dev -> Buffer Word8 -> IO (Buffer Word8)
writeBuf dev bbuf = do
  let bytes = bufferElems bbuf
  let offset = bufferOffset bbuf
  withBuffer bbuf $ \ptr ->
      IODevice.write dev (ptr `plusPtr` bufL bbuf) offset bytes
  let bbuf' = bufferAddOffset bytes bbuf
  return bbuf'{ bufL=0, bufR=0 }

-- XXX ToDo
writeBufNonBlocking :: RawIO dev => dev -> Buffer Word8 -> IO (Int, Buffer Word8)
writeBufNonBlocking dev bbuf = do
  let bytes = bufferElems bbuf
  let offset = bufferOffset bbuf
  res <- withBuffer bbuf $ \ptr ->
            IODevice.writeNonBlocking dev (ptr `plusPtr` bufL bbuf) offset bytes
  let bbuf' = bufferAddOffset bytes bbuf
  return (res, bufferAdjustL (bufL bbuf + res) bbuf')

