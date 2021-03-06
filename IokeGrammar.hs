{-# Language TemplateHaskell, QuasiQuotes, FlexibleContexts, DeriveDataTypeable #-}

module IokeGrammar
(ioke, Ioke(..), LitS(..), Chunk(..), LitSymb(..)) where
import Data.Data
import Data.Typeable
import qualified Data.Map as Map
import qualified Data.List as List
import Text.Peggy 
import Data.Maybe

data Ioke = Cell String (Maybe ArgList) | Symbol LitSymb | Dict [DictElem] | IList [IListElem] | Comment String | LiteralString LitS | QuotedMessage | QuasiQuotedMessage | UnQuotedMessage | Ret | Fullstop | ISpace Int | BangLine String | MethodComment String | Key String | Brackets Int [Ioke] deriving (Show, Data, Eq, Typeable)

data ArgList = ArgList Int  deriving (Show, Data, Eq, Typeable)

data DictElem = KV String String | Hash String String | DictMessage Message deriving (Show, Data, Eq, Typeable)

data IListElem = IListElem Message deriving (Show, Data, Eq, Typeable)

data Message = Message String [MessageLine] deriving (Show, Data, Eq, Typeable)

data MessageLine = MessageLine [Message] deriving (Show, Data, Eq, Typeable)

data LitS = SquareString [Chunk] | QuotedString [Chunk] deriving (Show, Data, Eq, Typeable)

data LitSymb = BareSymbol String | QuotedSymbol [Chunk] deriving (Show, Data, Eq, Typeable)

data Chunk = Lit String | Escape String | Interpolate MessageLine | RawInsert String deriving (Show, Data, Eq, Typeable)

[peggy|
ioke :: [Ioke]
  = (ret / dot / comment / hashbang / ispace / istring / isymbol / bracketedexpr)*

bracketedexpr :: Ioke
  = '(' ioke ')' { Brackets 0 $1 }

isymbol :: Ioke
  = ':' (baresymbol / symbolstr) { Symbol $1 }

baresymbol :: LitSymb
  = [A-Za-z0-9]+ { BareSymbol $1 }

symbolstr :: LitSymb
  = '\"' (symbolstring / symbolescape)* '\"' { QuotedSymbol $1 } 

symbolstring :: Chunk
  = [^\\"]+ { Lit $1 } --"

symbolescape :: Chunk
  = '\\' [nr"] { Escape ['\\', $1] } --"

istring :: Ioke
  = (squarestring / quotedstring)

squarestring :: Ioke
  = '#[' ( squarelit / squareescape / interpolate )* ']' { LiteralString (SquareString $1) }

quotedstring :: Ioke
  = '\"' ( quotedlit / quotedescape / interpolate )* '\"' { LiteralString (QuotedString $1) }

squarelit :: Chunk
  = [^\\\]]+ { (Lit $1) }

quotedlit :: Chunk
  = [^\\"]+  { (Lit $1) }  --"

squareescape :: Chunk
  = '\\' [nr\]] { (Escape ['\\', $1]) }

quotedescape :: Chunk
  = '\\' [nr"] { (Escape ['\\', $1]) } --"

interpolate :: Chunk
  = '{'  '}' { (Interpolate (MessageLine [])) } -- Nothing here at the moment

ret :: Ioke
  = [\r\n] { Ret }

dot :: Ioke
  = '.'    { Fullstop }

comment :: Ioke
  = (';' [^\n\r]+) { Comment (";" ++ $1) }

hashbang :: Ioke
  = ('#!/' [^\n\r]+) { BangLine ("#!/" ++ $1) }

ispace :: Ioke
  = [ ]+ { ISpace (length $1) }

|]
