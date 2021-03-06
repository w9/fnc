module Lib
    ( module Lib
    ) where

import System.Console.ANSI
import System.Environment
import System.Directory hiding (createDirectory, removeDirectory)
import System.Posix.Files
import System.Posix.Directory
import System.FilePath.Posix
import System.Exit
import System.Process
import System.Random
import Data.Bool
import Data.List
import Data.Maybe
import Data.Char
import Data.Monoid
import Control.Applicative
import Control.Monad

isDir :: FilePath -> IO Bool
isDir p = do
  s <- getFileStatus p
  return $ isDirectory s

getOldFns :: FilePath -> IO [String]
getOldFns f = do
  ctns <- listDirectory f

  dirs  <- filterM isDir ctns
  files <- filterM (fmap not . isDir) ctns

  let formattedDirs = map (++ "/") $ sortOn (map toLower) dirs
  let formattedFiles = map (++ "") $ sortOn (map toLower) files

  return $ formattedDirs <> formattedFiles

cmdLine :: IO ()
cmdLine = do
  globalTmpDir <- getTemporaryDirectory
  oldFns <- getOldFns "."
  let tempFileContent = unlines oldFns
  let tempFile = globalTmpDir </> "FNC"
  writeFile tempFile tempFileContent
  mEditor <- lookupEnv "EDITOR"
  editor <- maybe (die "The environment variable $EDITOR is not set.") return mEditor
  exitCode <- rawSystem editor [tempFile]

  case exitCode of
     ExitFailure k -> die $ "The editing was cancelled. Exit code = " ++ show k
     ExitSuccess -> return ()

  fileCtn <- readFile tempFile
  let newFns = lines fileCtn
  let diff = findDiff oldFns newFns

  if length diff == 0 then die "No change was found." else return ()

  putStrLn "The changes are:"
  putStrLn ""
  putStrLn . unlines $ map formatDiff diff
  putStrLn ""
  putStrLn "Would you like to make these changes? (y/n)"

  confirmation <- getLine
  if confirmation == "y"
     then return ()
     else die "No change was made."

  tmpDir <- randomWord randomASCII 12
  createDirectory tmpDir 0o777

  mapM_ (\(a, b) -> rename a (tmpDir </> b)) diff
  mapM_ (\(a, b) -> rename (tmpDir </> b) b) diff

  removeDirectory tmpDir

  putStrLn $ show (length diff) ++ " file(s) or directory(ies) have been renamed."


randomASCII :: IO Char
randomASCII = getStdRandom $ randomR (chr 0,chr 127)

onlyWith :: (Char -> Bool) -> IO Char -> IO Char
onlyWith p gen = gen >>= \c -> if p c then return c else onlyWith p gen

randomWord :: IO Char -> Int -> IO String
randomWord gen len = replicateM len $ onlyWith isAlphaNum gen

  
formatDiff :: (String, String) -> String
formatDiff (a, b) = setSGRCode [SetColor Foreground Vivid Blue] ++ a ++ setSGRCode [Reset]
              ++ " --> "
              ++ setSGRCode [SetColor Foreground Vivid Yellow] ++ b ++ setSGRCode [Reset]


isDifferent :: String -> String -> Maybe (String, String)
isDifferent a b = if a == b then Nothing else Just (a, b)

findDiff :: [String] -> [String] -> [(String, String)]
findDiff as bs = catMaybes $ zipWith isDifferent as bs
